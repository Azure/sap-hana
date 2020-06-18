### <img src="../../documentation/assets/UnicornSAPBlack256x256.png" width="64px"> SAP Automation > V1.0.0 > HANA <!-- omit in toc -->
# Running the Ansible Playbook <!-- omit in toc -->

Master Branch's status: [![Build Status](https://dev.azure.com/azuresaphana/Azure-SAP-HANA/_apis/build/status/Azure.sap-hana?branchName=master&api-version=5.1-preview.1)](https://dev.azure.com/azuresaphana/Azure-SAP-HANA/_build/latest?definitionId=6&branchName=master)

<br>

## Table of contents <!-- omit in toc -->
- [Running the Ansible Playbook](#running-the-ansible-playbook)

<br>

## Running the Ansible Playbook

1. If you set `options.ansible_execution` to `true`, then the Ansible deployment will be triggered as part of the Terrafrom deployment. Otherwise:
   - logon to the jumpbox (the logon information is recorded in the ouputs of [Running the Terraform Deployment - Outputs](../terraform/running-terraform-deployment.md#outputs)), which is already prepared with Ansible the enviorment.
   - Start the ansible playbook<sup>[1](#myfootnote1)</sup>:

    ```bash
    ansible-playbook -i hosts.yml ~/sap-hana/deploy/ansible/sap_playbook.yml
    ```

<sup>[1](#myfootnote1): The ansible playbook currently configures the VMs without HANA installation.</sup>
