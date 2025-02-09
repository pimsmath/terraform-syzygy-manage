output "instance_uuid" {
  value = openstack_compute_instance_v2.manage.id
}

output "floating_ip" {
  value = openstack_networking_floatingip_v2.fip.address
}

output "homedir_id" {
  value = "/dev/disk/by-id/virtio-${substr(
    openstack_compute_volume_attach_v2.datadir_1.volume_id,
    0,
    20,
  )}"
}
