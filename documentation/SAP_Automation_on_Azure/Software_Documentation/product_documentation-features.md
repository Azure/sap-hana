# ![SAP Deployment Automation Framework](../assets/images/UnicornSAPBlack64x64.png)**SAP Deployment Automation Framework** #

# Product Documentation - Features <!-- omit in toc -->

<br/>

## Table of Contents <!-- omit in toc -->
<br/>

- [Infrastructure as Code](#infrastructure-as-code)
- [Managed Resources](#managed-resources)
- [Configuration as Code](#configuration-as-code)
- [Orchestration](#orchestration)


<br/><br/><br/><br/>

---
<br/>

<!-- TODO: Refine -->

- Infrastructure as Code
  - Terraform
  - Modular Deployment
  - Custom naming
  - [Key Vault](key_vault.md)
  - HA Ready Infrastructure
  - Custom Images
  - IP Adressing
  - Availability Zones
  - Network Security Groups
  - DHCP
  - DNS



## Infrastructure as Code

| Feature                                  | Status                             |
| ---------------------------------------- | :--------------------------------: |
| Modular Deployment                       | ![lime](../assets/images/4s.png)   |
|   Deployment Infrastructure (Optional)   | ![lime](../assets/images/4s.png)   |
|   Library Infrastructure                 | ![Green](../assets/images/5s.png)  |
|   Workload Infrastructure                | ![green](../assets/images/5s.png)  |
|   SAP Platform Infrastructure            | ![green](../assets/images/5s.png)  |
| Naming Standard, both Default and Custom | ![green](../assets/images/5s.png)  |
| Subscription Deployment, Single          | ![green](../assets/images/5s.png)  |
| Subscription Deployment, Multiple        | ![orange](../assets/images/2s.png) |
| Support for Manual resources             | ![green](../assets/images/5s.png)  |
| Key Vault                                | ![green](../assets/images/5s.png)  |
| Regional Deployments                     | ![green](../assets/images/5s.png)  |
| DB, HANA                                 | ![green](../assets/images/5s.png)  |
| DB, Any                                  | ![green](../assets/images/5s.png)  |
| VM by SKU                                | ![green](../assets/images/5s.png)  |
| DBAny                                    | ![green](../assets/images/5s.png)  |
| DBAny                                    | ![green](../assets/images/5s.png)  |
| DBAny                                    | ![green](../assets/images/5s.png)  |
| DBAny                                    | ![green](../assets/images/5s.png)  |
| DBAny                                    | ![green](../assets/images/5s.png)  |
| DBAny                                    | ![green](../assets/images/5s.png)  |
| DBAny                                    | ![green](../assets/images/5s.png)  |
| Disk Encryption Support                  | ![green](../assets/images/5s.png)  |
| Tagging                                  | ![green](../assets/images/5s.png)  |
| Write Acceleration                       | ![green](../assets/images/5s.png)  |
| Accelerated Networking                   | ![green](../assets/images/5s.png)  |
| IP Addressing - Static and DHCP          | ![green](../assets/images/5s.png)  |
| SSH Key Pairs                            | ![green](../assets/images/5s.png)  |


<br/><br/><br/>


## Managed Resources

| Resource                                            | Deployer                           | Library                            | Workload                           | SDU                                |
| --------------------------------------------------- | :--------------------------------: | :--------------------------------: | :--------------------------------: | :--------------------------------: |
| Application Security Group                          | -                                  | -                                  | ![green](../assets/images/5s.png)  |                                    |
| Availability Zone                                   | -                                  | -                                  | ![green](../assets/images/5s.png)  |                                    |
| DNS                                                 | ![green](../assets/images/5s.png)  | -                                  | ![green](../assets/images/5s.png)  |                                    |
| VPN Gateway                                         | ![red](../assets/images/1s.png)    | -                                  | ![green](../assets/images/1s.png)  | -                                  |
| VMware                                              |                                    | -                                  |                                    |                                    |


| Resource                                            | Deployer                           | Library                            | Workload                           | SDU                                |
| --------------------------------------------------- | :--------------------------------: | :--------------------------------: | :--------------------------------: | :--------------------------------: |
| local_file                                          | ![green](../assets/images/5s.png)  | -                                  |-                                   | ![green](../assets/images/5s.png)  |
| null_resource                                       | ![green](../assets/images/5s.png)  | ![green](../assets/images/5s.png)  | ![green](../assets/images/5s.png)  | ![green](../assets/images/5s.png)  |
| random_id                                           | ![green](../assets/images/5s.png)  | ![green](../assets/images/5s.png)  | ![green](../assets/images/5s.png)  | ![green](../assets/images/5s.png)  |
| random_password                                     | ![green](../assets/images/5s.png)  | -                                  | ![green](../assets/images/5s.png)  | ![green](../assets/images/5s.png)  |
| tls_private_key                                     | ![green](../assets/images/5s.png)  | -                                  | ![green](../assets/images/5s.png)  | -                                  |
| availability_set                                    | -                                  | -                                  | -                                  | ![green](../assets/images/5s.png)  |
| key_vault                                           | ![green](../assets/images/5s.png)  | ![green](../assets/images/5s.png)  | ![green](../assets/images/5s.png)  | ![green](../assets/images/5s.png)  |
| key_vault_access_policy                             | ![green](../assets/images/5s.png)  | ![green](../assets/images/5s.png)  | -                                  | ![green](../assets/images/5s.png)  |
| key_vault_secret                                    | ![green](../assets/images/5s.png)  | -                                  | ![green](../assets/images/5s.png)  | ![green](../assets/images/5s.png)  |
| lb                                                  | -                                  | -                                  | -                                  | ![green](../assets/images/5s.png)  |
| lb_backend_address_pool                             | -                                  | -                                  | -                                  | ![green](../assets/images/5s.png)  |
| lb_probe                                            | -                                  | -                                  | -                                  | ![green](../assets/images/5s.png)  |
| lb_rule                                             | -                                  | -                                  | -                                  | ![green](../assets/images/5s.png)  |
| linux_virtual_machine                               | ![green](../assets/images/5s.png)  | -                                  | ![green](../assets/images/5s.png)  | ![green](../assets/images/5s.png)  |
| managed_disk                                        | -                                  | -                                  | -                                  | ![green](../assets/images/5s.png)  |
| network_interface                                   | ![green](../assets/images/5s.png)  | -                                  | ![green](../assets/images/5s.png)  | ![green](../assets/images/5s.png)  |
| network_interface_backend_address_pool_association  | -                                  | -                                  | -                                  | ![green](../assets/images/5s.png)  |
| network_interface_security_group_association        | -                                  | -                                  | ![green](../assets/images/5s.png)  | -                                  |
| network_security_group                              | ![green](../assets/images/5s.png)  | -                                  | ![green](../assets/images/5s.png)  | ![green](../assets/images/5s.png)  |
| network_security_rule                               | ![green](../assets/images/5s.png)  | -                                  | -                                  | ![green](../assets/images/5s.png)  |
| proximity_placement_group                           | -                                  | -                                  | -                                  | ![green](../assets/images/5s.png)  |
| public_ip                                           | ![green](../assets/images/5s.png)  | -                                  | -                                  | -                                  |
| resource_group                                      | ![green](../assets/images/5s.png)  | ![green](../assets/images/5s.png)  | ![green](../assets/images/5s.png)  | ![green](../assets/images/5s.png)  |
| role_assignment                                     | ![green](../assets/images/5s.png)  | ![green](../assets/images/5s.png)  | -                                  | -                                  |
| storage_account                                     | ![green](../assets/images/5s.png)  | ![green](../assets/images/5s.png)  | ![green](../assets/images/5s.png)  | -                                  |
| storage_container                                   | -                                  | ![green](../assets/images/5s.png)  | -                                  | -                                  |
| storage_share                                       | -                                  | ![green](../assets/images/5s.png)  | -                                  | -                                  |
| subnet                                              | ![green](../assets/images/5s.png)  | -                                  | ![green](../assets/images/5s.png)  | ![green](../assets/images/5s.png)  |
| subnet_network_security_group_association           | ![green](../assets/images/5s.png)  | -                                  | -                                  | ![green](../assets/images/5s.png)  |
| user_assigned_identity                              | ![green](../assets/images/5s.png)  | -                                  | -                                  | -                                  |
| virtual_machine_data_disk_attachment                | -                                  | -                                  | -                                  | ![green](../assets/images/5s.png)  |
| virtual_network                                     | ![green](../assets/images/5s.png)  | -                                  | ![green](../assets/images/5s.png)  | -                                  |
| virtual_network_peering                             | -                                  | -                                  | ![green](../assets/images/5s.png)  | -                                  |
| windows_virtual_machine                             | -                                  | -                                  | -                                  | ![green](../assets/images/5s.png)  |




<br/><br/><br/>


## Configuration as Code

| Feature                                 | Status                             |
| --------------------------------------- | :--------------------------------: |
| OS configuration, Base                  | ![orange](../assets/images/2s.png) |
| OS configuration, Base (CIS Guidelines) | ![orange](../assets/images/2s.png) |
| OS configuration, SAP Specific          | ![orange](../assets/images/2s.png) |
| Pacemaker configuration                 | ![orange](../assets/images/2s.png) |
| DB Install, HANA                        | ![yellow](../assets/images/3s.png) |
| Windows Failover configuration          | ![red](../assets/images/1s.png)    |
| SAP Application Install Framework       | ![orange](../assets/images/2s.png) |
| DB, HANA, HSR Configuration             | ![orange](../assets/images/2s.png) |


<br/><br/><br/>


## Orchestration

| Feature                                 | Status                             |
| --------------------------------------- | :--------------------------------: |
| Azure DevOps                            | ![orange](../assets/images/1s.png) |

