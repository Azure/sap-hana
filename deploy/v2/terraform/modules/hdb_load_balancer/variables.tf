variable "resource_group_name" {
}

variable "location" {
}

variable "subnet_id" {
}

variable "frontend_ip" {
}

# The HANA DB Instance Number is used as part of the ports for the forwarding rules and
# Health Probe listener
variable "instance_number" {
  type        = string
  description = "The HANA DB Instance Number"
  default     = "00"
}

# Network interfaces are added to the back end pool
variable "network_interfaces" {
}


# Load Balancer Rules for HANA 2.0
locals {
  lb_ports = [
    "3${var.instance_number}13",
    "3${var.instance_number}15",
    "3${var.instance_number}40",
    "3${var.instance_number}41",
    "3${var.instance_number}42",
    "5${var.instance_number}13",
    "5${var.instance_number}14",
  ]
}
