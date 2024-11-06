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