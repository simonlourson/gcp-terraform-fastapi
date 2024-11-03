resource "google_storage_bucket" "doctolib_bucket" {
  name          = "doctolib-bucket"
  location      = "EU"
  force_destroy = true
}

resource "google_storage_bucket_object" "python_script_api" {
  name   = "main.py"
  bucket = google_storage_bucket.doctolib_bucket.name
  source = "${path.module}/../src/main.py"
}

resource "google_storage_bucket_object" "populate_movie_db" {
  name   = "movie.sql"
  bucket = google_storage_bucket.doctolib_bucket.name
  source = "${path.module}/../src/movie.sql"
}

resource "google_storage_bucket_object" "populate_movie_db_python_script" {
  name   = "insert_sql_movies.py"
  bucket = google_storage_bucket.doctolib_bucket.name
  source = "${path.module}/../src/insert_sql_movies.py"
}