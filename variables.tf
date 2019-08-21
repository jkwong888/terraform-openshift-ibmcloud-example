variable "ibm_sl_username" {}
variable "ibm_sl_api_key" {}
variable "datacenter" {}

variable "domain" {
    default = ""
}

variable "hostname_prefix" {
    default = ""
}

variable "private_ssh_key" {
    default = "~/.ssh/openshift_rsa"
}

variable "public_ssh_key" {
    default = "~/.ssh/openshift_rsa.pub"
}

variable "vlan_count" {
    default = 0
}

variable "public_vlanid" {
    default = ""
}

variable "private_vlanid" {
    default = ""
}


variable "hourly_billing" {
    default = "true"
}

variable "rhn_username" {}
variable "rhn_password" {}
variable "rhn_poolid" {}

variable "dnscerts" {
    default = "false"
}

variable "cloudflare_email" {}
variable "cloudflare_token" {}
variable "master_cname" {}
variable "app_cname" {}
variable "letsencrypt_email" {}
variable "letsencrypt_api_endpoint" {
    default = "https://acme-v02.api.letsencrypt.org/directory"
}
variable "letsencrypt_dns_provider" {}

variable "ose_version" {
    default = "3.11"
}
variable "ose_deployment_type" {
    default = "openshift-enterprise"
}

variable "os_reference_code" {
  description = "IBM Cloud OS reference code to determine OS, version, word length.  For OpenShift/OKD this needs to be either REDHAT_7_64 (OpenShift Enterprise) or CENTOS_7_64 (OKD)"
  default = "REDHAT_7_64"
}

variable "image_registry" {
    default = "registry.redhat.io"
}

variable "image_registry_path" {
    default = "/openshift3/ose-$${component}:$${version}"
}

variable "image_registry_username" {
    default = ""
}
variable "image_registry_password" {
    default = ""
}

variable "registry_volume_size" {
    default = "100"
}

variable "openshift_vm_admin_user" {
    default = "root"
}

variable "bastion" {
  type = "map"
  default = {
    nodes  = "1"
    vcpu   = "2"
    memory = "8192"
    disk_size             = "100"      # Specify size or leave empty to use same size as template.
    datastore_disk_size   = "50"    # Specify size datastore directory, default 50.
  }
}

variable "master" {
  type = "map"
    default = {
    nodes  = "1"
    vcpu   = "8"
    memory = "32768"
    disk_size             = "100"      # Specify size or leave empty to use same size as template.
    docker_disk_size      = "100"   # Specify size for docker disk, default 100.
    docker_disk_device    = "/dev/xvdc"
  }
}

variable "infra" {
  type = "map"
    default = {
    nodes  = "1"
    vcpu   = "8"
    memory = "32768"
    disk_size           = "100"      # Specify size or leave empty to use same size as template.
    docker_disk_size    = "100"   # Specify size for docker disk, default 100.
    docker_disk_device  = "/dev/xvdc"
  }
}

variable "worker" {
  type = "map"
    default = {
    nodes  = "1"
    vcpu   = "8"
    memory = "32768"
    disk_size           = "100"      # Specify size or leave empty to use same size as template.
    docker_disk_size    = "100"   # Specify size for docker disk, default 100.
    docker_disk_device  = "/dev/xvdc"
  }
}

variable "storage" {
  type = "map"
    default = {
    nodes  = "3"
    vcpu   = "8"
    memory = "16384"
    disk_size           = "100"      # Specify size or leave empty to use same size as template.
    docker_disk_size    = "100"   # Specify size for docker disk, default 100.
    docker_disk_device  = "/dev/xvdc"
    gluster_disk_size   = "250"
    gluster_disk_device = "/dev/xvde"
  }
}

variable "haproxy" {
  type = "map"
  default = {
    nodes               = "0"
    vcpu                = "2"
    memory              = "8192"
    disk_size           = "100"      # Specify size or leave empty to use same size as template.
  }
}

variable "cloudprovider" {
  default = "ibm"
}

variable "ssh_user" {
  default = "root"
}

variable "network_cidr" {
    default = "10.128.0.0/14"
}

variable "service_network_cidr" {
    default = "172.30.0.0/16"
}

variable "host_subnet_length" {
    default = 9
}

variable "storageprovider" {
    default = "glusterfs"
}
