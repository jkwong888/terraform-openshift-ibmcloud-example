# #################################################
# # Output Bastion Node
# #################################################
#
# output "domain" {
#   value = "${module.infrastructure.domain}"
# }
 output "bastion_public_ip" {
   value = "${module.infrastructure.bastion_public_ip}"
 }
#
# output "bastion_private_ip" {
#   value = "${module.infrastructure.bastion_private_ip}"
# }
#
 output "bastion_hostname" {
   value = "${module.infrastructure.bastion_hostname}"
 }
#
#
# #################################################
# # Output Master Node
# #################################################
# output "master_private_ip" {
#   value = "${module.infrastructure.master_private_ip}"
# }
#
# output "master_hostname" {
#   value = "${module.infrastructure.master_hostname}"
# }
#
# output "master_public_ip" {
#   value = "${module.infrastructure.master_public_ip}"
# }
#
#
# #################################################
# # Output Infra Node
# #################################################
# output "infra_private_ip" {
#   value = "${module.infrastructure.infra_private_ip}"
# }
#
# output "infra_hostname" {
#   value = "${module.infrastructure.infra_hostname}"
# }
#
# output "infra_public_ip" {
#   value = "${module.infrastructure.infra_public_ip}"
# }
#
#
# #################################################
# # Output App Node
# #################################################
# output "app_private_ip" {
#   value = "${module.infrastructure.app_private_ip}"
# }
#
# output "app_hostname" {
#   value = "${module.infrastructure.app_hostname}"
# }
#
# output "app_public_ip" {
#   value = "${module.infrastructure.app_public_ip}"
# }
#
#
# #################################################
# # Output Storage Node
# #################################################
# output "storage_private_ip" {
#   value = "${module.infrastructure.storage_private_ip}"
# }
#
# output "storage_hostname" {
#   value = "${module.infrastructure.storage_hostname}"
# }
#
# output "storage_public_ip" {
#   value = "${module.infrastructure.storage_public_ip}"
# }

#################################################
# Output OpenShift
#################################################
output "kubeconfig" {
    value = "${module.kubeconfig.config}"
}
