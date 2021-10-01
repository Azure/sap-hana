# This is the SAP library’s storage account for sap binaries
saplib="xxxxxxsaplib###"

# This is the deployer keyvault
kv_name="xxxxxdep00user###"

end=`date -u -d "90 days" '+%Y-%m-%dT%H:%MZ'`

sas=$(az storage account generate-sas --permissions rpl --account-name $saplib --services b --resource-types sco --expiry $end -o tsv)

az keyvault secret set --vault-name $kv_name --name "sapbits-sas-token" --value ?$sas
