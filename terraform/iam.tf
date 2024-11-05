resource "google_service_account" "admin_api" {
  account_id   = "admin-api"
  display_name = "API Administrators"
  depends_on = [
    google_project_service.iam
  ]
}

resource "google_service_account" "dev_api" {
  account_id   = "dev-api"
  display_name = "API Developers"
  depends_on = [
    google_project_service.iam
  ]
}

resource "google_service_account" "operator_api" {
  account_id   = "operator-api"
  display_name = "API Operators"
  depends_on = [
    google_project_service.iam
  ]
}

resource "google_service_account" "auditor_api" {
  account_id   = "auditor-api"
  display_name = "Security Auditors"
  depends_on = [
    google_project_service.iam
  ]
}

# API Administrators
resource "google_project_iam_member" "admin_api_roles" {
  project = var.project_id
  role    = "roles/compute.admin"
  member  = "serviceAccount:${google_service_account.admin_api.email}"
  depends_on = [
    google_project_service.iam
  ]
}

resource "google_project_iam_member" "admin_api_sql" {
  project = var.project_id
  role    = "roles/cloudsql.admin"
  member  = "serviceAccount:${google_service_account.admin_api.email}"
  depends_on = [
    google_project_service.iam
  ]
}

resource "google_project_iam_member" "admin_api_storage" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.admin_api.email}"
}

# API Developers
resource "google_project_iam_member" "dev_api_compute" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.dev_api.email}"
}

resource "google_project_iam_member" "dev_api_sql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.dev_api.email}"
}

# API Operators
resource "google_project_iam_member" "operator_api_viewer" {
  project = var.project_id
  role    = "roles/viewer"
  member  = "serviceAccount:${google_service_account.operator_api.email}"
}

# Security Auditors
resource "google_project_iam_member" "auditor_api_security" {
  project = var.project_id
  role    = "roles/iam.securityReviewer"
  member  = "serviceAccount:${google_service_account.auditor_api.email}"
}
