
resource "google_compute_health_check" "webapi_hc" {
    name = "webapi-hc"

    timeout_sec         = 1
    check_interval_sec  = 30
    healthy_threshold   = 1
    unhealthy_threshold = 10

    tcp_health_check {
        port = "80"
    }
}

resource "google_compute_global_address" "webapi_static_ip" {
  name = "webapi-static-ip"
}


resource "google_compute_global_forwarding_rule" "webapi_forwarding_rule" {
  name                  = "webapi-forwarding-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
  target                = google_compute_target_http_proxy.webapi_http_proxy.id
  ip_address            = google_compute_global_address.webapi_static_ip.id
}

resource "google_compute_health_check" "webapi_lb_hc" {
  name        = "webapi-lb-hc"
  description = "Health check via tcp"

  timeout_sec         = 15
  check_interval_sec  = 15
  healthy_threshold   = 1
  unhealthy_threshold = 10

  tcp_health_check {
    port_name   = "http"
    port        = 80
  }
}


resource "google_compute_backend_service" "webapi_backend" {
  name                     = "webapi-backend-service"
  protocol                 = "HTTP"
  port_name                = "http"
  load_balancing_scheme    = "EXTERNAL"
  timeout_sec              = 10
  enable_cdn               = false
  health_checks            = [google_compute_health_check.webapi_lb_hc.id]
  backend {
    group           = module.mig.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

resource "google_compute_url_map" "webapi_url_map" {
  name            = "webapi-url-map"
  provider        = google-beta
  default_service = google_compute_backend_service.webapi_backend.id
}

resource "google_compute_target_http_proxy" "webapi_http_proxy" {
  name     = "webapi-http-proxy"
  url_map  = google_compute_url_map.webapi_url_map.id
}
