terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "compute.googleapis.com",
    "sql-component.googleapis.com",
    "sqladmin.googleapis.com",
    "pubsub.googleapis.com",
    "cloudfunctions.googleapis.com",
    "storage-api.googleapis.com",
    "iam.googleapis.com"
  ])
  
  project = var.project_id
  service = each.value
  
  disable_dependent_services = true
}

# Project metadata with OS Login disabled (vulnerability)
resource "google_compute_project_metadata" "default" {
  metadata = {
    enable-oslogin = false  # VULNERABILITY: OS Login disabled
  }
  
  depends_on = [google_project_service.required_apis]
}

# VPC Network
resource "google_compute_network" "mes_vpc" {
  name                    = "smart-manufacturing-execution-system-mes-network-main"
  auto_create_subnetworks = false
  
  depends_on = [google_project_service.required_apis]
}

# Public subnet for load balancer
resource "google_compute_subnetwork" "public_subnet" {
  name          = "smart-manufacturing-execution-system-mes-subnet-public"
  ip_cidr_range = var.public_subnet_cidr
  region        = var.region
  network       = google_compute_network.mes_vpc.id
}

# Private subnet for application servers
resource "google_compute_subnetwork" "private_subnet" {
  name          = "smart-manufacturing-execution-system-mes-subnet-private"
  ip_cidr_range = var.private_subnet_cidr
  region        = var.region
  network       = google_compute_network.mes_vpc.id
  
  private_ip_google_access = true
}

# Data subnet for database
resource "google_compute_subnetwork" "data_subnet" {
  name          = "smart-manufacturing-execution-system-mes-subnet-data"
  ip_cidr_range = var.data_subnet_cidr
  region        = var.region
  network       = google_compute_network.mes_vpc.id
  
  private_ip_google_access = true
}

# Firewall rule allowing SSH from anywhere (vulnerability)
resource "google_compute_firewall" "allow_ssh_public" {
  name    = "smart-manufacturing-execution-system-mes-firewall-ssh"
  network = google_compute_network.mes_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]  # VULNERABILITY: SSH access from anywhere
  target_tags   = ["mes-application"]
}

# Firewall rule for HTTP/HTTPS
resource "google_compute_firewall" "allow_http_https" {
  name    = "smart-manufacturing-execution-system-mes-firewall-web"
  network = google_compute_network.mes_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["mes-application"]
}

# Sensor Data Ingestion - Pub/Sub Topic
resource "google_pubsub_topic" "sensor_data_ingestion" {
  name = "smart-manufacturing-execution-system-mes-topic-sensor-data"
  
  labels = {
    environment = var.environment
    component   = "sensor-data-ingestion"
  }
  
  depends_on = [google_project_service.required_apis]
}

# Quality Data Topic
resource "google_pubsub_topic" "quality_data" {
  name = "smart-manufacturing-execution-system-mes-topic-quality-data"
  
  labels = {
    environment = var.environment
    component   = "quality-data"
  }
  
  depends_on = [google_project_service.required_apis]
}

# Pub/Sub Subscriptions
resource "google_pubsub_subscription" "sensor_data_subscription" {
  name  = "smart-manufacturing-execution-system-mes-subscription-sensor"
  topic = google_pubsub_topic.sensor_data_ingestion.name
  
  ack_deadline_seconds = 20
}

# Time Series Storage - Cloud Storage Bucket
resource "google_storage_bucket" "time_series_storage" {
  name     = "smart-manufacturing-execution-system-mes-storage-${random_id.bucket_suffix.hex}"
  location = var.region
  
  labels = {
    environment = var.environment
    component   = "time-series-storage"
  }
  
  # Missing encryption configuration (vulnerability implied)
}

# Archive storage bucket
resource "google_storage_bucket" "archive_storage" {
  name     = "smart-manufacturing-execution-system-mes-archive-${random_id.bucket_suffix.hex}"
  location = var.region
  
  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }
  
  labels = {
    environment = var.environment
    component   = "archive-storage"
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Production Database - Cloud SQL
resource "google_sql_database_instance" "production_database" {
  name             = "smart-manufacturing-execution-system-mes-db-${random_id.db_suffix.hex}"
  database_version = "POSTGRES_13"
  region           = var.region
  
  settings {
    tier = "db-custom-2-4096"
    
    ip_configuration {
      ipv4_enabled = true
      authorized_networks {
        value = "0.0.0.0/0"  # VULNERABILITY: Public access allowed
        name  = "internet"
      }
      authorized_networks {
        value = var.private_subnet_cidr
        name  = "private-subnet"
      }
    }
    
    backup_configuration {
      enabled    = true
      start_time = "03:00"
    }
    
    # VULNERABILITY: Logging disabled
    database_flags {
      name  = "log_disconnections"
      value = "off"
    }
    
    database_flags {
      name  = "log_checkpoints"
      value = "off"
    }
  }
  
  deletion_protection = false
  
  depends_on = [google_project_service.required_apis]
}

resource "random_id" "db_suffix" {
  byte_length = 4
}

# Database
resource "google_sql_database" "mes_database" {
  name     = "manufacturing_execution_system"
  instance = google_sql_database_instance.production_database.name
}

# Database user
resource "google_sql_user" "mes_user" {
  name     = "mes_admin"
  instance = google_sql_database_instance.production_database.name
  password = var.db_password
}

# Service Account for Cloud Functions
resource "google_service_account" "function_service_account" {
  account_id   = "mes-functions-sa"
  display_name = "MES Cloud Functions Service Account"
}

# IAM binding for Cloud Functions
resource "google_project_iam_member" "function_permissions" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.function_service_account.email}"
}

# Data Processing Pipeline - Cloud Function
resource "google_cloudfunctions_function" "data_processing_pipeline" {
  name        = "smart-manufacturing-execution-system-mes-function-data-processing"
  description = "Processes sensor data and calculates OEE metrics"
  runtime     = "python39"
  
  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.time_series_storage.name
  source_archive_object = "function-source.zip"
  trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.sensor_data_ingestion.name
  }
  timeout               = 60
  entry_point          = "process_sensor_data"
  service_account_email = google_service_account.function_service_account.email
  
  environment_variables = {
    DB_HOST     = google_sql_database_instance.production_database.connection_name
    DB_NAME     = google_sql_database.mes_database.name
    DB_USER     = google_sql_user.mes_user.name
    DB_PASSWORD = var.db_password
  }
  
  depends_on = [google_project_service.required_apis]
}

# Reporting Service - Cloud Function
resource "google_cloudfunctions_function" "reporting_service" {
  name        = "smart-manufacturing-execution-system-mes-function-reporting"
  description = "Generates production reports and compliance documents"
  runtime     = "python39"
  
  available_memory_mb   = 512
  source_archive_bucket = google_storage_bucket.time_series_storage.name
  source_archive_object = "reporting-source.zip"
  trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = "projects/${var.project_id}/topics/report-trigger"
  }
  timeout               = 300
  entry_point          = "generate_reports"
  service_account_email = google_service_account.function_service_account.email
  
  environment_variables = {
    DB_HOST        = google_sql_database_instance.production_database.connection_name
    STORAGE_BUCKET = google_storage_bucket.time_series_storage.name
  }
  
  depends_on = [google_project_service.required_apis]
}

# MES Application - Compute Instance
resource "google_compute_instance" "mes_application" {
  name         = "smart-manufacturing-execution-system-mes-instance-app"
  machine_type = "e2-standard-4"
  zone         = var.zone
  
  tags = ["mes-application"]
  
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 50
    }
    # VULNERABILITY: Plaintext encryption key
    disk_encryption_key_raw = "b2ggbm8gdGhpcyBpcyBiYWQ="
  }
  
  network_interface {
    network    = google_compute_network.mes_vpc.name
    subnetwork = google_compute_subnetwork.private_subnet.name
    
    access_config {
      // Ephemeral public IP
    }
  }
  
  # VULNERABILITY: IP forwarding enabled
  can_ip_forward = true
  
  metadata_startup_script = file("${path.module}/startup-script.sh")
  
  service_account {
    email  = google_service_account.function_service_account.email
    scopes = ["cloud-platform"]
  }
  
  labels = {
    environment = var.environment
    component   = "mes-application"
  }
  
  depends_on = [google_project_service.required_apis]
}

# Load Balancer Instance Group
resource "google_compute_instance_group" "mes_instance_group" {
  name        = "smart-manufacturing-execution-system-mes-group-app"
  description = "MES application instance group"
  zone        = var.zone
  
  instances = [
    google_compute_instance.mes_application.id
  ]
  
  named_port {
    name = "http"
    port = "8080"
  }
}