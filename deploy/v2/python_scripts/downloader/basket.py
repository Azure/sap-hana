#!/usr/bin/env python3
# 
#       SapMonitor payload deployed on collector VM
#
#       License:        GNU General Public License (GPL)
#       (c) 2019        Microsoft Corp.
#

import argparse
import context
import re

from helper import *
from SAP_DLM import *
from SAP_Scenarios import *
from SAP_SMP import *

parser = argparse.ArgumentParser(description="Downloader")
parser.add_argument("--config", required=True, type=str, help="The configuration file")
parser.add_argument("--basket", required=False, type=bool, default=False, help="To include item in the basket, default False")
parser.add_argument("--dryrun", required=False, type=bool, default=False, help="Dryrun set to True will not actually download the bits")

args = parser.parse_args()

Config.load(args.config)

include_basket        = args.basket
context.skip_download = args.dryrun

# define shortcuts to the configuration files
app = Config.app_scenario
db  = Config.db_scenario
rti = Config.rti_scenario

DLM.init()
basket = DownloadBasket()

if include_basket:
    DLM.refresh_basket(basket)
    assert(len(basket.items) > 0), \
        "Download basket is empty."
    basket.filter_latest()

SMP.init()
# iterate through all packages
packages = []
if app:
    packages += app.packages
if db:
    packages += db.packages
if rti:
    packages += rti.packages  
for p in packages:
    # Evaluate global condition to decide what software to download
    skip = False
    for c in p.condition:
        if not eval(c):
            skip = True
            break

    if skip:
        continue
    print("Retrieving package %s..." % p.name)

    # iterate through all OS available for package
    for o in p.os_avail:
        relevant_os = eval(p.os_var)
        if type(relevant_os) is str:
            relevant_os = [relevant_os]

        if o not in relevant_os:
            continue
        results = SMP.retrieve(p.retr_params, o)
        cnt     = 0
        while cnt < len(results):
            r = results[cnt]
            assert("Description" in r and "Infotype" in r and "Fastkey" in r and "Filesize" in r and "ReleaseDate" in r), \
                "Result does not have all required keys (%s)" % (str(r))

            r["Filesize"]   = int(r["Filesize"])
            r["ReleaseDate"]  = int(re.search("(\d+)", r["ReleaseDate"]).group(1)) if re.search("(\d+)", r["ReleaseDate"]) else 0

            # Filter out packages that don't match  
            filtered_out = False
            for f in p.filter:
                if not eval(f):
                    results.pop(cnt)
                    filtered_out = True
                    break
            if not filtered_out:
                cnt += 1

        if p.selector: result = results[eval(p.selector)]
        print("%s\n" % (result))
        basket.add_item(DownloadItem(
            id         = result["Fastkey"],
            desc       = result["Description"],
            size       = result["Filesize"],
            time       = basket.latest,
            target_dir = p.target_dir,
        ))

if len(basket.items) > 0:
    basket.filter_latest()
    basket.download_all()
