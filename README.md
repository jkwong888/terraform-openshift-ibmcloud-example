# terraform-openshift-example

Sample terraform project leveraging multiple modules to deploy OpenShift into an user provided infrastructure.

In this example, we'll use IBM Cloud and OpenShift 3.11. `example.tfvars` shows variables that can be passed to the whole project to build an OpenShift environment.


### Step 1:  Build infrastructure

In your terraform `main.tf` file include the [terraform-openshift-ibminfra](https://github.ibm.com/ncolon/terraform-openshift-ibminfra) module

```terraform
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
    bastion_ssh_key_file  = "${var.bastion_ssh_key_file}"
    hourly_billing        = "${var.hourly_billing}"
    os_reference_code     = "${var.os_reference_code}"
    bastion               = "${var.bastion}"
    master                = "${var.master}"
    infra                 = "${var.infra}"
    worker                = "${var.worker}"
    storage               = "${var.storage}"
}
```

Deploy the Infrastructure
```bash
$ terraform apply -target=module.infrastructure
```

### Step 2: Register VMs with RedHat Satelite

In your terraform `main.tf` file include the [terraform-openshift-rhnregister](https://github.ibm.com/ncolon/terraform-openshift-rhnregister) module.  It will pull necessary information from the infrastructure module above.

You need to provide your own RedHat username (`rhn_username`) and password (`rhn_password`), as well as the OpenShift Subscription Pool (`rhn_poolid`) to draw licenses from.

```terraform
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
```

Register your servers with RHN
```bash
$ terraform apply -target=module.rhnregister
```

### Step 3: Register your infrastructure DNS.
We'll use cloudflare for DNS registrar and Letsencrypt for SSL certificates

In your terraform `main.tf` file include the [terraform-openshift-letsencrypt](https://github.ibm.com/ncolon/terraform-openshift-ibminfra) and [terraform-openshift-cloudflare](https://github.ibm.com/ncolon/terraform-openshift-ibminfra) modules. It will pull necessary information from the infrastructure module above.

The cloudflare module currently requires the cloudflare_email and cloudflare_token to be passed thru s variables.  It will be converted to CLOUDFLARE_EMAIL and CLOUDFLARE_TOKEN env variables soon.

```terraform
resource "random_id" "tag" {
    byte_length = 4
}

module "dnscerts" {
    source                  = "git::ssh://git@github.ibm.com/ncolon/terraform-openshift-dnscerts.git"
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
```

Register your servers with DNS
```bash
$ terraform apply -target=module.dnscerts
```

### Step 4:  Ansible Configuration Files
You need to generate an ansible inventory and a hosts file to propagate to your infrastructure for OpenShift deployment.  In your terraform `main.tf` file include the [terraform-openshift-inventory](https://github.ibm.com/ncolon/terraform-openshift-inventory) module. It will pull necessary information from the infrastructure module above.

```terraform
module "inventory" {
    source                  = "git::ssh://git@github.ibm.com/ncolon/terraform-openshift-inventory.git"
    domain                  = "${var.domain}"
    bastion_ip_address      = "${module.infrastructure.bastion_public_ip}"
    bastion_private_ip      = "${module.infrastructure.bastion_private_ip}"
    master_private_ip       = "${module.infrastructure.master_private_ip}"
    infra_private_ip        = "${module.infrastructure.infra_private_ip}"
    app_private_ip          = "${module.infrastructure.app_private_ip}"
    storage_private_ip      = "${module.infrastructure.storage_private_ip}"
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
}
```

The module will place an `inventory.cfg` and `hosts` file under `inventory_repo` in your modules root directory.

Create the inventory files
```bash
$ terraform apply -target=module.inventory
```


### Step 5: Deploy OpenShift
In your terraform `main.tf` file include the [terraform-openshift-deploy](https://github.ibm.com/ncolon/terraform-openshift-deploy) module. It will pull necessary information from the infrastructure module above.

```terraform
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
}
```

Deploy OpenShift
```bash
$ terraform apply -target=module.openshift
```

### Step 6:  Access your OpenShift Cluster
In your terraform `main.tf` file include the [terraform-openshift-kubeconfig](https://github.ibm.com/ncolon/terraform-openshift-kubeconfig) module. It will pull necessary information from the infrastructure module above.

```terraform
module "kubeconfig" {
    source                  = "git::ssh://git@github.ibm.com/ncolon/terraform-openshift-kubeconfig.git"
    bastion_ip_address      = "${module.infrastructure.bastion_public_ip}"
    bastion_private_ssh_key = "${var.private_ssh_key}"
    master_private_ip       = "${module.infrastructure.master_private_ip}"
    cluster_name            = "${var.hostname_prefix}-${random_id.tag.hex}"
}
```

On yout `output.tf` file, add the following to expose the config

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

Credentials for this example are `admin:admin`
