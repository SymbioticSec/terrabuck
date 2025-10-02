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

# VPC Network
resource "google_compute_network" "digital_library_vpc" {
  name                    = "digital-library-content-management-platform-vpc-main"
  auto_create_subnetworks = false
  description             = "VPC for digital library platform"
}

# Public Subnet
resource "google_compute_subnetwork" "public_subnet" {
  name          = "digital-library-content-management-platform-subnet-public"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.digital_library_vpc.id
  description   = "Public subnet for load balancers and external access"
}

# Private Subnet
resource "google_compute_subnetwork" "private_subnet" {
  name          = "digital-library-content-management-platform-subnet-private"
  ip_cidr_range = "10.0.2.0/24"
  region        = var.region
  network       = google_compute_network.digital_library_vpc.id
  description   = "Private subnet for Cloud Run services"
}

# Data Subnet
resource "google_compute_subnetwork" "data_subnet" {
  name          = "digital-library-content-management-platform-subnet-data"
  ip_cidr_range = "10.0.3.0/24"
  region        = var.region
  network       = google_compute_network.digital_library_vpc.id
  description   = "Data subnet for databases"
}

# Content Storage Bucket
resource "google_storage_bucket" "content_storage" {
  name          = "digital-library-content-management-platform-storage-content-${random_id.bucket_suffix.hex}"
  location      = var.region
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }

  versioning {
    enabled = true
  }
}

# Usage Logs Storage Bucket
resource "google_storage_bucket" "usage_logs" {
  name          = "digital-library-content-management-platform-storage-logs-${random_id.bucket_suffix.hex}"
  location      = var.region
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 2555
    }
    action {
      type = "Delete"
    }
  }
}

# Random ID for bucket naming
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# User Database Instance
resource "google_sql_database_instance" "user_database" {
  name             = "digital-library-content-management-platform-db-users"
  database_version = "POSTGRES_14"
  region           = var.region
  deletion_protection = false

  settings {
    tier = "db-f1-micro"
    
    backup_configuration {
      enabled = false  # VULNERABILITY: Backup disabled
    }

    ip_configuration {
      ipv4_enabled    = true
      require_ssl     = false  # VULNERABILITY: SSL not required
      authorized_networks {
        value = "0.0.0.0/0"
        name  = "all"
      }
    }

    database_flags {
      name  = "log_min_messages"
      value = "PANIC"  # VULNERABILITY: Insufficient error logging
    }
  }
}

# Metadata Database Instance
resource "google_sql_database_instance" "metadata_database" {
  name             = "digital-library-content-management-platform-db-metadata"
  database_version = "POSTGRES_14"
  region           = var.region
  deletion_protection = false

  settings {
    tier = "db-f1-micro"
    
    backup_configuration {
      enabled = false  # VULNERABILITY: Backup disabled
    }

    ip_configuration {
      ipv4_enabled    = true
      require_ssl     = false  # VULNERABILITY: SSL not required
    }

    database_flags {
      name  = "log_lock_waits"
      value = "off"  # VULNERABILITY: Lock wait logging disabled
    }
  }
}

# User Database
resource "google_sql_database" "users_db" {
  name     = "users"
  instance = google_sql_database_instance.user_database.name
}

# Metadata Database
resource "google_sql_database" "metadata_db" {
  name     = "metadata"
  instance = google_sql_database_instance.metadata_database.name
}

# SSL Policy with weak TLS
resource "google_compute_ssl_policy" "api_ssl_policy" {
  name            = "digital-library-content-management-platform-ssl-policy"
  profile         = "MODERN"
  min_tls_version = "TLS_1_1"  # VULNERABILITY: Weak TLS version
}

# Service Account for API Gateway
resource "google_service_account" "api_gateway_sa" {
  account_id   = "digital-library-api-gateway"
  display_name = "Digital Library API Gateway Service Account"
  description  = "Service account for API Gateway Cloud Run service"
}

# Service Account for Search Service
resource "google_service_account" "search_service_sa" {
  account_id   = "digital-library-search"
  display_name = "Digital Library Search Service Account"
  description  = "Service account for Search Cloud Run service"
}

# Service Account for Analytics Processor
resource "google_service_account" "analytics_processor_sa" {
  account_id   = "digital-library-analytics"
  display_name = "Digital Library Analytics Service Account"
  description  = "Service account for Analytics Cloud Function"
}

# API Gateway Cloud Run Service
resource "google_cloud_run_service" "api_gateway" {
  name     = "digital-library-content-management-platform-run-api-gateway"
  location = var.region

  template {
    spec {
      service_account_name = google_service_account.api_gateway_sa.email
      containers {
        image = "gcr.io/cloudrun/hello"
        ports {
          container_port = 8080
        }
        env {
          name  = "DATABASE_URL"
          value = "postgresql://user:pass@${google_sql_database_instance.user_database.connection_name}/users"
        }
        resources {
          limits = {
            cpu    = "1000m"
            memory = "512Mi"
          }
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Search Service Cloud Run
resource "google_cloud_run_service" "search_service" {
  name     = "digital-library-content-management-platform-run-search"
  location = var.region

  template {
    spec {
      service_account_name = google_service_account.search_service_sa.email
      containers {
        image = "gcr.io/cloudrun/hello"
        ports {
          container_port = 8080
        }
        env {
          name  = "METADATA_DB_URL"
          value = "postgresql://user:pass@${google_sql_database_instance.metadata_database.connection_name}/metadata"
        }
        env {
          name  = "CONTENT_BUCKET"
          value = google_storage_bucket.content_storage.name
        }
        resources {
          limits = {
            cpu    = "1000m"
            memory = "512Mi"
          }
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Analytics Processor Cloud Function
resource "google_cloudfunctions_function" "analytics_processor" {
  name        = "digital-library-content-management-platform-function-analytics"
  description = "Processes usage events and generates reports"
  runtime     = "python39"
  region      = var.region

  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.usage_logs.name
  source_archive_object = "analytics-function.zip"
  trigger {
    event_type = "google.storage.object.finalize"
    resource   = google_storage_bucket.usage_logs.name
  }
  timeout               = 60
  entry_point          = "process_analytics"
  service_account_email = google_service_account.analytics_processor_sa.email

  environment_variables = {
    METADATA_DB_URL = "postgresql://user:pass@${google_sql_database_instance.metadata_database.connection_name}/metadata"
    LOGS_BUCKET     = google_storage_bucket.usage_logs.name
  }
}

# IAM Bindings with vulnerabilities
resource "google_project_iam_binding" "api_gateway_permissions" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"  # VULNERABILITY: Project-level service account impersonation

  members = [
    "serviceAccount:${google_service_account.api_gateway_sa.email}",
    "user:librarian@gmail.com",  # VULNERABILITY: Personal email account
  ]
}

resource "google_storage_bucket_iam_member" "content_storage_access" {
  bucket = google_storage_bucket.content_storage.name
  role   = "roles/storage.objectViewer"
  member = "user:admin@yahoo.com"  # VULNERABILITY: Personal email account
}

resource "google_project_iam_binding" "analytics_permissions" {
  project = var.project_id
  role    = "roles/iam.serviceAccountTokenCreator"  # VULNERABILITY: Project-level token creator

  members = [
    "serviceAccount:${google_service_account.analytics_processor_sa.email}",
    "user:developer@hotmail.com",  # VULNERABILITY: Personal email account
  ]
}

# Cloud Run IAM for public access
resource "google_cloud_run_service_iam_binding" "api_gateway_public" {
  location = google_cloud_run_service.api_gateway.location
  project  = google_cloud_run_service.api_gateway.project
  service  = google_cloud_run_service.api_gateway.name
  role     = "roles/run.invoker"

  members = [
    "allUsers",
  ]
}

resource "google_cloud_run_service_iam_binding" "search_service_public" {
  location = google_cloud_run_service.search_service.location
  project  = google_cloud_run_service.search_service.project
  service  = google_cloud_run_service.search_service.name
  role     = "roles/run.invoker"

  members = [
    "allUsers",
  ]
}

# Firewall Rules
resource "google_compute_firewall" "allow_http" {
  name    = "digital-library-content-management-platform-firewall-http"
  network = google_compute_network.digital_library_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server"]
}

resource "google_compute_firewall" "allow_internal" {
  name    = "digital-library-content-management-platform-firewall-internal"
  network = google_compute_network.digital_library_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = ["10.0.0.0/16"]
}