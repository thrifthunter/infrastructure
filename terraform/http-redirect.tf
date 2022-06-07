resource "google_compute_url_map" "http_redirect" {
  name = "http-redirect"

  default_url_redirect {
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"  
    strip_query            = false
    https_redirect         = true  
  }
}

resource "google_compute_target_http_proxy" "http_redirect" {
  name    = "http-redirect"
  url_map = google_compute_url_map.http_redirect.self_link
}

resource "google_compute_global_forwarding_rule" "http_redirect" {
  name       = "http-redirect"
  target     = google_compute_target_http_proxy.http_redirect.self_link
  ip_address = google_compute_global_address.webapi_static_ip.id
  port_range = "80"
}