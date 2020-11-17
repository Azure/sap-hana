#!/bin/bash

# Requires:
# - a stack XML file (*.xml)
# - a stack Excel file (*.xls)
# - a download basket manifest (*.json)
# The script discovers the filenames based on the file extension.
# NOTE: Exactly one of each file is allowed!
#
# Limitations of generated BoM:
# - Hard-coded HANA2 dependency
# - No provision for `version:` in media
# - No provision for `override_target_filename:` in media
#
# Instructions
# - Run this script from the stackfiles folder on your workstation
#   /path/to/generate_fullbom.sh archive_location [product] >path/to/bom.yml
#   where:
#   - `archive_location` is the Azure Storage Account path, e.g. "https://npweeusaplib9545.file.core.windows.net/sapbits/archives"
#     If not supplied or blank, it will default to "https://npweeusaplib9545.file.core.windows.net/sapbits/archives"
#   - `product` is the documented root BoM name, e.g. "SAP_S4HANA_1809_SP4"
#     If not supplied or blank, it will attempt to determine the name from the stack XML file.
#   For example:
#   cd stackfiles
#   /path/to/util/generate_fullbom.sh "" "SAP_S4HANA_1809_S4_v001" >../bom.yml

declare ARCHIVE=${1:-https://npweeusaplib9545.file.core.windows.net/sapbits/archives}
declare PRODUCT=${2}

declare ERR=0

declare -a XML_FILE=($(ls *.xml 2>/dev/null))
if [[ ${#XML_FILE[*]} -ne 1 ]]; then
  echo "Error: Exactly one .xml file is required. I have found ${XML_FILE[*]:-none}"
  ERR=1
fi

declare -a XLS_FILE=($(ls *.xls 2>/dev/null))
if [[ ${#XLS_FILE[*]} -ne 1 ]]; then
  echo "Error: Exactly one .xls file is required. I have found ${XLS_FILE[*]:-none}"
  ERR=1
fi

declare -a JSON_FILE=($(ls *.json 2>/dev/null))
if [[ ${#JSON_FILE[*]} -ne 1 ]]; then
  echo "Error: Exactly one .json file is required. I have found ${JSON_FILE[*]:-none}"
  ERR=1
fi

if [[ ${ERR} -eq 1 ]]; then
  exit 1
fi

awk -v excelfile="${XLS_FILE[0]}" -v downloadmanifestfile="${JSON_FILE[0]}" '
BEGIN {
  sequence["SP_B"] = "AA";  # download_basket
  sequence["CD"] = "BB";    # DVD exports
  sequence["SPAT"] = "CC";  # others
  RScopy = RS;
  RS = "},{";

  count = 0;
  while ( getline < downloadmanifestfile ) {
    if ( match($0, /USERID|USERNAME1|USERNAME2|OBJCNT/ ) == 0) {
      id = gensub(/^.*"Value":"/, "", "1");  #"
      id = gensub(/^(.*)\|(.+)\|.+\|(.+)\|.+\|.+\|.+$/, "\\1,\\2,\\3", "1", id);
      split(id, result, ",");
      if ( sequence[result[2]] != "" ) {
        seq = sequence[result[2]];
      } else {
        seq = ("ZZ" result[2]);  # Unknown flag
      }
      references[result[3]] = sprintf("%-6s,%s", seq, result[1]);
    }
  }
  close(downloadmanifestfile);
  RS = RScopy;
}

END {
  RS = "</Row>";
  count = 0;
  while ( getline line < excelfile ) {
    if ( match(line, /ss:StyleID=.s20./) != 0 ) {
      count++;
      # <Data ss:Type="String">K-80401INISPSCA.SAR</Data> ... <Data ss:Type="String">IS-PS-CA 804: SP 0001</Data>
      id = gensub(/.*<Data ss:Type=.String.>([^<]+).*<Data ss:Type=.String.>([^<;]+).*"Number">([^<]+).*$/, "\\1,\\2,\\3", "1", line);
      split(id, basketresults, ",");
      sub(/ +$/, "", basketresults[2]);  # trim line end
      filename = basketresults[1];
      component = basketresults[2];
      componentref = basketresults[3];

      if ( references[componentref] != "" ) {
        split(references[componentref], referenceresults, ",");
      } else {
        split(references[filename], referenceresults, ",");
      }

      seq = referenceresults[1];
      sapurl = referenceresults[2];

      if ( sapurl == "" ) seq = "CC";
      if ( component == "File on DVD" ) seq = "BB";
      printf("%-6s%04d,%s,%s,%s\n", seq, count, sapurl, filename, component) | "sort >tempworkfile";
    }
  }
  close (excelfile);
  RS = RScopy;
}
' /dev/null

sed -e 's@\(</[^>][^>]*>\)@\1\n@g' ${XML_FILE[0]} | \
awk -v "archive=${ARCHIVE}" -v "product=${PRODUCT}" '
BEGIN {
  phase = "";
  FS = ",";
}

/<\/constraints>/ {
  systemname = gensub(/^.*<constraint name="ppms-main-app-id"[^>]*description="([^"]+).*$/, "\\1", "1", $0);
  systemname = gensub(/\//, "", "1", systemname);
  systemname = gensub(/[^A-Za-z0-9]+/, "_", "g", systemname);
  if (product == "") product = systemname;
  targetname = gensub(/^.*<constraint name="ppms-nw-id"[^>]*description="([^"]+).*$/, "\\1", "1", $0);
}

END {

  printf("---\n\nname: \"%s\"\ntarget: \"%s\"\nversion: \"001\"\n\ndefaults:\n", product, targetname);
  printf("  archive_location: \"%s/\"\n  target_location: \"/usr/sap/install/downloads/\"\n\n", archive);
  printf("materials:\n  dependencies:\n    - name: \"HANA2\"\n      version: \"003\"\n\n  media:\n");

  while ( getline < "tempworkfile" ) {
    seq = $1;
    sapurl = $2;
    filename = $3;
    component = $4;
    if ( component == "File on DVD" ) component = (component " - " $3)

    dir = "/usr/sap/install/downloads";
    current = substr(seq,1,2);
    if (current != phase ) {
      phase = current;
      if ( phase == "AA" ) {
        printf("\n    # kernel components\n");
        overridedir = "/usr/sap/install/download_basket";
      } else if ( phase == "BB" ) {
        printf("\n    # db export components\n");
        overridedir = "/usr/sap/install/cd_exports";
      } else {
        printf("\n    # other components\n");
        overridedir = "";
      }
    }

    printf("\n    - name: \"%s\"\n", component);
    printf("      archive: \"%s\"\n", filename);
    if ( overridedir != "") printf("      override_target_location: \"%s\"\n", overridedir);
    if (match(filename, /SAPCAR_.*\.EXE/ ) != 0) printf("      override_target_filename: \"SAPCAR.EXE\"\n");
    if ( sapurl != "" ) printf("      sapurl: \"https://softwaredownloads.sap.com/file/%s\"\n", sapurl);
  }

  printf("\n  templates:\n\n    - name: \"%s ini file\"\n      file: \"%s.inifile.params\"\n", product, product);
}
'
