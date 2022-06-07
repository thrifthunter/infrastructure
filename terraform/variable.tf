variable "project_id" {
  description = "project id used on this terraform"
  type = string
  default = "sunlit-flag-351808"
}

variable "docker_image"{
  description = "Docker image from container registry"
  type = string
  default = "asia.gcr.io/sunlit-flag-351808/webapi:latest"
}

variable "region" {
  description = "Region used"
  type = string
  default = "asia-southeast2"
}

variable "network"{
  description = "network"
  type = string
  default = "webapi-net"
}

variable "subnet"{
  description = "subnetwork"
  type = string
  default = "webapi-subnet"
}


variable "service_account" {
  type = object({
    email  = string,
    scopes = list(string)
  })
  default = {
    email  = "terraform@sunlit-flag-351808.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }
}
