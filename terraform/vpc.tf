resource "google_compute_network" "webapi_network" {
  name                    = var.network
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "webapi_subnet" {
  name          = var.subnet
  ip_cidr_range = "10.240.0.0/20"
  region        = var.region
  network       = var.network
}
