variable "resource_group_name" {
}

variable "location" {
}

variable "subnet_id" {
}

variable "frontend_ip" {
}

# The HANA DB Instance Number and Version are used to determine the ports for the
# Pacemaker Port forwarding rules and the Health Probe listener port
variable "instance_number" {
  type        = string
  description = "The HANA DB Instance Number"
  default     = "00"
}

variable "db_version" {
  type        = string
  description = "The HANA DB Version"
  default     = "2.0"
}

# Network interfaces are added to the back end pool
variable "network_interfaces" {
}

# Pacemaker Load Balancer Ports for HANA 1 and 2.0
locals {
  lb_ports_src = {
    "1" = [
      "3${var.instance_number}15",
      "3${var.instance_number}17",
    ]

    "2.0" = [
      "3${var.instance_number}13",
      "3${var.instance_number}15",
      "3${var.instance_number}40",
      "3${var.instance_number}41",
      "3${var.instance_number}42",
      "5${var.instance_number}13",
      "5${var.instance_number}14",
    ]
  }

  lb_ports = lookup(local.lb_ports_src, var.db_version, local.lb_ports_src["2.0"])
}
