# ![SAP Deployment Automation Framework](../assets/images/UnicornSAPBlack64x64.png)**SAP Deployment Automation Framework** #

# Using custom disk sizing #

By default the automation will deploy the correct disk configuration for the Hana deployments. For the AnyDB deployments the default disklayout is defined based on the size of the database and for Hana deployments it is typically tied to the VM size. See [product_documentation-sap_deployment_unit.md] (../Software_Documentation/product_documentation-sap_deployment_unit.md) for more info

The disk sizing can be changed by providing a custom json file to the deployment by specifying the following parameter ```db_disk_sizes_filename : "[PATH to json file]"``` in the parameter file.

The structure of the disk layout file is shown below:

```json
{
  "type": {
    "Default": {
      "compute": {
        "vm_size"       : "Standard_D4s_v3",
        "swap_size_gb"  : 2
      },
      "storage": [
        {
          "name"        : "os",
          "count"       : 1,
          "disk_type"   : "Premium_LRS",
          "size_gb"     : 127,
          "caching"     : "ReadWrite"
        },
        {
          "name"        : "[NAME_OF_DISK]",
          "count"       : [NUMBER_OF_DISKS],
          "disk_type"   : "Premium_LRS",
          "size_gb"     : 128,
          "caching"     : "ReadWrite",
          "start_lun"   : 0 
        }

      ]
    }
  }
}
```

The first node with the name "os" is mandatory and it defines the size of the operating disk. The top level value ("Default" in the sample below) is the key that is referred to by the automation. The parameter files need to have a corresponding value in the database section in the parameter file ```"size" : "Default"```

The "name" attribute will be a part of the Azure name of the resource. 
The "start_lun" attribute defines the first LUN lumber for the disks in the node.

It is possible to add multiple nodes in the structure to create additional disks to meet the business requirements. For example the json below consists of 3 data disks (LUNS 0,1,2) and a log disk (LUN 9) using the Ultra SKU and a backup disk (LUN 13) using Standard SSDN.

```json
{
  "type" : {
    "Default": {
      "compute": {
        "vm_size"                 : "Standard_D4s_v3",
        "swap_size_gb"            : 2
      },
      "storage": [
        {
          "name"                  : "os",
          "count"                 : 1,
          "disk_type"             : "Premium_LRS",
          "size_gb"               : 127,
          "caching"               : "ReadWrite"
        },
        {
          "name"                  : "data",
          "count"                 : 3,
          "disk_type"             : "Premium_LRS",
          "size_gb"               : 256,
          "caching"               : "ReadWrite",
          "write_accelerator"     : false,
          "start_lun"             : 0
        },
        {
          "name"                  : "log",
          "count"                 : 1,
          "disk_type"             : "UltraSSD_LRS",
          "size_gb": 512,
          "disk-iops-read-write"  : 2048,
          "disk-mbps-read-write"  : 8,
          "caching"               : "None",
          "write_accelerator"     : false,
          "start_lun"             : 9
        },
        {
          "name"                  : "backup",
          "count"                 : 1,
          "disk_type"             : "Premium_LRS",
          "size_gb"               : 256,
          "caching"               : "ReadWrite",
          "write_accelerator"     : false,
          "start_lun":            : 13
        }

      ]
    }
  }
}
```

# Extending by adding disks #

If there is a need to grow the system by adding additional disks to an already deployed system it can be achieved by adding a new block to the json structure which has the append attribute set to true.

**Note** It is recommended to whenever possible grow the disk sizes instead of adding new disks"


```json
{
  "type" : {
    "Default": {
      "compute": {
        "vm_size"                 : "Standard_D4s_v3",
        "swap_size_gb"            : 2
      },
      "storage": [
        {
          "name"                  : "os",
          "count"                 : 1,
          "disk_type"             : "Premium_LRS",
          "size_gb"               : 127,
          "caching"               : "ReadWrite"
        },
        {
          "name"                  : "data",
          "count"                 : 3,
          "disk_type"             : "Premium_LRS",
          "size_gb"               : 256,
          "caching"               : "ReadWrite",
          "write_accelerator"     : false,
          "start_lun"             : 0
        },
        {
          "name"                  : "log",
          "count"                 : 1,
          "disk_type"             : "UltraSSD_LRS",
          "size_gb": 512,
          "disk-iops-read-write"  : 2048,
          "disk-mbps-read-write"  : 8,
          "caching"               : "None",
          "write_accelerator"     : false,
          "start_lun"             : 9
        },
        {
          "name"                  : "backup",
          "count"                 : 1,
          "disk_type"             : "Premium_LRS",
          "size_gb"               : 256,
          "caching"               : "ReadWrite",
          "write_accelerator"     : false,
          "start_lun":            : 13
        }
        ,
        {
          "name"                  : "data",
          "count"                 : 3,
          "disk_type"             : "Premium_LRS",
          "size_gb"               : 256,
          "caching"               : "ReadWrite",
          "write_accelerator"     : false,
          "append"                : true,
          "start_lun"             : 4
        }

      ]
    }
  }
}
```