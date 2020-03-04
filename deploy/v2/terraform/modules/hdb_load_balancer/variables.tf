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
