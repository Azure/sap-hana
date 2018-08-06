# Create bastion and single HANA node by calling the modules
provider "azurerm" {}

# Create a resource group
resource "azurerm_resource_group" "hana-resource-group" {
  name     = "${var.az_resource_group}"
  location = "${var.az_region}"

  tags {
    environment = "Terraform SAP HANA HA-pair deployment"
  }
}

# TODO(pabowers): switch to use the Terraform registry version when release for nsg support becomes available
module "vnet" {
  source  = "Azure/vnet/azurerm"
  version = "1.2.0"

  address_space       = "10.0.0.0/21"
  location            = "${var.az_region}"
  resource_group_name = "${var.az_resource_group}"
  subnet_names        = ["hdb-subnet"]
  subnet_prefixes     = ["10.0.0.0/24"]
  vnet_name           = "${var.sap_sid}-vnet"

  tags {
    environment = "Terraform HANA vnet and subnet creation"
  }
}

resource "azurerm_availability_set" "ha-pair-availset" {
  name                         = "hanaHAPairAvailabilitySet"
  location                     = "${azurerm_resource_group.hana-resource-group.location}"
  resource_group_name          = "${azurerm_resource_group.hana-resource-group.name}"
  platform_update_domain_count = 20                                                       # got these values from Tobias' deployment automatically created template.json
  platform_fault_domain_count  = 2
  managed                      = true

  tags {
    environment = "HA-Pair deployment"
  }
}

module "nsg" {
  source              = "../nsg_for_hana"
  resource_group_name = "${azurerm_resource_group.hana-resource-group.name}"
  az_region           = "${var.az_region}"
  sap_instancenum     = "${var.sap_instancenum}"
  sap_sid             = "${var.sap_sid}"
}

resource "azurerm_lb" "ha-pair-lb" {
  name                = "ha-pair-lb"
  location            = "${var.az_region}"
  resource_group_name = "${azurerm_resource_group.hana-resource-group.name}"

  frontend_ip_configuration {
    name                          = "hsr-front"
    subnet_id                     = "${module.vnet.vnet_subnets[0]}"
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.0.13"
  }
}

resource "azurerm_lb_probe" "health-probe" {
  resource_group_name = "${azurerm_resource_group.hana-resource-group.name}"
  loadbalancer_id     = "${azurerm_lb.ha-pair-lb.id}"
  name                = "health-probe"
  port                = "625${var.sap_instancenum}"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_backend_address_pool" "availability-back-pool" {
  resource_group_name = "${azurerm_resource_group.hana-resource-group.name}"
  loadbalancer_id     = "${azurerm_lb.ha-pair-lb.id}"
  name                = "BackEndAddressPool-HA"
}

resource "azurerm_lb_rule" "lb-rule0" {
  resource_group_name            = "${azurerm_resource_group.hana-resource-group.name}"
  loadbalancer_id                = "${azurerm_lb.ha-pair-lb.id}"
  name                           = "lb-rule-0"
  protocol                       = "Tcp"
  frontend_port                  = "3${var.sap_instancenum}15"
  backend_port                   = "3${var.sap_instancenum}15"
  idle_timeout_in_minutes        = 30
  enable_floating_ip             = true
  frontend_ip_configuration_name = "hsr-front"
}

resource "azurerm_lb_rule" "lb-rule1" {
  resource_group_name            = "${azurerm_resource_group.hana-resource-group.name}"
  loadbalancer_id                = "${azurerm_lb.ha-pair-lb.id}"
  name                           = "lb-rule-1"
  protocol                       = "Tcp"
  frontend_port                  = "3${var.sap_instancenum}17"
  backend_port                   = "3${var.sap_instancenum}17"
  idle_timeout_in_minutes        = 30
  enable_floating_ip             = true
  frontend_ip_configuration_name = "hsr-front"
}

module "create_db0" {
  source = "../create_db_node"

  availability_set_id   = "${azurerm_availability_set.ha-pair-availset.id}"
  az_resource_group     = "${azurerm_resource_group.hana-resource-group.name}"
  az_region             = "${var.az_region}"
  backend_ip_pool_ids   = ["${azurerm_lb_backend_address_pool.availability-back-pool.id}"]
  db_num                = "0"
  hana_subnet_id        = "${module.vnet.vnet_subnets[0]}"
  nsg_id                = "${module.nsg.nsg-id}"
  private_ip_address    = "10.0.0.6"
  sap_sid               = "${var.sap_sid}"
  sshkey_path_public    = "${var.sshkey_path_public}"
  storage_disk_sizes_gb = "${var.storage_disk_sizes_gb}"
  vm_user               = "${var.vm_user}"
  vm_size               = "${var.vm_size}"
}

module "create_db1" {
  source = "../create_db_node"

  availability_set_id   = "${azurerm_availability_set.ha-pair-availset.id}"
  az_resource_group     = "${azurerm_resource_group.hana-resource-group.name}"
  az_region             = "${var.az_region}"
  backend_ip_pool_ids   = ["${azurerm_lb_backend_address_pool.availability-back-pool.id}"]
  db_num                = "1"
  hana_subnet_id        = "${module.vnet.vnet_subnets[0]}"
  nsg_id                = "${module.nsg.nsg-id}"
  private_ip_address    = "10.0.0.7"
  sap_sid               = "${var.sap_sid}"
  sshkey_path_public    = "${var.sshkey_path_public}"
  storage_disk_sizes_gb = "${var.storage_disk_sizes_gb}"
  vm_user               = "${var.vm_user}"
  vm_size               = "${var.vm_size}"
}

module "nic_and_pip_setup_iscsi" {
  source = "../generic_nic_and_pip"

  az_region          = "${var.az_region}"
  az_resource_group  = "${azurerm_resource_group.hana-resource-group.name}"
  name               = "iscsi"
  nsg_id             = "${module.nsg.nsg-id}"
  private_ip_address = "10.0.0.17"
  subnet_id          = "${module.vnet.vnet_subnets[0]}"
}

module "vm_and_disk_creation_iscsi" {
  source = "../generic_vm_and_disk_creation"

  sshkey_path_public    = "${var.sshkey_path_public}"
  az_resource_group     = "${azurerm_resource_group.hana-resource-group.name}"
  az_region             = "${var.az_region}"
  storage_disk_sizes_gb = [16]
  machine_name          = "iscsi"
  vm_user               = "${var.vm_user}"
  vm_size               = "Standard_D2s_v3"
  nic_id                = "${module.nic_and_pip_setup_iscsi.nic_id}"
  availability_set_id   = "${azurerm_availability_set.ha-pair-availset.id}"
  machine_type          = "iscsi-${azurerm_resource_group.hana-resource-group.name}"
}

module "configure_vm" {
  source = "../playbook-execution"

  az_resource_group   = "${azurerm_resource_group.hana-resource-group.name}"
  sshkey_path_private = "${var.sshkey_path_private}"
  sap_instancenum     = "${var.sap_instancenum}"
  sap_sid             = "${var.sap_sid}"
  vm_user             = "${var.vm_user}"
  url_sap_sapcar      = "${var.url_sap_sapcar}"
  url_sap_hdbserver   = "${var.url_sap_hdbserver}"
  pw_os_sapadm        = "${var.pw_os_sapadm}"
  pw_os_sidadm        = "${var.pw_os_sidadm}"
  pw_db_system        = "${var.pw_db_system}"
  useHana2            = "${var.useHana2}"
  vms_configured      = "${module.create_db0.machine_hostname}, ${module.create_db1.machine_hostname}, ${module.vm_and_disk_creation_iscsi.machine_hostname}"
}
