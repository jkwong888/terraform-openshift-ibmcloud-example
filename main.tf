
resource "random_id" "tag" {
    byte_length = 4
}

module "infrastructure" {
    source                = "github.com/jkwong888/terraform-openshift-infra-ibmcloud-classic"
    datacenter            = "${var.datacenter}"
    domain                = "${var.domain}"
    hostname_prefix       = "${var.hostname_prefix}"
    vlan_count            = "${var.vlan_count}"
    public_vlanid         = "${var.public_vlanid}"
    private_vlanid        = "${var.private_vlanid}"
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

    openshift_node_count = "${var.master["nodes"] + var.worker["nodes"] + var.infra["nodes"] +  var.storage["nodes"]}"

}

module "rhnregister" {
  source = "github.com/ibm-cloud-architecture/terraform-openshift-rhnregister.git?ref=v1.0"
  bastion_ip_address = "${module.infrastructure.bastion_public_ip}"
  private_ssh_key    = "${var.private_ssh_key}"
  ssh_username       = "${var.ssh_user}"
  rhn_username       = "${var.rhn_username}"
  rhn_password       = "${var.rhn_password}"
  rhn_poolid         = "${var.rhn_poolid}"
  all_nodes          = "${local.rhn_all_nodes}"
  all_count          = "${local.rhn_all_count}"
}

module "dns" {
    source                   = "github.com/ibm-cloud-architecture/terraform-dns-cloudflare.git?ref=v1.0"

    cloudflare_email         = "${var.cloudflare_email}"
    cloudflare_token         = "${var.cloudflare_token}"
    cloudflare_zone          = "${var.domain}"

    num_nodes = "${local.rhn_all_count}"
    num_cnames = 2

    nodes                    = "${zipmap(
        concat(
            list(module.infrastructure.bastion_hostname),
            module.infrastructure.master_hostname,
            module.infrastructure.app_hostname,
            module.infrastructure.infra_hostname,
            module.infrastructure.storage_hostname
        ),
        concat(
            list(module.infrastructure.bastion_public_ip),
            module.infrastructure.master_private_ip,
            module.infrastructure.app_private_ip,
            module.infrastructure.infra_private_ip,
            module.infrastructure.storage_private_ip
        )
    )}"

    cnames                   = "${zipmap(
        concat(
            list("${var.master_cname}-${random_id.tag.hex}"),
            list("*.${var.app_cname}-${random_id.tag.hex}")
        ),
        concat(
            list("${module.infrastructure.public_master_vip}"),
            list("${module.infrastructure.public_app_vip}")
        )
    )}"
}

module "certs" {
    source                   = "github.com/ibm-cloud-architecture/terraform-certs-letsencrypt-cloudflare?ref=v1.0"

    cloudflare_email         = "${var.cloudflare_email}"
    cloudflare_token         = "${var.cloudflare_token}"
    letsencrypt_email        = "${var.letsencrypt_email}"

    cluster_cname            = "${var.master_cname}-${random_id.tag.hex}.${var.domain}"
    app_subdomain            = "${var.app_cname}-${random_id.tag.hex}.${var.domain}"
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
    source = "github.com/ibm-cloud-architecture/terraform-dns-etc-hosts.git?ref=v1.0"
    bastion_ip_address      = "${module.infrastructure.bastion_public_ip}"
    ssh_user                = "${var.ssh_user}"
    ssh_private_key         = "${var.private_ssh_key}"
    node_ips                = "${local.all_ips}"
    node_hostnames          = "${local.all_hostnames}"
    domain                  = "${var.domain}"

    num_nodes = "${local.openshift_node_count}"
}

# ####################################################
# Deploy openshift
# ####################################################
module "openshift" {
    dependson = [
        "${module.rhnregister.registered_resource}"
    ]

    source                  = "github.com/ibm-cloud-architecture/terraform-openshift-deploy"
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
    haproxy                 = "${var.haproxy}"
    pod_network_cidr        = "${var.network_cidr}"
    service_network_cidr    = "${var.service_network_cidr}"
    host_subnet_length      = "${var.host_subnet_length}"
    # admin_password          = "${random_string.password.result}"
    node_count              = "${local.openshift_node_count}"
    dnscerts                = true
    master_cert             = "${module.certs.master_cert}"
    master_key              = "${module.certs.master_key}"
    router_cert             = "${module.certs.router_cert}"
    router_key              = "${module.certs.router_key}"
    router_ca_cert          = "${module.certs.ca_cert}"

}

