# Specify providers
terraform {
  required_providers {
    libvirt = {
      source = "dmacvicar/libvirt"
    }
    ansible = {
      source = "nbering/ansible"
      version = "1.0.4"
    }

  }

  backend "pg" {
    conn_str = "postgres://terraform:terraform@cicdtoolbox-db/terraform"
  }
}

provider "libvirt" {
  # Configuration options
  uri = "qemu+ssh://kvmuser@kvmhost/system"
}