# Automated Deployments of SAP Landscapes in Microsoft Azure

This repository contains a set of highly customizable templates that can be used to automatically deploy complex SAP landscapes in the Azure Cloud.
The templates are 

 ![image](https://raw.githubusercontent.com/Azure/sap-hana/7494c4d66cd8aa222e453326261d50bd72e25a8d/template-hapair.png)
 ![image](https://raw.githubusercontent.com/Azure/sap-hana/61374fa02c7951ffd8cc949d0af5d2b154ed119d/shine-dashboard.png)

## Table of contents

- [Getting started](#getting-started)
- [Scenarios](#scenarios)
- [Applications](#applications)

## Getting started

In this simple example, we'll deploy a simple single-node HANA instance. *(**Note:** If you already have access to the required SAP packages via a direct HTTP link, you can skip to step 10.)*

1. Navigate to the [SAP Software Download Center (SWDC)](https://launchpad.support.sap.com/#/softwarecenter).

2. Search for the following packages required for the single-node HANA scenario and download them to your local machine:

| SWDC filename | Package name | OS | Version | Template parameter |
| ------------- | ------------ | -- | ------- | ------------------ |
| SAPCAR_1110-80000935.EXE | SAPCAR | Linux x86_64 | 7.21 | `url_sap_sapcar` |
| IMDB_SERVER100_122_17-10009569.SAR | HANA DB Server | Linux x86_64 | 122.17 (SPS12) for HANA DB 1.00 | `url_sap_hdbserver` |

3. In the Azure Portal, create a **Storage Account** named. *(**Note:** Please make sure to choose a region close to you to improve transfer speed; the SAP bits are quite large.)*

4. In the storage account you just created, create a new **Blob Storage**.

5. In the new Blob Storage that you just created, create a new **Container** and name it `sapbits`.

6. Upload each of the SAP packages you downloaded in step 2 and take note of the download URL.

7. From your Azure Portal, open your Cloud Shell (`>_` button in top bar).

8. Clone this repository:

    ```sh
    git clone https://github.com/Azure/sap-hana.git
    ```

9. Change into the directory for the HANA single-node scenario:

    ```sh
    cd sap-hana/deploy/vm/modules/single_node_hana/
    ```

10. Use a text editor to create a Terraform variables file `terraform.tfvars`, adapting the download URLs accordingly:

    ```python
    # Azure region to deploy resource in; please choose the same region as your storage from step 3 (example: "westus2")
    az_region = "westus2"

    # Name of resource group to deploy (example: "demo1")
    az_resource_group = "demo1"

    # Unique domain name for easy VM access (example: "hana-on-azure1")
    az_domain_name = "hana-on-azure1"

    # Size of the VM to be deployed (example: "Standard_E8s_v3")
    # For HANA platform edition, a minimum of 32 GB of RAM is recommended
    vm_size = "Standard_E8s_v3"

    # Path to the public SSH key to be used for authentication (e.g. "~/.ssh/id_rsa.pub")
    sshkey_path_public = "~/.ssh/id_rsa.pub"

    # Path to the corresponding private SSH key (e.g. "~/.ssh/id_rsa")
    sshkey_path_private = "~/.ssh/id_rsa"

    # OS user with sudo privileges to be deployed on VM (e.g. "demo")
    vm_user = "demo"

    # SAP system ID (SID) to be used for HANA installation (example: "HN1")
    sap_sid = "HN1"

    # SAP instance number to be used for HANA installation (example: "01")
    sap_instancenum = "01"

    # URL to download SAPCAR binary from (see step 6)
    url_sap_sapcar = "https://XXX"

    # URL to download HANA DB server package from (see step 6)
    url_sap_hdbserver = "https://XXX"

    # Password for the OS sapadm user
    pw_os_sapadm = "XXX"

    # Password for the OS <sid>adm user
    pw_os_sidadm = "XXX"

    # Password for the DB SYSTEM user
    # (In MDC installations, this will be for SYSTEMDB tenant only)
    pw_db_system = "XXX"

    # Password for the DB XSA_ADMIN user
    pwd_db_xsaadmin = "XXX"

    # Password for the DB SYSTEM user for the tenant DB (MDC installations only)
    pwd_db_tenant = "XXX"

    # Password for the DB SHINE_USER user (SHINE demo content only)
    pwd_db_shine = "XXX"

    # e-mail address used for the DB SHINE_USER user (SHINE demo content only)
    email_shine = "shine@myemailaddress.com"

    # Set this flag to true when installing HANA 2.0 (or false for HANA 1.0)
    useHana2 = false

    # Set this flag to true when installing the XSA application server
    install_xsa = false

    # Set this flag to true when installing SHINE demo content (requires XSA)
    install_shine = false

    # Set this flag to true when installing Cockpit (requires XSA)
    install_cockpit = false
    ```

11. Log into your Azure subscription:

    ```sh
    az login
    ```

12. Trigger the deployment:
    ```sh
    terraform apply
    ```

13. When prompted if you want to deploy the resources, answer `yes`. The deployment will start and take approx. 30 minutes (actual times may vary depending on region and other parameters).

14. Once the deployment has finished, take note of the last three lines on your console; they should look like this:

    ```sh
    Apply complete! Resources: 19 added, 0 changed, 0 destroyed.
    Outputs:
    ip = Connect using tniek@xs1-db0-tniek-xs1.westus2.cloudapp.azure.com
    ```

15. Connect to your newly deployed HANA instance via SSH:

16. Switch to the <sid>adm user:

    ```sh
    sudo su -
    su - xs1adm
    ```

17. Run `hdbsql` to execute a simple query:

    ```sh
    hdbsql -i 01 -u SYSTEM -p Initial1 "SELECT CURRENT_TIME FROM DUMMY"
    ```

You should see the current system time displayed on the screen.

## Scenarios

#### HANA single-node instance
- single-node HANA instance

#### HANA high-availability pair
- single-node HANA instance, two-tier [HSR](# "HANA System Replication") (primary/secondary)
- Pacemaker high-availability cluster, fully configured with [SBD](# "STONITH by device") and SAP/Azure resource agents

## Applications

#### XSA
- [SAP HANA Cockpit](https://help.sap.com/viewer/6b94445c94ae495c83a19646e7c3fd56/2.0.03/en-US/da25cad976064dc0a24a1b0ee9b62525.html)
- [SHINE Demo Model](https://blogs.saphana.com/2014/03/10/shine-sap-hana-interactive-education/)
