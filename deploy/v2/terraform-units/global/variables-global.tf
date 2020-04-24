/*
                      /////// \\\\\\\
                ///////             \\\\\\\
         ////////                         \\\\\\\
   ///////                                      \\\\\\\
  (((((((   CAUTION:  GLOBALLY MAINTAINED FILE   )))))))
   \\\\\\\                                      ///////
         \\\\\\\                          ///////
               \\\\\\\              ///////
                     \\\\\\\  ///////
*/

# TODO: subscription map
# TODO: region map
# TODO: tags map

variable deployZone {
  type        = string
  description = "PUB (Public), PROTO (Prototype), NP (Non-Prod), PROD (Production)"
  default     = "NOT_SET"
}

variable region {
  type        = string
  description = "Region"
  default     = "NOT_SET"
}

# variable sapSID {
#   type        = string
#   description = "SAP SID"
#   default     = "NOT_SET"
# }

# variable iscsiVms {
#   type        = string
#   description = "Create iSCSI Servers"
#   default     = false
# }

# variable ipamVm {
#   type        = string
#   description = "Create IPAM Server"
#   default     = false
# }

# variable projectName {
#   type        = string
#   description = "Development Cycle Partitioning"
#   default     = "NOT_SET"
# }

# variable sapVnet {
#   type        = string
#   description = "VNET"
#   default     = "NOT_SET"
# }

# variable landscape {
#   type        = string
#   description = "SAP Product"
#   default     = "NOT_SET"
# }

# variable sapAppSubnetSize {
#   type        = string
#   description = "1=27, 2=26, 3=25"
#   default     = 1
# }

# variable sapAppCount {
#   type        = string
#   description = "Number of Application Servers; Minimum: 1"
#   default     = 1
# }

# variable sapWebCount {
#   type        = string
#   description = "Number of Web Dispatchers; Minimum: 0"
#   default     = 1
# }

# variable hdbSize {
#   type        = string
#   description = "HANA DB size map"
#   default     = "NOT_SET"
# }

# variable hdbResiliency {
#   type        = string
#   description = "SA: Stand-Alone; HA: High-Availability"
#   default     = "SA"
# }

# variable scsResiliency {
#   type        = string
#   description = "SA: Stand-Alone; HA: High-Availability"
#   default     = "SA"
# }

# variable logicalNetwork {
#   type        = string
#   description = "Logical Network Partitioning"
#   default     = 0
# }

# variable dnsZoneName {
#   type        = string
#   description = "Remote State Resource Group"
#   default     = "NOT_SET"
# }

# variable rs_vnetId {
#   type        = string
#   description = "Remote State VNET ID"
#   default     = "NOT_SET"
# }

# variable rs_vnetName {
#   type        = string
#   description = "Remote State VNET Name"
#   default     = "NOT_SET"
# }

# variable rs_rgName {
#   type        = string
#   description = "Remote State Resource Group"
#   default     = "NOT_SET"
# }

# variable rs_dnsZoneName {
#   type        = string
#   description = "Remote State Resource Group"
#   default     = "NOT_SET"
# }

/*-----------------------------------------------------------------------------8
|                                                                              |
|                                     SDU                                      |
|                                                                              |
+--------------------------------------4--------------------------------------*/
# variable rs_deployZone {
#   type        = string
#   description = "Remote State Deployment Zone"
#   default     = ""
# }

# variable rs_region {
#   type        = string
#   description = "Remote State Region"
#   default     = ""
# }

# variable rs_routeTableId {
#   type        = string
#   description = "Remote State Route Table ID"
#   default     = ""
# }

# variable rs_diagPrimaryBlobEndpoint {
#   type        = string
#   description = "Remote State Storage URI - diag"
#   default     = ""
# }

# variable EnableSduHdb {
#   type        = string
#   description = "SAP SDU HDB"
#   default     = true
# }

# variable EnableSduApp {
#   type        = string
#   description = "SAP SDU APP"
#   default     = true
# }

# variable rgName {
#   type        = string
#   description = "Resource Group Name"
#   default     = "NOT_SET"
# }

# variable rgRegion {
#   type        = string
#   description = "Region"
#   default     = "NOT_SET"
# }

/*-----------------------------------------------------------------------------8
|                                                                              |
|                                                                              |
|                                                                              |
+--------------------------------------4--------------------------------------*/
# variable osImage {
#   type        = string
#   description = "Custom OS Image to use"
#   default     = "NOT_SET"
# }

# variable addressSpace {
#   type        = list(string)
#   description = "Address Space to be used"
#   default     = ["NOT_SET"]
# }

# variable remotePeeringID {
#   type        = string
#   description = "ID of VNET to peer to"
#   default     = "NOT_SET"
# }

# variable deployPortal {
#   type        = string
#   description = "Is there a Deploy Portal in the Environment"
#   default     = "NOT_SET"

# }

# variable testSizing {
#   type        = string
#   description = "Use Smaller VMs for Testing"
#   default     = false
# }

# variable  deployPortalAnsibleKeyMap {
#   type    = map(string)
#   default = {
#       PUB   = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDUG8H0kZNIpQFj8L0Ue9ZRI2MYYUw1j35iLCmzq7RrOOrUtyx9ILdrTzWr/aavq6zaBiU6kJgKztCy6lopxYbY4MC7LSKXDaTOmbLvyhZBSHyi2tXThblu7Co6f9YzvBLx/NvA7R4z1ne++wSm+qTN9SaUr1K9wJ7Bt2CvE5HlMIjbW3JBuf3TXDxETz6o3ztyYwGQjeY35GZHTibcGyTmg35kTDxI/do7AfII5eukqA/vEHK+Ieo1cMfUMAhkFAwYmCvN4CVb12gO9/ONBDH+lSQ//zyN56jxe6kAI9gW5cw3gUktf3Ol3n/XslUtEitX7gEAGTTAWSTyPkxzEsgL Ansible PUB MS PM SAP Automation"
#       PROTO = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC08lfVvcY0ptVNIH9wU7SDDmSchAjIlB0jzHzT5TLzKL+9/3v5tI7gT94XKkPz95S88LVhW3vR9dR8R0LwcCULpyXzgQ66K4NIki/LSp753iYeU9tnwHtYucbxkfp8qubXbUw2/gEq/uabmNP6WE/oL4OfcvzVlHiBbQLgjyLXQBLLTtJLWfns/yyC4nN/xpzfJyaHyazUf17QMaCNg09Jlpm5IR7mH+azqaLUHtq1er28RY9kqfYNDssNcTAtTBrzH2jed/5pBGIuY+sbFHkvSO9wlxTvfDlxFSIZcbp7ZjdZIBnN6WTXbRnZ2ODYlCybi7cG6vP/fAx115/qSD1l Ansible PROTO MS PM SAP Automation"
#       NP    = ""
#       PROD  = ""      
#   }
# }

/*-----------------------------------------------------------------------------8
|                                                                              |
|                                   MAPPINGS                                   |
|                                                                              |
+--------------------------------------4--------------------------------------*/
variable tags {
  type        = map(string)
  description = "Tags for Resources"
  default = {
    Workload                              = "SAP"
    Deployment                            = "SAP on Azure Automation"
    OwnerAlias                            = "NOT_SET"
  }
}

variable "regionMap" {
  type        = map(string)
  description = "Region Mapping: Full = Single CHAR, 4-CHAR"

  # 28 Regions
  default = {
    westus              = "weus"
    westus2             = "wus2"
    centralus           = "ceus"
    eastus              = "eaus"
    eastus2             = "eus2"
    northcentralus      = "ncus"
    southcentralus      = "scus"
    westcentralus       = "wcus"
    northeurope         = "noeu"
    westeurope          = "weeu"
    eastasia            = "eaas"
    southeastasia       = "seas"
    brazilsouth         = "brso"
    japaneast           = "jpea"
    japanwest           = "jpwe"
    centralindia        = "cein"
    southindia          = "soin"
    westindia           = "wein"
    uksouth2            = "uks2"
    uknorth             = "ukno"
    canadacentral       = "cace"
    canadaeast          = "caea"
    australiaeast       = "auea"
    australiasoutheast  = "ause"
    uksouth             = "ukso"
    ukwest              = "ukwe"
    koreacentral        = "koce"
    koreasouth          = "koso"
  }
}

variable deployZoneMap {
  type        = map(string)
  description = "PUB (Public), PROTO (Prototype), NP (Non-Prod), PROD (Production)"
  default     = {
    PUB                 = "Z"
    PROTO               = "X"
    NP                  = "N"
    PROD                = "P"
  }
}

# variable "vmSkuMap" {
#   type        = map(string)
#   description = "VM Size Map"

#   # Fields:
#   #   1st = VM SKU
#   #   2nd = Accelerated Networking
#   default = {
#     IPAM                = "Standard_D2s_v3,false"
#     ISCSI               = "Standard_D2s_v3,false"
#     SAPAPP              = "Standard_E16s_v3,true"
#     SAPSCS              = "Standard_D8s_v3,false"
#     SAPWEB              = "Standard_D4s_v3,false"
#   }
# }

# variable "vmSkuMapTesting" {
#   type        = map(string)
#   description = "VM Size Map"

#   # Fields:
#   #   1st = VM SKU
#   #   2nd = Accelerated Networking
#   default = {
#     IPAM                = "Standard_D2s_v3,false"
#     ISCSI               = "Standard_D2s_v3,false"
#     SAPAPP              = "Standard_D2s_v3,false"
#     SAPSCS              = "Standard_D4s_v3,false"
#     SAPWEB              = "Standard_D2s_v3,false"
#   }
# }

# variable hdbSizeMap {
#   type        = map(string)
#   description = "HANA DB VM Size Map"

#   # Fields:
#   #   1st = VM SKU
#   #   2nd = Accelerated Networking
#   #   3rd = Storage
#   default = {
#     0                   = "Standard_M32ls,true,256"   # vCPU:   32; RAM:    256G
#     1                   = "Standard_M64ls,true,512"   # vCPU:   64; RAM:    512G
#     2                   = "Standard_M64s,true,1024"   # vCPU:   64; RAM:   1024G
#     3                   = "Standard_M128s,true,2048"  # vCPU:  128; RAM:   2048G
#     4                   = "Standard_M128ms,true,3892" # vCPU:  128; RAM:   3892G
#     5                   = ""
#     6                   = ""
#     7                   = ""
#     8                   = ""
#     9                   = ""
#     99                  = "Standard_D8s_v3,false,512" # Test: D8s_v3
#   }
# }

# variable subnetMap {
#   type        = map(string)
#   description = "SID to Subnet Mapping"

#   # Fields:
#   #   1st = HANA          /28
#   #   2nd = Application   /28 - sapAppSubnetSize
# # /24   0
# # /25   0                                             128
# # /26   0                      64                     128                     192
# # /27   0          32          64          96         128         160         192         224
# # /28   0    16    32    48    64    80    96   112   128   144   160   176   192   208   224   240

#   default = {
#     Z00                   = "10.4.1.0,10.4.2.0"
#     Z01                   = "10.4.1.16,10.4.2.32"
#     Z02                   = "10.4.1.32,10.4.2.64"
#     Z03                   = "10.4.1.48,10.4.2.96"
#     Z04                   = "10.4.1.64,10.4.2.112"
#   }
# }


