variable "project_id" {
    description = "project id used on this terraform"
    type = string
    default = "spatial-lodge-350205"
}

variable "region" {
    description = "Region used"
    type = string
    default = "us-central1"
}

variable "service_account" {
  type = object({
    email  = string,
    scopes = list(string)
  })
  default = {
    email  = "instance-template@spatial-lodge-350205.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }
}
