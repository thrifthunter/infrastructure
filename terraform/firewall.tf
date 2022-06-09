resource "google_compute_firewall" "allow_internal_ssh" {
  project = var.project_id
  name    = "allow-internal-ssh"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
  target_tags = ["thrift-api"]
}

resource "google_compute_firewall" "allow_health_checks" {
  project = var.project_id
  name    = "allow-health-checks"
  network = var.network

  allow {
    protocol = "tcp"
  }
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags = ["thrift-api"]
}

