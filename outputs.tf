output "cluster_name" {
  description = "The name of the GKE cluster"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "The GKE cluster endpoint"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "mongodb_vm_ip" {
  description = "The external IP of the MongoDB VM"
  value       = google_compute_instance.mongodb.network_interface[0].access_config[0].nat_ip
}

output "mongodb_internal_ip" {
  description = "The internal IP of the MongoDB VM (used by GKE pods)"
  value       = google_compute_instance.mongodb.network_interface[0].network_ip
}

output "mongodb_backup_bucket" {
  description = "The GCS bucket for MongoDB backups"
  value       = google_storage_bucket.mongodb_backups.name
}

output "artifact_registry_url" {
  description = "The Artifact Registry Docker repository URL"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.docker.repository_id}"
}
/*
output "gke_deployer_sa_email" {
  description = "The email of the GKE deployer service account"
  value       = google_service_account.gke_deployer.email
}
*/
