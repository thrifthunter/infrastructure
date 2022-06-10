resource "google_compute_address" "mysql_private_ip" {
  name         = "mysql-ip"
  subnetwork   = var.subnet
  address_type = "INTERNAL"
  address      = "10.240.0.36"
  region       = var.region
}

resource "google_compute_disk" "mysql_disk" {
  name  = "mysql-data-disk"
  type  = "pd-balanced"
  zone  = var.zone
  size  = 100
  labels = {
    environment = "dev"
  }
  physical_block_size_bytes = 4096
}

resource "google_compute_instance" "mysql_instance" {
  name          = "mysql-instance"
  machine_type  = "e2-micro"
  zone          = var.zone
  tags          = ["http-server", "mysql-server"]

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2004-focal-v20220609"
      size  = 12
      type  = "pd-balanced"
    }
  }

  // Local SSD disk
  attached_disk {
    source = google_compute_disk.mysql_disk.self_link
  }

  network_interface {
    subnetwork     = var.subnet
    network_ip     = google_compute_address.mysql_private_ip.self_link
  }

  metadata = {
    startup-script-url = "https://raw.githubusercontent.com/thrifthunter/infrastructure/main/startup-script/mysql-server.sh"
  }

}