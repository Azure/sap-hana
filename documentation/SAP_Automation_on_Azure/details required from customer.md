

|** |**Value**|**Details**|
| :- | :- | :- |
|**Environment**|
|Name| |Used for grouping applications (development, qa etc)|
|** |
|**Networking**|
|VNet              |* |If existing provide the ARM ID otherwise the address space|
|Subnet|* |If existing provide the ARM ID otherwise the address space|
|NSG|* |If existing provide the ARM ID |
|**Keyvault**|
|Keyvault|* |If existing provide the ARM ID. |
||| |
|||This is used for storing Service Principal details and credentials|
|**Service Principal**|
|App ID|* |These need to be stored in the key vault using the format |
|||[ENVIRONMENT]-client-id|
|App Secret|* |These need to be stored in the key vault using the format|
|||[ENVIRONMENT]-client-secret|
|Tenant ID|* |These need to be stored in the key vault using the format |
|||[ENVIRONMENT]-tenant-id|
|Subscription ID|* |These need to be stored in the key vault using the format|
|||[ENVIRONMENT]-subscription-id|
|**Azure NetApp Files**|
|name of empty availability set|* |needed for deployment of ANF|
||| |
|name of empty capacity pool|* |needed for deployment of ANF|
||| |

|SAP Information|**Value**|** |
| :- | :- | :- |
|Environment| |Development, QA etc – used to map to the correct|
|SID| | |
|**Database**|
|Type|* |*Hana, DB2, ORACLE, SQLSERVER*|
|VM SKU| | |
|OS| | |
|Image| | |
|Count| | |
|IP Addresses (if static IP)| | |
|Load Balancer IP (if static Ips)| | |
|Disk configuration|
| |Count|Size|Name|
|Data disks| | | |
|Log disks| | | |
|Other disks| | | |
|** |
|**Application**|
|VM SKU| | |
|OS| | |
|Image| | |
|Count| | |
|IP Addresses (if static IP)| | |
|Disk configuration|
|* |Count|Size|Name|
|Data disks| | | |
|Other disks| | | |
|** |
|**Central Services**|
|VM SKU| | |
|OS| | |
|Image (if different from App)| | |
|Count| | |
|IP Addresses (if static IP)| | |
|Load Balancer IPs (if static Ips)| | |
|Disk configuration| | |
| |Count|Size|Caching|
|Data disks| | | |
|Other disks| | | |
|** |
|**Web Dispatchers**|
|VM SKU| | |
|OS| | |
|Image (if different from App)| | |
|Count| | |
|IP Addresses (if static IP)| | |
|Load Balancer IP (if static Ips)| | |
|Disk configuration|
| |Count|Size|Caching|
|Data disks| | | |
|Other disks| | | |
