# -------------------------------------------------------
# Bootstrap resources (APIs & IAM roles) are managed MANUALLY
# outside of Terraform, since the GitHub Actions service
# account does not have admin-level permissions to manage them.
#
# The following must be configured manually via gcloud:
#
# APIs enabled:
#   - iamcredentials.googleapis.com
#   - cloudresourcemanager.googleapis.com
#   - compute.googleapis.com
#   - container.googleapis.com
#   - artifactregistry.googleapis.com
#
# IAM roles granted to the service account:
#   - roles/container.admin
#   - roles/compute.networkAdmin
#   - roles/compute.securityAdmin      (for firewall rules)
#   - roles/compute.instanceAdmin.v1   (for VM creation)
#   - roles/iam.serviceAccountAdmin    (for creating SAs)
#   - roles/storage.admin
#   - roles/iam.serviceAccountUser
#   - roles/resourcemanager.projectIamAdmin  (for binding IAM roles at project level)
#   - roles/artifactregistry.admin
# -------------------------------------------------------
