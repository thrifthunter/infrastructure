module "gce-container" {
    source = "terraform-google-modules/container-vm/google"
    container = {
        image = "gcr.io/spatial-lodge-350205/webapi@sha256:2fefc5a7eedc4b6d66fdece92e3c51f9d751b383f5c2c0a93a96cbc59c454b59"
    }
}

module "mig_template" {
    name_prefix            = "webapi-templates"
    source          = "terraform-google-modules/vm/google//modules/instance_template"
    version         = "~> 7.3"
    machine_type    = "e2-micro"
    network              = "default"
    subnetwork           = "default"
    # access_config = [{
    #     nat_ip       = null
    #     network_tier =  null
    # }]

    service_account      = var.service_account
    source_image_family  = "cos-stable"
    source_image_project = "cos-cloud"
    source_image         = reverse(split("/", module.gce-container.source_image))[0]
    metadata             = {
        "gce-container-declaration" = module.gce-container.metadata_value
    }
    tags = [
        "http-server"
    ]
    labels = {
        "container-vm" = module.gce-container.vm_container_label
    }
    disk_size_gb = 40
}

module "mig" {
    hostname            = "webapi"
    source              = "terraform-google-modules/vm/google//modules/mig"
    version             = "~> 7.3"
    instance_template   = module.mig_template.self_link
    region              = var.region
    network             = "default"
    subnetwork          = "default"
    max_replicas        = 3
    min_replicas        = 2
    autoscaling_enabled = true
    autoscaling_mode    = "ON"
    autoscaling_cpu  = [{
        target = 0.8
    }]
    named_ports = [
        {
            name = "http",
            port = 80
        }
    ]
}

resource "google_compute_health_check" "webapi-hc" {
    name = "webapi-hc"

    timeout_sec         = 1
    check_interval_sec  = 30
    healthy_threshold   = 1
    unhealthy_threshold = 10

    tcp_health_check {
        port = "80"
    }
}

# reserved IP address
resource "google_compute_global_address" "default" {
  name = "webapi-static-ip"
}

# forwarding rule
resource "google_compute_global_forwarding_rule" "default" {
  name                  = "webapi-forwarding-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
  target                = google_compute_target_http_proxy.default.id
  ip_address            = google_compute_global_address.default.id
}

# http proxy
resource "google_compute_target_http_proxy" "default" {
  name     = "webapi-http-proxy"
  url_map  = google_compute_url_map.default.id
}

# url map
resource "google_compute_url_map" "default" {
  name            = "webapi-url-map"
  provider        = google-beta
  default_service = google_compute_backend_service.default.id
}

# health check
resource "google_compute_health_check" "default" {
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

# backend service with custom request and response headers
resource "google_compute_backend_service" "default" {
  name                     = "webapi-backend-service"
  protocol                 = "HTTP"
  port_name                = "http"
  load_balancing_scheme    = "EXTERNAL"
  timeout_sec              = 10
  enable_cdn               = false
  health_checks            = [google_compute_health_check.default.id]
  backend {
    group           = module.mig.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}
