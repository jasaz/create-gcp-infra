# Resources used by Terraform

# GCS bucket for MongoDB backups — publicly readable
resource "google_storage_bucket" "mongodb_backups" {
  name                        = "${var.project_id}-mongodb-backups"
  location                    = var.region
  force_destroy               = true

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action { type = "Delete" }
    condition { age = 90 }  # retain backups for 90 days
  }
}

# Make the bucket publicly readable
resource "google_storage_bucket_iam_member" "public_read" {
  bucket = google_storage_bucket.mongodb_backups.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# Create Service account for the MongoDB VM
resource "google_service_account" "mongodb_vm" {
  account_id   = "mongodb-vm-sa"
  display_name = "MongoDB VM Service Account"
}

# Allow the VM SA to write backups to the bucket
resource "google_storage_bucket_iam_member" "vm_backup_write" {
  bucket = google_storage_bucket.mongodb_backups.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.mongodb_vm.email}"
}

# Granting overly excessive permission (Project level access) to create a VM
resource "google_project_iam_member" "vm_sa_instance_admin" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.mongodb_vm.email}"
}
