terraform {
  # The configuration for this backend will be filled in by Terragrunt
  backend "s3" {
  }
  required_providers {
    ansible = {
      source = "nbering/ansible"
      version = "~>1.0"
    }
    openstack = {
      source = "terraform-provider-openstack/openstack"
      version = "~> 1.53.0"
    }
  }
}

resource "openstack_networking_floatingip_v2" "fip" {
  pool = var.floatingip_pool
}

resource "openstack_compute_floatingip_associate_v2" "fip" {
  instance_id = openstack_compute_instance_v2.manage.id
  floating_ip = openstack_networking_floatingip_v2.fip.address
}

resource "openstack_compute_instance_v2" "manage" {
  name            = var.environment_name
  flavor_name     = var.flavor_name
  key_pair        = var.key_name
  security_groups = [var.security_group_name]
  user_data       = local.cloudconfig

  # Keep the root disk on a volume
  block_device {
    uuid             = var.block_device_source_id
    source_type      = var.block_device_type
    volume_size      = 30
    boot_index       = 0
    destination_type = "volume"

    # This is messy but necessary because of how we resize
    delete_on_termination = false
  }

  network {
    name = var.network_name
  }
}

# Determine the volume UUIDs, whether if existing ones were supplied
# or if new ones were created.
locals {
  vol_id_1 = length(var.existing_volumes) == 0 ? element(
    concat(openstack_blockstorage_volume_v3.datadir.*.id, [""]),
    0,
  ) : element(concat(var.existing_volumes, [""]), 0)
}

resource "openstack_blockstorage_volume_v3" "datadir" {
  count = length(var.existing_volumes) == 0 ? 1 : 0
  name  = format("%s-datadir-%02d", var.environment_name, count.index + 1)
  size  = var.vol_datadir_size
}

resource "openstack_compute_volume_attach_v2" "datadir_1" {
  instance_id = openstack_compute_instance_v2.manage.id
  volume_id   = local.vol_id_1
}

resource "ansible_group" "manage" {
  inventory_group_name = "manage"
}

resource "ansible_group" "jupyter" {
  inventory_group_name = "jupyter"
  children             = ["manage"]
}

resource "ansible_host" "manage" {
  inventory_hostname = "${var.environment_name}.${var.domain_name}"
  groups             = ["manage"]

  vars = {
    ansible_user            = "ptty2u"
    ansible_host            = openstack_networking_floatingip_v2.fip.address
    ansible_ssh_common_args = "-C -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
    syzygy_datadir_id = "/dev/disk/by-id/virtio-${substr(
      openstack_compute_volume_attach_v2.datadir_1.volume_id,
      0,
      20,
    )}"
  }
}
