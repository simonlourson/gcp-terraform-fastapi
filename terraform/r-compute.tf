# Private VM hosting fastAPI
resource "google_compute_instance" "fast_api_instance_private" {
  name                      = "${var.project_id}-fast-api-instance"
  zone                      = var.zone
  machine_type              = var.fast_api_instance_compute_type
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }


  network_interface {
    network    = google_compute_network.terraform_network.self_link
    subnetwork = google_compute_subnetwork.private.self_link
    network_ip = local.fast_api_compute_private_cidr
    # access_config {}
  }

  metadata = {
    startup-script = file("${path.module}/../src/startup_fastapi.sh") 
  }

  service_account {
    email  = google_service_account.fast_api_compute_sa.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"] 
  }

  tags = ["http-server", "https-server", "fastapi-server", "allow-iap"]


  depends_on = [
    google_compute_router_nat.nat,
    google_project_service.iam,
    google_sql_user.db_user,
    google_sql_database.movie_database
  ]
}


# Private VM bastion
resource "google_compute_instance" "bastion_instance" {
  name         = "${var.project_id}-bastion-host"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.public.self_link
    access_config {}
  }

  metadata = {
    startup-script = file("${path.module}/../src/startup_bastion.sh")
  }

  tags       = ["bastion-host", "http-server", "https-server", "allow-ssh"]
  depends_on = [google_compute_instance.fast_api_instance_private]
}