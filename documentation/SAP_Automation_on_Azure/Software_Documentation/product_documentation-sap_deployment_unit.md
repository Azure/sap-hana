# ![SAP Deployment Automation Framework](../assets/images/UnicornSAPBlack64x64.png)**SAP Deployment Automation Framework** #

## The SAP System Deployment ##

The SAP System deployment will deploy the Virtual Machines and the supporting artifacts needed for the SAP Application.

The SAP System deploys the:

1. Application tier
2. The Central Services tier
3. Web dispatcher tie
4. The database tier (HANA or AnyDB)

### Application tier ###

The application tier consist of the Virtual machines and their disks.

#### Application tier sizing ####

The default application deployment deploys a customer defined number of Virtual machines of size Standard_D4s_v3 with an 30 GB operating system disk and a 512 GB data disk.

The count of application servers is defined in the application block using the ```"application_server_count": 3``` in the parameter file.

The application tier sizing can be changed by providing a custom json file to the deployment by specifying the following parameter ```app_disk_sizes_filename : "[PATH to json file]"``` in the parameter file.

An example of the format of the json file is provided below:

```json
{
  "app": {
    "Default": {
      "compute": {
        "vm_size": "Standard_D4s_v3",
        "accelerated_networking": false
      },
      "storage": [
        {
          "count": 1,
          "name": "os",
          "disk_type": "Premium_LRS",
          "size_gb": 30,
          "caching": "ReadWrite",
          "write_accelerator": false
        },
        {
          "count": 1,
          "name": "data",
          "disk_type": "Premium_LRS",
          "size_gb": 512,
          "caching": "None",
          "write_accelerator": false
        }
      ]
    }
  },
```

### Central Services tier ###

The Central Services deployment deploys a customer defined number of Virtual machines of size Standard_D4s_v3 with an 30 GB operating system disk and a 512 GB data disk. The deployment also deploys an Azure Standard Load Balancer.

The count of  servers is defined in the application block using the ```"scs_server_count": 2``` in the parameter file.

The SCS tier sizing can be changed by providing a custom json file to the deployment by specifying the following parameter ```app_disk_sizes_filename : "[PATH to json file]"``` in the parameter file.

An example of the format of the json file is provided below:

```json
{
  "scs": {
    "Default": {
      "compute": {
        "vm_size": "Standard_D4s_v3",
        "accelerated_networking": false
      },
      "storage": [
        {
          "count": 1,
          "name": "os",
          "disk_type": "Premium_LRS",
          "size_gb": 30,
          "caching": "ReadWrite",
          "write_accelerator": false
        },
        {
          "count": 1,
          "name": "data",
          "disk_type": "Premium_LRS",
          "size_gb": 512,
          "caching": "None",
          "write_accelerator": false
        }
      ]
    }
  },
```

### Web Dispatcher tier ###

The Central Services deployment deploys a customer defined number of Virtual machines of size Standard_D4s_v3 with an 30 GB operating system disk and a 512 GB data disk. The deployment will also deploy a Azure Standard Load Balancer.

The count of servers is defined in the application block using the ```"web_server_count": 2``` in the parameter file.

The web dispatcher tier sizing can be changed by providing a custom json file to the deployment by specifying the following parameter ```app_disk_sizes_filename : "[PATH to json file]"``` in the parameter file.

An example of the format of the json file is provided below:

```json
{
  "web": {
    "Default": {
      "compute": {
        "vm_size": "Standard_D4s_v3",
        "accelerated_networking": false
      },
      "storage": [
        {
          "count": 1,
          "name": "os",
          "disk_type": "Premium_LRS",
          "size_gb": 30,
          "caching": "ReadWrite",
          "write_accelerator": false
        },
        {
          "count": 1,
          "name": "data",
          "disk_type": "Premium_LRS",
          "size_gb": 512,
          "caching": "None",
          "write_accelerator": false
        }
      ]
    }
  },
```

### Database tier ###

The database tier deployment deploys the Virtual machines and their disks. It also deploys an Standard Azure Load Balancer.

The size of the database virtual machines is controlled with the ```"size" : "[SIZE]"``` parameter in the databases section.
The size parameter mapps to the following disk configuration.

### Hana DB sizing ###

| Size      | VM SKU              | OS disk       | Data disks       | Log disks        | Hana shared    | User SAP   | Backup          |
|-----------|---------------------|---------------|------------------|------------------|----------------|------------|-----------------|
| Default   | Standard_D8s_v3     | E6 (64 GB)    | P20 (512 GB)     | P20 (512 GB)     | E20 (512 GB)   | E6 (64 GB) | E20 (512 GB)    |  
| S         | Standard_M32ls      | E6 (64 GB)    | 3 P20 (512 GB)   | 2 P20 (512 GB)   | E20 (512 GB)   | E6 (64 GB) | E20 (512 GB)    |  
| M         | Standard_M64ls      | E6 (64 GB)    | 3 P20 (512 GB)   | 2 P20 (512 GB)   | E20 (512 GB)   | E6 (64 GB) | E20 (512 GB)    |  
| L         | Standard_M64s       | E6 (64 GB)    | 4 P20 (1024 GB)  | 2 P30 (1024 GB)  | E30 (1024 GB)  | E6 (64 GB) | 2 E30 (1024 GB) |  
| XL        | Standard_M64s       | E10 (128 GB)  | 4 P20 (1024 GB)  | 2 P30 (1024 GB)  | E30 (1024 GB)  | E6 (64 GB) | 2 E30 (1024 GB) |
| XXL       | Standard_M128ms     | E10 (128 GB)  | 5 P20 (1024 GB)  | 2 P30 (1024 GB)  | E30 (1024 GB)  | E6 (64 GB) | 4 E30 (1024 GB) |
| M32ts     | Standard_M32ts      | P6 (64 GB)    | 4 P6 (64 GB)     | 3 P10 (128 GB)   | P20 (512 GB)   | P6 (64 GB) | P20 (512 GB)    |
| M32ls     | Standard_M32ls      | P6 (64 GB)    | 4 P6 (64 GB)     | 3 P10 (128 GB)   | P20 (512 GB)   | P6 (64 GB) | P20 (512 GB)    |
| M64ls     | Standard_M64ls      | P6 (64 GB)    | 4 P10 (128 GB)   | 3 P10 (128 GB)   | P20 (512 GB)   | P6 (64 GB) | P30 (1024 GB)   |
| M64s      | Standard_M64s       | P10 (128 GB)  | 4 P15 (256 GB)   | 3 P15 (256 GB)   | P30 (1024 GB)  | P6 (64 GB) | P30 (1024 GB)   |
| M64ms     | Standard_M64ms      | P6 (64 GB)    | 4 P20 (512 GB)   | 3 P15 (256 GB)   | P30 (1024 GB)  | P6 (64 GB) | 2 P30 (1024 GB) |
| M128s     | Standard_M128s      | P10 (128 GB)  | 4 P20 (512 GB)   | 3 P15 (256 GB)   | P30 (1024 GB)  | P6 (64 GB) | 2 P30 (1024 GB) |
| M128ms    | Standard_M128m      | P10 (128 GB)  | 4 P30 (1024 GB)  | 3 P15 (256 GB)   | P30 (1024 GB)  | P6 (64 GB) | 4 P30 (1024 GB) |
| M208s_v2  | Standard_M208s_v2   | P10 (128 GB)  | 4 P30 (1024 GB)  | 3 P15 (256 GB)   | P30 (1024 GB)  | P6 (64 GB) | 3 P40 (2048 GB) |
| M208ms_v2 | Standard_M208ms_v2  | P10 (128 GB)  | 4 P40 (2048 GB)  | 3 P15 (256 GB)   | P30 (1024 GB)  | P6 (64 GB) | 3 P40 (2048 GB) |
| M416s_v2  | Standard_M416s_v2   | P10 (128 GB)  | 4 P40 (2048 GB)  | 3 P15 (256 GB)   | P30 (1024 GB)  | P6 (64 GB) | 3 P40 (2048 GB) |
| M416ms_v2 | Standard_M416m_v2   | P10 (128 GB)  | 4 P50 (4096 GB)  | 3 P15 (256 GB)   | P30 (1024 GB)  | P6 (64 GB) | 4 P50 (4096 GB) |

Table: Hana default disk sizing

### Any DB sizing ###

| Size    | VM SKU           | OS disk     | Data disks       | Log disks       |
|---------|------------------|-------------|------------------|-----------------|
| Default | Standard_E4s_v3  | P6 (64 GB)  | P15 (256 GB)     | P10 (128 GB)    |
| 200 GB  | Standard_E4s_v3  | P6 (64 GB)  | P15 (256 GB)     | P10 (128 GB)    |
| 500 GB  | Standard_E8s_v3  | P6 (64 GB)  | P20 (512 GB)     | P15 (256 GB)    |
| 1   TB  | Standard_E16s_v3 | P10(128 GB) | 2 P20 (512 GB)   | 2 P15 (256 GB)  |
| 2   TB  | Standard_E32s_v3 | P10(128 GB) | 2 P30 (1024 GB)  | 2 P20 (512 GB)  |
| 5   TB  | Standard_M64ls   | P10(128 GB) | 5 P30 (1024 GB)  | 2 P20 (512 GB)  |
| 10  TB  | Standard_M64s    | P10(128 GB) | 5 P40 (2048 GB)  | 2 P20 (512 GB)  |
| 15  TB  | Standard_M64s    | P10(128 GB) | 4 P50 (4096 GB)  | 2 P20 (512 GB)  |
| 20  TB  | Standard_M64s    | P10(128 GB) | 5 P50 (4096 GB)  | 2 P20 (512 GB)  |
| 30  TB  | Standard_M128s   | P10(128 GB) | 8 P50 (4096 GB)  | 2 P40 (2048 GB) |
| 40  TB  | Standard_M128s   | P10(128 GB) | 10 P50 (4096 GB) | 2 P40 (2048 GB) |
| 50  TB  | Standard_M128s   | P10(128 GB) | 13 P50 (4096 GB) | 2 P40 (2048 GB) |

Table: AnyDB default disk sizing

### Providing custom disk configuration ###

The disk sizing can be changed by providing a custom json file to the deployment by specifying the following parameter ```db_disk_sizes_filename : "[PATH to json file]"``` in the parameter file. For more information see [Using_custom_disk_sizing.md](../Process_Documentation/Using_custom_disk_sizing.md)
