# Artifact Registry for Docker images
resource "google_artifact_registry_repository" "docker" {
  location      = var.region
  repository_id = var.gar_repository_id
  format        = "DOCKER"
  description   = "Docker repository for web-app images"
}
