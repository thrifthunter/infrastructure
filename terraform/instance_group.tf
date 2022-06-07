module "gce-container" {
    source = "terraform-google-modules/container-vm/google"
    container = {
        image = var.image
    }
}

module "mig_template" {
    name_prefix         = "webapi-templates"
    source              = "terraform-google-modules/vm/google//modules/instance_template"
    version             = "~> 7.3"
    machine_type        = "e2-micro"
    network             = var.network
    subnetwork          = var.subnet

    service_account      = var.service_account
    source_image_family  = "cos-stable"
    source_image_project = "cos-cloud"
    source_image         = reverse(split("/", module.gce-container.source_image))[0]
    metadata             = {
        "gce-container-declaration" = module.gce-container.metadata_value
        "google-logging-enabled"    = true
    }
    tags = [
        "http-server"
        "thrit-api"
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
    network             = var.network
    subnetwork          = var.subnet
    max_replicas        = 5
    min_replicas        = 1
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
