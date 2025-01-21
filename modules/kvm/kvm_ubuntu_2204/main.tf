# Defining VM Volumes
resource "libvirt_volume" "target-os" {
  name      = "${var.target_type}-os.qcow2"
  pool      = "default"
#  source    = "images/focal-server-cloudimg-amd64-clone.img"
  source = "https://cloud-images.ubuntu.com/releases/${var.os_version_name}/release/ubuntu-${var.os_version}-server-cloudimg-amd64.img"
  format    = "qcow2"
}

resource "libvirt_volume" "target-data" {
  name      = "${var.target_type}-data.qcow2"
  pool      = "default"
  size      = var.data_disk_size
  format    = "qcow2"
}

# get user data info
data "template_file" "user_data" {
  template = "${file("${path.module}/cloud_init.cfg")}"
}

# Use CloudInit to add the instance
resource "libvirt_cloudinit_disk" "commoninit" {
  name = "commoninit.iso"
  pool = "default"
  user_data      = "${data.template_file.user_data.rendered}"
}

# Define KVM domain to create
resource "libvirt_domain" "target" {
  name        = "${var.target_type}-${var.target_name}"
  memory      = "2048"
  vcpu        = 2
  running     = true

  disk {
      volume_id = "${libvirt_volume.target-os.id}"
    }
  disk{
      volume_id = "${libvirt_volume.target-data.id}"
    }

  network_interface {
    network_name = "default" # List networks with virsh net-list
    wait_for_lease = true
  }

  cloudinit = "${libvirt_cloudinit_disk.commoninit.id}"

  console {
    type = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }
}

resource "ansible_host" "target" {
    inventory_hostname = "${var.target_type}-${var.target_name}"
    groups = ["${var.target_type}","${var.target_type}_test"]
    vars = {
        ansible_host = "${libvirt_domain.target.network_interface.0.addresses.0}"
    }
}