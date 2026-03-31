terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.6"
    }
  }
}


provider "libvirt" {
  uri = "qemu+tcp://192.168.56.69/system"
}


# Pool
resource "libvirt_pool" "default" {
  name = "default"
  type = "dir"
  path = "/var/lib/libvirt/images"
}

# OS Image
resource "libvirt_volume" "debian" {
  name = "debian-13-genericcloud-amd64.qcow2"
  pool = libvirt_pool.default.name
  source = "https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
  format = "qcow2"

  depends_on = [libvirt_pool.default]
}

resource "libvirt_cloudinit_disk" "init" {
  name = "cloud-init.iso"       
  user_data = file("cloud-init.yml")  
}

# VM
resource "libvirt_domain" "vm1" {
  name   = "vm1"
  memory = 2048
  vcpu   = 2

  disk {
    volume_id = libvirt_volume.debian.id
  }

  network_interface {
    network_name = "default"
    mac = "52:54:00:12:34:56"
  }
  
  cloudinit = libvirt_cloudinit_disk.init.id  

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type = "vnc"
    listen_type = "address"
  }
}
