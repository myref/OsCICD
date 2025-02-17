variable "region" {
  description = "Apache Cloudstack-like region definition"
  type        = string
  default     = "somewhere"
}

variable "zone" {
  description = "Apache Cloudstack-like zone definition"
  type        = string
  default     = "ozone"
}

variable "pod" {
  description = "Apache Cloudstack-like pod definition"
  type        = string
  default     = "potty"
}

variable "cluster" {
  description = "Apache Cloudstack-like cluster definition"
  type        = string
  default     = "close"
}

variable "host" {
  description = "Apache Cloudstack-like host definition"
  type        = string
  default     = "worker"
}

variable "target_type" {
  description = "Device type"
  type        = string
  default     = "Node"
}

variable "target_name" {
  description = "Customer Name"
  type        = string
  default     = "SomeCustomer"
}

variable "os_version_name" {
  description = "OS release name"
  type        = string
  default     = "jammy"
}

variable "os_version" {
  description = "OS version"
  type        = string
  default     = "22.04"
}

variable "system_memory" {
  description = "System memory"
  type        = string
  default     = "2048"
}

variable "system_cores" {
  description = "System cores"
  type        = string
  default     = 2
}

variable "os_disk_size" {
  description = "Disk size for the OS"
  type        = string
  default     = 53687091200
}

variable "data_disk_size" {
  description = "Disk size for target data"
  type        = string
  default     = 2147483648
}

variable "kvm_user" {
  description = "User that deploys VMs on KVM host"
  type        = string
  default     = "kvmuser"
}

variable "git_commit" {
  description = "Short ID of the git commit"
  type        = string
  default     = "123456"
}