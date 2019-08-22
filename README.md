# terraform-openshift-ibmcloud-example

Sample terraform project leveraging multiple modules to deploy OpenShift into an user provided infrastructure.

In this example, we'll deploy OpenShift 3.11 to IBM Cloud IaaS. `terraform.tfvars` shows variables that can be passed to the whole project to build an OpenShift environment.


### Step 1:  Build infrastructure

Fork the [terraform-openshift-ibminfra](https://github.ibm.com/ncolon/terraform-openshift-ibminfra) module and include it in your terraform `main.tf` file.  Details on the variables used are found in this module's github.

```terraform
resource "random_id" "tag" {
    byte_length = 4
}

module "infrastructure" {
  source                = "git::ssh://git@github.ibm.com/<USERNAME>/terraform-openshift-ibminfra.git"
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
  hourly_billing        = "${var.hourly_billing}"
  os_reference_code     = "${var.os_reference_code}"
  master                = "${var.master}"
  infra                 = "${var.infra}"
  worker                = "${var.worker}"
  storage               = "${var.storage}"
  bastion               = "${var.bastion}"
  haproxy               = "${var.haproxy}"
}
```

Deploy the Infrastructure
```bash
$ terraform apply -target=module.infrastructure
```

### Step 2: Register VMs with RedHat Satelite

Fork the [terraform-openshift-rhnregister](https://github.ibm.com/ncolon/terraform-openshift-rhnregister) module and include it in your `main.tf` file.  It will pull necessary information from the infrastructure module above. Details on the variables used are found in this module's github.

You need to provide your own RedHat username (`rhn_username`) and password (`rhn_password`), as well as the OpenShift Subscription Pool (`rhn_poolid`) to draw licenses from.

```terraform
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
  source = "git::ssh://git@github.ibm.com/<USERNAME>/terraform-openshift-rhnregister.git"
  bastion_ip_address = "${module.infrastructure.bastion_public_ip}"
  private_ssh_key    = "${var.private_ssh_key}"
  ssh_username       = "${var.ssh_user}"
  rhn_username       = "${var.rhn_username}"
  rhn_password       = "${var.rhn_password}"
  rhn_poolid         = "${var.rhn_poolid}"
  all_nodes          = "${local.rhn_all_nodes}"
  all_count          = "${local.rhn_all_count}"
}
```

Register your servers with RHN
```bash
$ terraform apply -target=module.rhnregister
```

### Step 3: Register your infrastructure DNS.
OpenShift depends heavily on DNS.  We'll use cloudflare for DNS registrar and Letsencrypt for SSL certificates

Fork the [terraform-openshift-dnscerts](https://github.ibm.com/ncolon/terraform-openshift-ibminfra) and [terraform-dns-etc-hosts](https://github.ibm.com/ncolon/terraform-dns-etc-hosts) and include them in your `main.tf` file. It will pull necessary information from the infrastructure module above. Details on the variables used are found in this module's github.

The certificate module currently requires the cloudflare_email and cloudflare_token to be passed thru variables.  It will be converted to CLOUDFLARE_EMAIL and CLOUDFLARE_TOKEN env variables at a later date.

```terraform
module "dnscerts" {
    source                   = "git::ssh://git@github.ibm.com/<USERNAME>/terraform-openshift-dnscerts.git"
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
    source = "git::ssh://git@github.ibm.com/<USERNAME>/terraform-dns-etc-hosts.git"
    bastion_ip_address      = "${module.infrastructure.bastion_public_ip}"
    ssh_user                = "${var.ssh_user}"
    ssh_private_key         = "${var.private_ssh_key}"
    node_ips                = "${local.all_ips}"
    node_hostnames          = "${local.all_hostnames}"
    domain                  = "${var.domain}"
}

```

Register your servers with DNS and generate SSL certificates from LetsEncrypt.
```bash
$ terraform apply -target=module.dnscerts
$ terraform apply -target=module.etchosts
```


### Step 4: Deploy OpenShift
Fork the [terraform-openshift-deploy](https://github.ibm.com/ncolon/terraform-openshift-deploy) module and include it on your `main.tf` file. It will pull necessary information from the infrastructure module above. Details on the variables used are found in this module's github.

```terraform
module "openshift" {
    source                  = "git::ssh://git@github.ibm.com/<USERNAME>/terraform-openshift-deploy.git"
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
}
```

Deploy OpenShift
```bash
$ terraform apply -target=module.openshift
```

### Step 5:  Access your OpenShift Cluster
Fork the [terraform-openshift-kubeconfig](https://github.ibm.com/ncolon/terraform-openshift-kubeconfig) module and include it in your `main.tf` file. It will pull necessary information from the infrastructure module above. Details on the variables used are found in this module's github.

```terraform
module "kubeconfig" {
    source                  = "git::ssh://git@github.ibm.com/<USERNAME>/terraform-openshift-kubeconfig.git"
    bastion_ip_address      = "${module.infrastructure.bastion_public_ip}"
    bastion_private_ssh_key = "${var.private_ssh_key}"
    master_private_ip       = "${module.infrastructure.master_private_ip}"
    cluster_name            = "${var.hostname_prefix}-${random_id.tag.hex}"
    ssh_username            = "${var.ssh_user}"
}
```

On your `output.tf` file, add the following to expose the config

```terraform
output "kubeconfig" {
    value = "${module.kubeconfig.config}"
}
```

```bash
$ export KUBECONFIG=$(terraform output kubeconfig)
$ oc get nodes
NAME                                      STATUS    ROLES     AGE       VERSION
ocp-ibm-062054dd9a-app-0.ncolon.xyz       Ready     compute   2h        v1.11.0+d4cacc0
ocp-ibm-062054dd9a-infra-0.ncolon.xyz     Ready     infra     2h        v1.11.0+d4cacc0
ocp-ibm-062054dd9a-master-0.ncolon.xyz    Ready     master    2h        v1.11.0+d4cacc0
ocp-ibm-062054dd9a-storage-0.ncolon.xyz   Ready     compute   2h        v1.11.0+d4cacc0
ocp-ibm-062054dd9a-storage-1.ncolon.xyz   Ready     compute   2h        v1.11.0+d4cacc0
ocp-ibm-062054dd9a-storage-2.ncolon.xyz   Ready     compute   2h        v1.11.0+d4cacc0

$ oc get routes -n openshift-console
NAME      HOST/PORT                              PATH      SERVICES   PORT      TERMINATION          WILDCARD
console   console.apps-ibm-96274e13.ncolon.xyz             console    https     reencrypt/Redirect   None
```
