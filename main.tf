
resource "random_id" "tag" {
    byte_length = 4
}

module "infrastructure" {
    source                = "git::ssh://git@github.ibm.com/ncolon/terraform-openshift-ibminfra.git"
    ibm_sl_username       = "${var.ibm_sl_username}"
    ibm_sl_api_key        = "${var.ibm_sl_api_key}"
    datacenter            = "${var.datacenter}"
    domain                = "${var.domain}"
    hostname_prefix       = "${var.hostname_prefix}"
    vlan_count            = "${var.vlan_count}"
    public_vlanid         = "${var.public_vlanid}"
    private_vlanid        = "${var.private_vlanid}"
    private_ssh_key       = "${var.private_ssh_key}"
    ssh_public_key        = "${var.public_ssh_key}"
    private_ssh_key       = "${var.private_ssh_key}"
    hourly_billing        = "${var.hourly_billing}"
    os_reference_code     = "${var.os_reference_code}"
    master                = "${var.master}"
    infra                 = "${var.infra}"
    worker                = "${var.worker}"
    storage               = "${var.storage}"
    bastion               = "${var.bastion}"
    haproxy               = "${var.haproxy}"
}


locals {
    rhn_all_nodes = "${concat(
        "${list(module.infrastructure.bastion_public_ip)}",
        "${module.infrastructure.master_private_ip}",
        "${module.infrastructure.infra_private_ip}",
        "${module.infrastructure.app_private_ip}",
        "${module.infrastructure.storage_private_ip}",
    )}"
    rhn_all_count = "${var.bastion["nodes"] + var.master["nodes"] + var.infra["nodes"] + var.worker["nodes"] + var.storage["nodes"] + var.haproxy["nodes"]}"
}

module "rhnregister" {
  source = "git::ssh://git@github.ibm.com/ncolon/terraform-openshift-rhnregister.git"
  bastion_ip_address = "${module.infrastructure.bastion_public_ip}"
  private_ssh_key    = "${var.private_ssh_key}"
  ssh_username       = "${var.ssh_user}"
  rhn_username       = "${var.rhn_username}"
  rhn_password       = "${var.rhn_password}"
  rhn_poolid         = "${var.rhn_poolid}"
  all_nodes          = "${local.rhn_all_nodes}"
  all_count          = "${local.rhn_all_count}"
}

module "dnscerts" {
    source                   = "git::ssh://git@github.ibm.com/ncolon/terraform-openshift-dnscerts.git"
    dnscerts                 = "${var.dnscerts}"
    cloudflare_email         = "${var.cloudflare_email}"
    cloudflare_token         = "${var.cloudflare_token}"
    cloudflare_zone          = "${var.domain}"
    letsencrypt_email        = "${var.letsencrypt_email}"
    public_master_vip        = "${module.infrastructure.public_master_vip}"
    public_app_vip           = "${module.infrastructure.public_app_vip}"
    master_cname             = "${var.master_cname}-${random_id.tag.hex}"
    app_cname                = "${var.app_cname}-${random_id.tag.hex}"
    bastion_public_ip        = "${module.infrastructure.bastion_public_ip}"
    bastion_hostname         = "${module.infrastructure.bastion_hostname}"
    master_hostname          = "${module.infrastructure.master_hostname}"
    app_hostname             = "${module.infrastructure.app_hostname}"
    infra_hostname           = "${module.infrastructure.infra_hostname}"
    storage_hostname         = "${module.infrastructure.storage_hostname}"
    master_private_ip        = "${module.infrastructure.master_private_ip}"
    app_private_ip           = "${module.infrastructure.app_private_ip}"
    infra_private_ip         = "${module.infrastructure.infra_private_ip}"
    storage_private_ip       = "${module.infrastructure.storage_private_ip}"
    cluster_cname            = "${var.master_cname}-${random_id.tag.hex}.${var.domain}"
    app_subdomain            = "${var.app_cname}-${random_id.tag.hex}.${var.domain}"
    letsencrypt_dns_provider = "${var.letsencrypt_dns_provider}"
    letsencrypt_api_endpoint = "${var.letsencrypt_api_endpoint}"
    bastion_public_ip        = "${module.infrastructure.bastion_public_ip}"
    bastion_ssh_key_file     = "${var.private_ssh_key}"
    ssh_username             = "${var.ssh_user}"
    master                   = "${var.master}"
    infra                    = "${var.infra}"
    worker                   = "${var.worker}"
    storage                  = "${var.storage}"
    bastion                  = "${var.bastion}"
    haproxy                  = "${var.haproxy}"
}

# ####################################################
# Generate /etc/hosts files
# ####################################################
locals {
    all_ips = "${concat(
        "${module.infrastructure.master_private_ip}",
        "${module.infrastructure.infra_private_ip}",
        "${module.infrastructure.app_private_ip}",
        "${module.infrastructure.storage_private_ip}",
    )}"
    all_hostnames = "${concat(
        "${module.infrastructure.master_hostname}",
        "${module.infrastructure.infra_hostname}",
        "${module.infrastructure.app_hostname}",
        "${module.infrastructure.storage_hostname}",
    )}"
}

module "etchosts" {
    source = "git::ssh://git@github.ibm.com/ncolon/terraform-dns-etc-hosts.git"
    bastion_ip_address      = "${module.infrastructure.bastion_public_ip}"
    ssh_user                = "${var.ssh_user}"
    ssh_private_key         = "${var.private_ssh_key}"
    node_ips                = "${local.all_ips}"
    node_hostnames          = "${local.all_hostnames}"
    domain                  = "${var.domain}"
}

# ####################################################
# Deploy openshift
# ####################################################
module "openshift" {
    source                  = "git::ssh://git@github.ibm.com/ncolon/terraform-openshift-deploy.git"
    bastion_ip_address      = "${module.infrastructure.bastion_public_ip}"
    bastion_private_ssh_key = "${var.private_ssh_key}"
    master_private_ip       = "${module.infrastructure.master_private_ip}"
    infra_private_ip        = "${module.infrastructure.infra_private_ip}"
    app_private_ip          = "${module.infrastructure.app_private_ip}"
    storage_private_ip      = "${module.infrastructure.storage_private_ip}"
    bastion_hostname        = "${module.infrastructure.bastion_hostname}"
    master_hostname         = "${module.infrastructure.master_hostname}"
    infra_hostname          = "${module.infrastructure.infra_hostname}"
    app_hostname            = "${module.infrastructure.app_hostname}"
    storage_hostname        = "${module.infrastructure.storage_hostname}"
    domain                  = "${var.domain}"
    bastion_private_ssh_key = "${var.private_ssh_key}"
    ssh_user                = "${var.ssh_user}"
    cloudprovider           = "${var.cloudprovider}"
    bastion                 = "${var.bastion}"
    master                  = "${var.master}"
    infra                   = "${var.infra}"
    worker                  = "${var.worker}"
    storage                 = "${var.storage}"
    ose_version             = "${var.ose_version}"
    ose_deployment_type     = "${var.ose_deployment_type}"
    image_registry          = "${var.image_registry}"
    image_registry_username = "${var.image_registry_username == "" ? var.rhn_username : ""}"
    image_registry_password = "${var.image_registry_password == "" ? var.rhn_password : ""}"
    master_cluster_hostname = "${module.infrastructure.public_master_vip}"
    cluster_public_hostname = "${var.master_cname}-${random_id.tag.hex}.${var.domain}"
    app_cluster_subdomain   = "${var.app_cname}-${random_id.tag.hex}.${var.domain}"
    registry_volume_size    = "${var.registry_volume_size}"
    dnscerts                = "${var.dnscerts}"
    haproxy                 = "${var.haproxy}"
    pod_network_cidr        = "${var.network_cidr}"
    service_network_cidr    = "${var.service_network_cidr}"
    host_subnet_length      = "${var.host_subnet_length}"
    storageprovider         = "${var.storageprovider}"
    # admin_password          = "${random_string.password.result}"
}
# ####################################################
# Copy kube config file to local machine
# ####################################################
module "kubeconfig" {
    source                  = "git::ssh://git@github.ibm.com/ncolon/terraform-openshift-kubeconfig.git"
    bastion_ip_address      = "${module.infrastructure.bastion_public_ip}"
    bastion_private_ssh_key = "${var.private_ssh_key}"
    master_private_ip       = "${module.infrastructure.master_private_ip}"
    cluster_name            = "${var.hostname_prefix}-${random_id.tag.hex}"
    ssh_username            = "${var.ssh_user}"
}
