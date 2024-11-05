resource "google_compute_firewall" "allow_http_https" {
  name    = "allow-http-https"
  network = google_compute_network.terraform_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["http-server", "https-server"]
}

resource "google_compute_firewall" "allow_fastapi" {
  name    = "allow-fastapi"
  network = google_compute_network.terraform_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["8000"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["fastapi-server"]
}

resource "google_compute_firewall" "iap_allow" {
  name      = "allow-iap"
  network   = google_compute_network.terraform_network.self_link
  direction = "INGRESS"
  disabled  = false
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["allow-iap"]
}


resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.terraform_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-ssh"]
}

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
    startup-script = file("${path.module}/../src/startup_fastapi.sh") # Read the script from a file
  }

  service_account {
    email  = google_service_account.cloud_sql_admin.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"] # Change scopes if needed
  }

  tags = ["http-server", "https-server", "fastapi-server", "allow-iap"]


  depends_on = [
    google_compute_router_nat.nat,
    google_project_service.iam,
    google_sql_user.db_user,
    google_sql_database.movie_database
  ]
}

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