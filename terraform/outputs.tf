output "fast_api_instance_external_ip" {
  value       = google_compute_instance.fast_api_instance_private.network_interface[0].access_config[0].nat_ip
  description = "The external IP address of the FastAPI instance to access from browser."
}

output "project_resource_name" {
  value = {
    sql_instance_name      = google_sql_database_instance.sql_instance.name
    bucket_data_name       = google_storage_bucket.bucket_data.name
    fast_api_instance_name = google_compute_instance.fast_api_instance_private.name
    bastion_instance_name  = google_compute_instance.bastion_instance.name
  }

}