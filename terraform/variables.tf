variable "project_id" {
  type    = string
  default = "doctolib-case-dataops"
}

variable "region" {
  type    = string
  default = "europe-west1"
}

variable "zone" {
  type    = string
  default = "europe-west1-b"
}

variable "fast_api_instance_compute_type" {
  type    = string
  default = "e2-medium"
}

variable "environment" {
  type    = string
  default = "dev"
}