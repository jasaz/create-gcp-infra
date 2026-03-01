resource "google_container_cluster" "primary" {
  name                = var.cluster_name
  location            = var.region

  enable_autopilot    = true

  network             = google_compute_network.vpc.id
  subnetwork          = google_compute_subnetwork.private-subnet.id

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  private_cluster_config {
    # Ensures worker nodes are private
    enable_private_nodes    = true
    # Ensures GKE API server is reachable by GH runners hosted on public Internet
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  master_authorized_networks_config {
    cidr_blocks {
      cidr_block   = var.master_authorized_cidr_blocks
      display_name = "Authorized Network"
    }
  }

  deletion_protection = false
}
