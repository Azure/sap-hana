#################################################################################
#
# Helper file to retrieve the ssh key
#
#################################################################################

kv=$(grep "kv_uri:" sap-parameters.yaml  | cut -d: -f2 | xargs )
ksecret_prefix=$(grep "secret_prefix:" sap-parameters.yaml  | cut -d: -f2 | xargs )

ksecret=$ksecret_prefix-sid-sshkey
rm -f sshkey
az keyvault secret show --vault-name ${kv} --name ${ksecret} | jq -r .value > sshkey
chmod 600 sshkey

sshkeyv=$(az keyvault secret show --vault-name ${kv} --name ${ksecret} | jq -r .value)

export SSHKEYSAP=$sshkeyv
