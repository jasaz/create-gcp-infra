# Allow SSH from the public internet
resource "google_compute_firewall" "allow_ssh" {
  name    = "${var.vm_name}-allow-ssh"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}

# Allow MongoDB access from GKE pod network only
resource "google_compute_firewall" "allow_mongodb" {
  name    = "${var.vm_name}-allow-mongodb"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["27017"]
  }

  # GKE pod secondary range
  source_ranges = ["10.1.0.0/16"]
  target_tags   = ["mongodb-server"]
}
