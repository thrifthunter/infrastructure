module "container-vm" {
    source = "terraform-google-modules/container-vm/google"
    container = {
        image = var.docker_image
    }
}

module "vm_instance_template" {
    name_prefix         = "webapi-templates"
    source              = "terraform-google-modules/vm/google//modules/instance_template"
    version             = "~> 7.3"
    machine_type        = "e2-micro"
    network             = var.network
    subnetwork          = var.subnet

    service_account      = var.service_account
    source_image_family  = "cos-stable"
    source_image_project = "cos-cloud"
    source_image         = reverse(split("/", module.container-vm.source_image))[0]
    metadata             = {
        "gce-container-declaration" = module.container-vm.metadata_value
        "google-logging-enabled"    = true
    }
    tags = [
        "http-server", 
        "thrift-api"
    ]
    labels = {
        "container-vm" = module.container-vm.vm_container_label
    }
    disk_size_gb = 40
}

module "vm_mig" {
    hostname            = "webapi"
    source              = "terraform-google-modules/vm/google//modules/mig"
    version             = "~> 7.3"
    instance_template   = module.vm_instance_template.self_link
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
