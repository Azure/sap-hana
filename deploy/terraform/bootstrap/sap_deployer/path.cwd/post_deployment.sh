local_file_dir=$(cd "$(dirname "$BASH_SOURCE")" && pwd)
workspace=$(basename ${local_file_dir})
remote_dir="~/Azure_SAP_Automated_Deployment/WORKSPACES/LOCAL/${workspace}"
ssh_timeout_s=10

temp_file=$(mktemp)
vault_name=PERMWEEUDEP00userA93

ppk_name=PERM-WEEU-DEP00-sshkey
if [ ! -z ${ppk_name} ]
then
  printf "%s\n" "Collecting secrets from KV"
  ppk=$(az keyvault secret show --vault-name ${vault_name} --name ${ppk_name} | jq -r .value)
  echo "${ppk}" > ${temp_file}
fi

printf "%s\n" "Create remote workspace if not exists"

ssh -i ${temp_file}  -o StrictHostKeyChecking=no -o ConnectTimeout=${ssh_timeout_s} azureadm@20.54.198.28 "[ -d ${remote_dir} ] && mkdir -p ${remote_dir}"


printf "%s\n" "Start uploading deployer tfstate"

scp -i ${temp_file} -o StrictHostKeyChecking=no -o ConnectTimeout=${ssh_timeout_s} ${local_file_dir}/terraform.tfstate azureadm@20.54.198.28:${remote_dir}


printf "%s\n" "Start uploading deployer json"

scp -i ${temp_file} -o StrictHostKeyChecking=no -o ConnectTimeout=${ssh_timeout_s} ${local_file_dir}/PERM-WEEU-DEP00-INFRASTRUCTURE.json azureadm@20.54.198.28:${remote_dir}


rm ${temp_file}
