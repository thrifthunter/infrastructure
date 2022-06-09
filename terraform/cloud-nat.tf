resource "google_compute_router" "webapi_router" {
  name    = "webapi-router"
  region  = var.region
  network = var.network
}

resource "google_compute_router_nat" "webapi_nat" {
  name                               = "webapi-nat"
  router                             = google_compute_router.webapi_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}