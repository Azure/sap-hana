# Automated Deployments of SAP Landscapes in Microsoft Azure

This repository contains a set of highly customizable templates that can be used to automatically deploy complex SAP landscapes in the Azure Cloud.
The templates are 

 ![image](https://raw.githubusercontent.com/Azure/sap-hana/61374fa02c7951ffd8cc949d0af5d2b154ed119d/shine-dashboard.png)

## Table of contents

- [Getting started](#getting-started)
- [Scenarios](#scenarios)
- [Applications](#applications)

## Getting started

In this simple example, we'll deploy a simple single-node HANA instance. (*Note: If you already have access to the required SAP packages via a direct HTTP link, you can skip to step 10.*)
1. Navigate to the [SAP Software Download Center (SWDC)](https://launchpad.support.sap.com/#/softwarecenter).

2. Search for the following packages required for the single-node HANA scenario and download them to your local machine:

| SWDC filename | Package name | OS | Version | Template parameter |
| ------------- | ------------ | -- | ------- | ------------------ |
| SAPCAR_1110-80000935.EXE | SAPCAR | Linux x86_64 | 7.21 | `url_sap_sapcar` |
| IMDB_SERVER100_122_17-10009569.SAR | HANA DB Server | Linux x86_64 | 122.17 (SPS12) for HANA DB 1.00 | `url_sap_hdbserver` |

3. In the Azure Portal, create a **Storage Account** named.

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
    az_region = "westus2"
    az_resource_group = "demo-xs1"
    az_domain_name = "demo-xs1"
    vm_size      = "Standard_E8s_v3"
    sshkey_path_private = "~/.ssh/id_rsa"
    sshkey_path_public = "~/.ssh/id_rsa.pub"
    vm_user = "demo"

    sap_sid = "XS1"
    db_num = "0"
    sap_instancenum = "01"

    url_sap_sapcar = "https://XXX"
    url_sap_hostagent = "https://XXX"
    url_sap_hdbserver   = "https://XXX"
    url_xsa_runtime = "https://XXX"
    url_di_core = "https://XXX"
    url_sapui5 = "https://XXX"
    url_portal_services = "https://XXX"
    url_xs_services = "https://XXX"
    url_shine_xsa = "https://XXX"
    url_cockpit = "https://XXX"

    pw_os_sapadm = "XXX"
    pw_os_sidadm = "XXX"
    pw_db_system = "XXX"
    pwd_db_xsaadmin = "XXX"
    pwd_db_tenant = "XXX"
    pwd_db_shine = "XXX"
    email_shine = "shine@myemailaddress.com"

    useHana2    = true
    install_xsa = true
    install_shine = true
    install_cockpit = true
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
