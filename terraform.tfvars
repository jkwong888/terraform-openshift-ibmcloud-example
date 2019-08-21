ibm_sl_api_key = "<SL_API_KEY>
ibm_sl_username = "<SL_USERNAME>"
datacenter = "wdc04"
domain = "example.com"
hostname_prefix = "ocp-ibm"

openshift_vm_admin_user="root"
private_ssh_key = "~/.ssh/openshift_rsa"
public_ssh_key = "~/.ssh/openshift_rsa.pub"

vlan_count = 1
private_vlanid = "2659689"
public_vlanid = "2659687"

hourly_billing = "true"

cloudflare_email = "<CLOUDFLARE_EMAIL>"
cloudflare_token = "<CLOUDFLARE_TOKEN>"
master_cname = "master-ibm"
app_cname = "apps-ibm"

letsencrypt = true
letsencrypt_email = "<LETSENCRYPT_EMAIL>"
letsencrypt_dns_provider = "cloudflare"
letsencrypt_api_endpoint="https://acme-v02.api.letsencrypt.org/directory"

rhn_username = "<RHN_USERNAME>"
rhn_password = "<RHN_PASSWORD>"
rhn_poolid   = "<RHN_POOLID>

ose_deployment_type = "openshift-enterprise"

os_reference_code = "REDHAT_7_64"

ssh_user = "root"
dnscerts = true
