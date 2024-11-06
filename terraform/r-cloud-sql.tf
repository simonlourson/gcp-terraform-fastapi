resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  network       = google_compute_network.terraform_network.id
}

resource "google_service_networking_connection" "cloud_sql_private_connection" {
  service                 = "servicenetworking.googleapis.com"
  network                 = google_compute_network.terraform_network.id
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
  provider                = google-beta
  depends_on              = [google_compute_subnetwork.private]
}

resource "random_password" "db_password" {
  length  = 16
  special = true
}

# Create a Secret in Secret Manager
resource "google_secret_manager_secret" "db_password_secret" {
  secret_id = "cloudsql-db-password"
  replication {
    auto {}
  }
  depends_on = [
    google_project_service.secretmanager
  ]
}

# Add the password to the Secret Manager secret as a version
resource "google_secret_manager_secret_version" "db_password_secret_version" {
  secret      = google_secret_manager_secret.db_password_secret.id
  secret_data = random_password.db_password.result
}


resource "google_sql_database_instance" "sql_instance" {
  name             = "${var.project_id}-cloud-sql"
  database_version = "MYSQL_5_7"
  region           = var.region

  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled                                  = false
      private_network                               = google_compute_network.terraform_network.self_link
      enable_private_path_for_google_cloud_services = true
    }
  }
  deletion_protection = false
  depends_on = [
    google_project_service.servicenetworking,
    google_project_service.sqladmin,
    google_service_networking_connection.cloud_sql_private_connection,
  ]
}

# Set the database user with the generated password
resource "google_sql_user" "db_user" {
  instance = google_sql_database_instance.sql_instance.name
  name     = "${var.project_id}-sq"
  password = random_password.db_password.result
  host     = "%"
}

resource "google_sql_database" "movie_database" {
  name     = "movie_db"
  instance = google_sql_database_instance.sql_instance.name
}