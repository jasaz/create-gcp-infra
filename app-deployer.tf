# RESOURCES that will be created for App Deployment 

# Dedicated service account for app deployment
resource "google_service_account" "gke_deployer" {
  account_id   = "gke-deployer"
  display_name = "GKE Deployer Service Account"
}

# Allow the web-app repo to impersonate gke_deployer SA
resource "google_service_account_iam_member" "deployer_wif" {
  service_account_id = google_service_account.gke_deployer.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${var.wif_pool_id}/attribute.repository/${var.deployer_github_repo}"
}


# Provide the gke_deployer SA access to create GKE clusters Registry
resource "google_project_iam_member" "deployer_container_admin" {
  project = var.project_id
  role    = "roles/container.admin"
  member  = "serviceAccount:${google_service_account.gke_deployer.email}"
}

# # Provide the gke_deployer SA access to push images to Google Artifact Registry
resource "google_project_iam_member" "deployer_ar_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${google_service_account.gke_deployer.email}"
}

