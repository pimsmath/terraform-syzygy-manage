# Most of the defaults below reflect settings on CC Arbutus

variable "environment_name" {
  description = "Environment name"
}

variable "domain_name" {
  description = "Domain name"
  default     = "syzygy.ca"
}

variable "block_device_source_id" {
  description = "UUID to create VM backing store from (typically a glance image ID)"
  default     = "83b4531c-e56a-4e55-b5d2-12d9a0d1afb2"
}

variable "block_device_type" {
  description = "Block device type for backing store"
  default     = "image"
}

variable "flavor_name" {
  description = "Flavor of instance (e.g. c2-7.5gb-31, provider dependent)"
  default     = "p2-3gb"
}

variable "key_name" {
  description = "Public key for ssh authentication"
  default     = "id-cc-openstack"
}

variable "security_group_name" {
  description = "Security group to assign to this host"
  default     = "syzygy"
}

variable "network_name" {
  description = "Network name to place instance on"
  default     = "rpp-colliand-network"
}

variable "existing_volumes" {
  description = "List of existing volumes to attach to instance"
  type        = list(string)
  default     = []
}

variable "floatingip_pool" {
  description = "Pool to select floating IPs from"
  default     = "Public-Network"
}

variable "vol_datadir_size" {
  description = "Size of ZFS datadir volume in gigabytes"
  default     = 500
}

locals {
  cloudconfig = <<EOF
    #cloud-config
    preserve_hostname: true
    system_info:
      default_user:
        name: ptty2u
  EOF
}
