
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
    bastion_flavor        = "${var.bastion_flavor}"
    master_flavor         = "${var.master_flavor}"
    infra_flavor          = "${var.infra_flavor}"
    app_flavor            = "${var.app_flavor}"
    storage_flavor        = "${var.storage_flavor}"
    private_ssh_key       = "${var.private_ssh_key}"
    ssh_public_key        = "${var.public_ssh_key}"
    bastion_ssh_key_file  = "${var.bastion_ssh_key_file}"
    hourly_billing        = "${var.hourly_billing}"
    os_reference_code     = "${var.os_reference_code}"
}

module "rhnregister" {
    source                  = "git::ssh://git@github.ibm.com/ncolon/terraform-openshift-rhnregister.git"
    master_ip_address       = "${module.infrastructure.master_private_ip}"
    master_private_ssh_key  = "${var.private_ssh_key}"
    rhn_username            = "${var.rhn_username}"
    rhn_password            = "${var.rhn_password}"
    rhn_poolid              = "${var.rhn_poolid}"
    infra_ip_address        = "${module.infrastructure.infra_private_ip}"
    infra_private_ssh_key   = "${var.private_ssh_key}"
    app_ip_address          = "${module.infrastructure.app_private_ip}"
    app_private_ssh_key     = "${var.private_ssh_key}"
    storage_ip_address      = "${module.infrastructure.storage_private_ip}"
    storage_private_ssh_key = "${var.private_ssh_key}"
    bastion_ip_address      = "${module.infrastructure.bastion_public_ip}"
    bastion_private_ssh_key = "${var.private_ssh_key}"
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
    cloudflare_email         = "${var.cloudflare_email}"
    cloudflare_token         = "${var.cloudflare_token}"
    cluster_cname            = "${var.master_cname}-${random_id.tag.hex}.${var.domain}"
    app_subdomain            = "${var.app_cname}-${random_id.tag.hex}.${var.domain}"
    letsencrypt_dns_provider = "${var.letsencrypt_dns_provider}"
    letsencrypt_api_endpoint = "${var.letsencrypt_api_endpoint}"
    bastion_public_ip        = "${module.infrastructure.bastion_public_ip}"
    bastion_ssh_key_file     = "${var.private_ssh_key}"
}


module "inventory" {
    source                  = "git::ssh://git@github.ibm.com/ncolon/terraform-openshift-inventory.git"
    domain                  = "${var.domain}"
    bastion_ip_address      = "${module.infrastructure.bastion_public_ip}"
    master_private_ip       = "${module.infrastructure.master_private_ip}"
    infra_private_ip        = "${module.infrastructure.infra_private_ip}"
    app_private_ip          = "${module.infrastructure.app_private_ip}"
    storage_private_ip      = "${module.infrastructure.storage_private_ip}"
    bastion_hostname        = "${module.infrastructure.bastion_hostname}"
    master_hostname         = "${module.infrastructure.master_hostname}"
    infra_hostname          = "${module.infrastructure.infra_hostname}"
    app_hostname            = "${module.infrastructure.app_hostname}"
    storage_hostname        = "${module.infrastructure.storage_hostname}"
    bastion_private_ssh_key = "${var.private_ssh_key}"
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
    storage                 = "${var.storage}"
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
    master_hostname         = "${module.infrastructure.master_hostname}"
    infra_hostname          = "${module.infrastructure.infra_hostname}"
    app_hostname            = "${module.infrastructure.app_hostname}"
    storage_hostname        = "${module.infrastructure.storage_hostname}"
    domain                  = "${var.domain}"
    bastion_ip_address      = "${module.infrastructure.bastion_public_ip}"
    bastion_private_ssh_key = "${var.private_ssh_key}"
    bastion                 = "${var.bastion}"
    master                  = "${var.master}"
    infra                   = "${var.infra}"
    worker                  = "${var.worker}"
    storage                 = "${var.storage}"
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
}
