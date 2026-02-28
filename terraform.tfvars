# project_id and wif_pool_id are set via TF_VAR_ env vars (from GitHub secrets)
# Do NOT set them here — terraform.tfvars overrides env vars!
region                        = "australia-southeast1"
zone                          = "australia-southeast1-a"
vpc_name                      = "wiz-vpc"
private_subnet                = "wiz-private-subnet"
public_subnet                 = "wiz-public-subnet"
cluster_name                  = "wiz-autopilot-cluster"
master_authorized_cidr_blocks = "0.0.0.0/0"
vm_name                       = "wiz-mongodb-server"
vm_image                      = "ubuntu-os-cloud/ubuntu-2204-lts"
vm_machine_type               = "e2-small"
vm_disk_size                  = 20
gar_repository_id             = "wiz-gar-repo"
deployer_github_repo          = "jasaz/deploy-webapp"