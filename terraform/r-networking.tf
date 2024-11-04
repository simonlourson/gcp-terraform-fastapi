resource "google_compute_network" "terraform_network" {
  name                    = "${var.project_id}-network"
  auto_create_subnetworks = false
  depends_on              = [google_project_service.computeapi]
}

resource "google_compute_subnetwork" "private" {
  name                     = "${var.project_id}-private-subnet"
  region                   = var.region
  ip_cidr_range            = "10.0.0.0/24"
  stack_type               = "IPV4_ONLY"
  network                  = google_compute_network.terraform_network.id
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "public" {
  name          = "${var.project_id}-public-subnet"
  region        = var.region
  ip_cidr_range = "10.0.64.0/24"
  stack_type    = "IPV4_ONLY"
  network       = google_compute_network.terraform_network.id
}

resource "google_compute_route" "default_to_internet" {
  name             = "default-internet-gateway"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.terraform_network.id
  next_hop_gateway = "default-internet-gateway"
  priority         = 1000
  description      = "Default route to the Internet."
}

resource "google_compute_router" "router" {
  name    = "router"
  region  = var.region
  network = google_compute_network.terraform_network.id
}

resource "google_compute_address" "nat" {
  name         = "nat"
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"

  depends_on = [google_project_service.computeapi]
}

resource "google_compute_router_nat" "nat" {
  name   = "nat"
  router = google_compute_router.router.name
  region = var.region

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  nat_ip_allocate_option             = "MANUAL_ONLY"

  subnetwork {
    name                    = google_compute_subnetwork.private.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  nat_ips = [google_compute_address.nat.self_link]
}