# Reserve a static internal IP for the MongoDB VM
resource "google_compute_address" "mongodb_internal" {
  name         = "mongodb-internal-ip"
  subnetwork   = google_compute_subnetwork.public_subnet.id
  address_type = "INTERNAL"
  address      = "10.3.0.10"
  region       = var.region
}

resource "google_compute_instance" "mongodb" {
  name         = var.vm_name
  machine_type = var.vm_machine_type
  zone         = var.zone

  tags = ["mongodb-server", "ssh"]

  boot_disk {
    initialize_params {
      image = var.vm_image
      size  = var.vm_disk_size
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.public_subnet.id
    network_ip = google_compute_address.mongodb_internal.address

    # Public IP for SSH access
    access_config {}
  }

  service_account {
    email  = google_service_account.mongodb_vm.email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = templatefile("${path.module}/scripts/startup.sh", {
    backup_bucket   = google_storage_bucket.mongodb_backups.name
    admin_secret_id = "mongo_admin_pass"
    app_secret_id   = "mongo_app_pass"
  })

  depends_on = [google_storage_bucket.mongodb_backups]
}
