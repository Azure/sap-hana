### <img src="../documentation/assets/UnicornSAPBlack256x256.png" width="64px"> SAP Automation <!-- omit in toc -->
# Bootstrapping the Deployment Platform <!-- omit in toc -->

Master Branch's status: [![Build Status](https://dev.azure.com/azuresaphana/Azure-SAP-HANA/_apis/build/status/Azure.sap-hana?branchName=master&api-version=5.1-preview.1)](https://dev.azure.com/azuresaphana/Azure-SAP-HANA/_build/latest?definitionId=6&branchName=master)

<br/>

## Table of contents <!-- omit in toc -->
- [Overview](#overview)
    - [Deployment Environment Arch](#deployment-environment-arch)
  - [Prerequisites](#prerequisites)
    - [Credentials](#credentials)
      - [RBAC](#rbac)
      - [SPN](#spn)
- [Bootstrapping](#bootstrapping)
  - [Option 1 - Cloud Shell](#option-1---cloud-shell)
  - [Option 2 - Local Machine](#option-2---local-machine)
- [Migrate to Deployment Platform](#migrate-to-deployment-platform)
  - [Bootstrap JSON Config](#bootstrap-json-config)

<br/><br/>


# Overview
The initial step to using the SAP Automation tools is to Bootstrap your Deployment Environment. 
Once the Deployment Platform is bootstrapped, all subsequent automation activities will occur from that server.
It functions as the Automation Control Center.

There are more scenarios which we will discuss in[Advanced Scenarios for Deployment Infrastructure](/documentation/advanced-scenarios-for-deployment-infrastructure.md).

The Deployment Platform consists of:

| Resource         | Description                                                                                               |
| ---------------- | --------------------------------------------------------------------------------------------------------- |
| Management VNET  | This is an administrative VNET. <br/> Typically an address space with a /26 CIDR will be sufficient.       |
| Deploy Subnet    | This is a small subnet to provide an isolation for the Deploy Server. <br/> A /28 CIDR will be sufficient. |
| Deploy NSG       | Network Security Group assigned to the Deploy Subnet.                                                     |
| Deploy VM        | Deploy Server.                                                                                            |
| Deploy OS Disk   | OS Disk.                                                                                                  |
| Deploy Data Disk | Data Disk.                                                                                                |
| Deploy NIC       | Network Interface.                                                                                        |
| Deploy PIP       | Provides external access to the Deployment Server.                                                        |
| Storage Account  | Storage Account for Boot Diagnostics for the Deployment Environment VNET.                                 |
| SAP VNET         | This the VNET to which the SAP Infrastructure will be deployed. <br/> This is a larger address space. Default operations function with a /16 CIDR. Smaller address spaces require more administration overhead. |

<br/><br/>

### Deployment Environment Arch
<img src="../documentation/assets/deploymentEnvironmentArch.png" width="800px">

<br/><br/>

## Prerequisites
- For bootstrapping we can use User level access that meets a minimum security role: [RBAC](#rbac).
- For consistant execution from the Deploy Server, that will be created, an [SPN](#spn) will be desired.

<br/><br/>

### Credentials
The user credentials that allow access to the Azure Portal will work for the Bootstrapping, provided they are assigned the correct RBAC.

For opperation of the Deploy Server after Bootstrapping, a SPN will be required.

<br/>

#### RBAC
1) Contributor
2)  Need to be more specific here *TODO*

<br/>

#### SPN
1) Create SPN
2) Details Portal *TODO*
3) Details CLI *TODO*

<br/><br/>

# Bootstrapping

## Option 1 - Cloud Shell

1) In the Azure Portal, start the Cloud Shell
2) Ensure that the correct subscription is set as Default.
    ```
    az account list
    az account set --subscription XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX or "Name"
    ```

3) Create a Bootstrap Directory and descend into it.<br/>
    ```
    mkdir bootstrap
    cd $_
    ```

4) Clone the sap-hana Repository.<br/>
    ```
    git clone https://github.com/Azure/sap-hana.git
    ````

5) Generate or provide the SSH key pair.
    ```
    ssh-keygen -q -t rsa -C "Deploy Platform" -f sshkey
    <enter>
    <enter>
    ```

6) [**Create bootstrap.json**](#bootstrap-json-config)

7) Initialize Terraform Bootstrap Deployment.
    ```
    terraform init --upgrade=true sap-hana/deploy/terraform/
    ```

8) Preview the Bootstrap Deployment.
    ```
    terraform plan --var-file=bootstrap.json sap-hana/deploy/terraform/
    ```

9) Execute the Bootstrap Deployment.
    ```
    terraform apply --auto-approve --var-file=bootstrap.json sap-hana/deploy/terraform/
    ```

10) [**Migrate to Deployment Platform**](#migrate-to-deployment-platform)

<br/><br/><br/>

## Option 2 - Local Machine

1) Create a Bootstrap Directory and descend into it.<br/>
    ```
    mkdir bootstrap
    cd $_
    ```

2) Download the Terraform software from https://www.terraform.io/downloads.html

3) Unzip Terraform

4) Clone the sap-hana Repository.<br/>
    ```
    git clone https://github.com/Azure/sap-hana.git
    ````

5) Generate or provide the SSH key pair.
    ```
    ssh-keygen -q -t rsa -C "Deploy Platform" -f sshkey
    <enter>
    <enter>
    ```

6) Set the enviorment with the required SPN credentials.
    ```
    export ARM_SUBSCRIPTION_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
    export ARM_CLIENT_SECRET=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    export ARM_TENANT_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
    export ARM_CLIENT_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
    ```

7) [**Create bootstrap.json**](#bootstrap-json-config)

8) Initialize Terraform Bootstrap Deployment.
    ```
    terraform init --upgrade=true sap-hana/deploy/terraform/
    ```

9) Preview the Bootstrap Deployment.
    ```
    terraform plan --var-file=bootstrap.json sap-hana/deploy/terraform/
    ```

10) Execute the Bootstrap Deployment.
    ```
    terraform apply --auto-approve --var-file=bootstrap.json sap-hana/deploy/terraform/
    ```

11) [**Migrate to Deployment Platform**](#migrate-to-deployment-platform)

<br/><br/><br/>

# Migrate to Deployment Platform

1) Logon to Deploy Server

2) Install unzip package.
    ```
    sudo apt install unzip
    ```

3) Set Environment with the SPN credentials.
    ```
    cat <<EOF >> ~/.profile
    export ARM_SUBSCRIPTION_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
    export ARM_CLIENT_SECRET=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
    export ARM_TENANT_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
    export ARM_CLIENT_ID=XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
    export ANSIBLE_HOST_KEY_CHECKING=False
    EOF
    ```

4) Install Terraform Software.
    ```
    mkdir bin; cd $_
    wget https://releases.hashicorp.com/terraform/0.12.29/terraform_0.12.29_linux_amd64.zip
    unzip terraform_0.12.29_linux_amd64.zip
    ```

5) Create a Bootstrap Workspace and descend into it.<br/>
    The *\<NAME\>* used in the path should be the same as the name used for the Resource Group name in the JSON, or created by the defualt naming standard if omitted.
    ```
    mkdir -p WORKSPACES/LOCAL/DEPLOY/<NAME>
    cd $_
    ```

6) Copy the following files from the Bootstrap directory to the newly created Bootstrap Workspace Directory.
    - bootstrap.json
    - *.tfstate
    - sshkey*

7) Initialize Terraform Bootstrap Deployment.
    ```
    terraform init --upgrade=true ../../../../sap-hana/deploy/terraform/
    ```

8) Preview the Bootstrap Deployment.
    ```
    terraform plan --var-file=bootstrap.json ../../../../sap-hana/deploy/terraform/
    ```

9) Execute the Bootstrap Deployment.
    ```
    terraform apply --auto-approve --var-file=bootstrap.json ../../../../sap-hana/deploy/terraform/
    ```


<br/><br/><br/>

---


## Bootstrap JSON Config
```
cat <<EOF > bootstrap.json
{
  "infrastructure": {
    "region"                    : "southcentralus",
    "resource_group": {
      "is_existing"             : "false",
      "name"                    : "SAMPLE-SCUS-DEMO-Deploy_Platform"
    },
    "ppg": {
      "is_existing"             : "false",
      "name"                    : "test-ppg"
    },
    "vnets": {
      "management": {
        "is_existing"           : "false",
        "name"                  : "vnet-mgmt",
        "address_space"         : "10.0.0.0/26",
        "subnet_mgmt": {
          "is_existing"         : "false",
          "name"                : "deployment_platform-subnet",
          "prefix"              : "10.0.0.16/28",
          "nsg": {
            "is_existing"       : "false",
            "name"              : "deployment_platform-nsg",
            "allowed_ips": [
                                  "0.0.0.0/0"
            ]
          }
        }
      },
      "sap": {
        "is_existing"           : "false",
        "name"                  : "vnet-sap",
        "address_space"         : "10.1.0.0/16"
      }
    }
  },
  "jumpboxes": {
    "windows": [],
    "linux": [
      {
        "name"                  : "rti",
        "destroy_after_deploy"  : "true",
        "size"                  : "Standard_D2s_v3",
        "disk_type"             : "StandardSSD_LRS",
        "os": {
          "publisher"           : "Canonical",
          "offer"               : "UbuntuServer",
          "sku"                 : "18.04-LTS"
        },
        "authentication": {
          "type"                : "key",
          "username"            : "azureadm"
        },
        "components": [
                                 "ansible"
        ]
      }
    ]
  },
  "software": {
    "storage_account_sapbits": {
      "is_existing"             : false,
      "account_tier"            : "Premium",
      "account_replication_type": "LRS",
      "account_kind"            : "FileStorage",
      "file_share_name"         : "bits"
    },
    "downloader": {}
  },
  "sshkey": {
    "path_to_public_key"        : "sshkey.pub",
    "path_to_private_key"       : "sshkey"
  },
  "options": {
    "enable_secure_transfer"    : true,
    "enable_prometheus"         : true
  }
}
EOF
```

