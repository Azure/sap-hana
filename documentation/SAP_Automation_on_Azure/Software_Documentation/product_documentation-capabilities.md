# ![SAP Deployment Automation Framework](../assets/images/UnicornSAPBlack64x64.png)**SAP Deployment Automation Framework** #

## Supported platforms ##

The SAP Deployment automation supports deployment on both Linux and Windows

## Supported topologies ##

The default deployment model using the SAP Deployment Automation is the distributed model with a database tier and an application tier. The application tier can be further split into three tiers: the application servers, the central services servers and the web dispatchers.

The automation can also be deployed to a standalone server by specifying an configuration without an application tier.

## Supported capabilities ##

The SAP Deployment Automation Framework supportability matrix

Feature                                      | Supported    |  Notes |
| :------------------------------------------|  :---------- |  :----------
| Accelerated Networking                     | Y            | Accelerated Networking is enabled on VMs
| Application Security Groups                | N            | In roadmap
| Anchor VM                                  | Y            | A Virtual Machine which is uses to anchor the proximity placement group in the Availability Zone
| Authentication                             | Y            | The authentication supports both ssh based authentication as well as username/password based authentication
| Availability Zones                         | Y            | The automation can deploy Virtual machines zonal or across Availability Zones
| Azure Files for NFS                        | N            | In roadmap
| Azure Firewall                             | Y            | The automation can deploy an Azure Firewall in the deployer network
| Azure Load Balancer                        | Y            | The automation uses Standard Azure Load Balancers
| Azure NetApp Files                         | N            | In roadmap
| Boot diagnistics Storage Account           | Y            | The boot diagnostics storage account is shared across all systems in a Workload Zone
| Azure Key Vaults                           | Y            | New Azure Keyvaults or existing
| Customer images                            | Y            | The custom images need to be replicated to the region
| Customer managed disk encryption keys      | Y            | The keys need to be pre-created and stored in an Azure Keyvault
| Deployment environment                     | Y            | A Virtual machine in a network peered to the SAP network(s)
| Disk sizing                                | Y            | Default disk sizing specified, can be configured
| IP Addressing                              | Y            | Both customer specified IP addresses and Azure provided
| Naming convention                          | Y            | Default naming convention, can be customized
| Network Security Groups                    | Y            | New Network Security Groups or existing
| Proximity Placement Groups                 | Y            | New Proximity Placement groups or existing
| Resource Group                             | Y            | New Resource Group or existing
| Subnets                                    | Y            | New subnets or existing
| SAP Monitoring                             | N            | In roadmap
| Storage for SAP Installation Media         | Y            | New storage account or existing
| Storage for Terraform state                | Y            | New storage account or existing
| Virtual Machine SKU                        | Y            | All Virtual Machine SKUs are configurable
| Virtual Networks                           | Y            | New Virtual Network or existing
| Witness Storage Account                    | Y            | The Witness storage account is shared across all systems in a Workload Zone. Used for Windows High Availability Scenarios
