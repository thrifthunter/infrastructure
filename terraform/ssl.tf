resource "google_compute_managed_ssl_certificate" "webapi_ssl" {
  name = "webapi-cert"

  managed {
    domains = ["thrifthunter.csproject.org"]
  }
}

resource "google_compute_target_https_proxy" "webapi_proxy" {
  name             = "webapi-proxy"
  url_map          = google_compute_url_map.webapi_url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.webapi_ssl.id]
}