variable "project_id" {
  type = string
  # default = "gpcfastapi-dev-europe-west1"
}

variable "region" {
  type    = string
  default = "europe-west1"
}

variable "zone" {
  type    = string
  default = "europe-west1-b"
}

variable "tfstate_bucket_name" {
  type    = string
  default = "gcpfastapi-dev-europe-west1-terraform"
}

variable "fast_api_instance_compute_type" {
  type    = string
  default = "e2-medium"
}