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
}

# VPC Network
resource "google_compute_network" "smart_city_vpc" {
  name                    = "smart-city-traffic-management-platform-vpc-main"
  auto_create_subnetworks = false
  description             = "VPC for Smart City Traffic Management Platform"
}

# Public Subnet
resource "google_compute_subnetwork" "public_subnet" {
  name          = "smart-city-traffic-management-platform-subnet-public"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.smart_city_vpc.id
  enable_flow_logs = false
}

# Private Subnet
resource "google_compute_subnetwork" "private_subnet" {
  name          = "smart-city-traffic-management-platform-subnet-private"
  ip_cidr_range = "10.0.2.0/24"
  region        = var.region
  network       = google_compute_network.smart_city_vpc.id
  enable_flow_logs = false
}

# Firewall Rules - Allow internal traffic
resource "google_compute_firewall" "allow_internal" {
  name    = "smart-city-traffic-management-platform-firewall-internal"
  network = google_compute_network.smart_city_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.0.0.0/16"]
}

# Firewall Rules - Egress with vulnerability
resource "google_compute_firewall" "allow_egress" {
  name      = "smart-city-traffic-management-platform-firewall-egress"
  network   = google_compute_network.smart_city_vpc.name
  direction = "EGRESS"

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  destination_ranges = ["0.0.0.0/0"]
}

# Pub/Sub Topic for Sensor Data Ingestion
resource "google_pubsub_topic" "sensor_data_ingestion" {
  name = "smart-city-traffic-management-platform-pubsub-sensor-data"

  message_retention_duration = "86400s"
  
  labels = {
    environment = var.environment
    component   = "sensor-data-ingestion"
  }
}

# Pub/Sub Subscription
resource "google_pubsub_subscription" "sensor_data_subscription" {
  name  = "smart-city-traffic-management-platform-pubsub-sensor-subscription"
  topic = google_pubsub_topic.sensor_data_ingestion.name

  message_retention_duration = "1200s"
  retain_acked_messages      = true
  ack_deadline_seconds       = 20
}

# Cloud SQL Database Instance with vulnerabilities
resource "google_sql_database_instance" "traffic_database" {
  name             = "smart-city-traffic-management-platform-sql-main"
  database_version = "POSTGRES_13"
  region           = var.region

  settings {
    tier = "db-f1-micro"
    
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.smart_city_vpc.id
    }

    database_flags {
      name  = "log_checkpoints"
      value = "off"
    }

    database_flags {
      name  = "log_min_messages"
      value = "PANIC"
    }

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = true
    }
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# Cloud SQL Database
resource "google_sql_database" "traffic_data" {
  name     = "traffic_data"
  instance = google_sql_database_instance.traffic_database.name
}

# Service Networking Connection for Private IP
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.smart_city_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# Reserved IP Range for Private Services
resource "google_compute_global_address" "private_ip_address" {
  name          = "smart-city-traffic-management-platform-ip-private"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.smart_city_vpc.id
}

# Storage Bucket for Static Assets
resource "google_storage_bucket" "static_assets" {
  name     = "smart-city-traffic-management-platform-storage-assets-${random_id.bucket_suffix.hex}"
  location = var.region

  versioning {
    enabled = true
  }

  labels = {
    environment = var.environment
    component   = "static-assets"
  }
}

# Random ID for bucket naming
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# Service Account for Cloud Functions with vulnerability
resource "google_service_account" "function_sa" {
  account_id   = "traffic-data-processor-sa"
  display_name = "Traffic Data Processor Service Account"
  description  = "Service account for traffic data processing functions"
}

# IAM binding with user vulnerability
resource "google_project_iam_member" "function_sa_permissions" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "user:traffic-operator@${var.project_id}.iam.gserviceaccount.com"
}

# Cloud Function for Traffic Data Processing
resource "google_cloudfunctions_function" "traffic_data_processor" {
  name        = "smart-city-traffic-management-platform-function-processor"
  description = "Processes incoming sensor data and calculates traffic patterns"
  runtime     = "python39"

  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.function_source.name
  source_archive_object = google_storage_bucket_object.function_zip.name
  trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.sensor_data_ingestion.name
  }
  entry_point = "process_traffic_data"

  environment_variables = {
    DB_HOST = google_sql_database_instance.traffic_database.private_ip_address
    DB_NAME = google_sql_database.traffic_data.name
  }

  service_account_email = google_service_account.function_sa.email
}

# Storage bucket for function source
resource "google_storage_bucket" "function_source" {
  name     = "smart-city-traffic-management-platform-storage-functions-${random_id.function_bucket_suffix.hex}"
  location = var.region
}

# Random ID for function bucket
resource "random_id" "function_bucket_suffix" {
  byte_length = 8
}

# Function source code placeholder
resource "google_storage_bucket_object" "function_zip" {
  name   = "function-source.zip"
  bucket = google_storage_bucket.function_source.name
  source = "function-source.zip"
}

# Compute Instance for Operator Dashboard with vulnerabilities
resource "google_compute_instance" "operator_dashboard" {
  name         = "smart-city-traffic-management-platform-compute-dashboard"
  machine_type = "e2-medium"
  zone         = "${var.region}-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
    }
  }

  network_interface {
    network    = google_compute_network.smart_city_vpc.name
    subnetwork = google_compute_subnetwork.private_subnet.name
    
    access_config {
      // Ephemeral IP - vulnerability
    }
  }

  service_account {
    email  = "${var.project_number}-compute@developer.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = "apt-get update && apt-get install -y nginx"

  tags = ["dashboard", "web-server"]

  labels = {
    environment = var.environment
    component   = "operator-dashboard"
  }
}

# Cloud Run Service for Public API Gateway
resource "google_cloud_run_service" "public_api_gateway" {
  name     = "smart-city-traffic-management-platform-run-api"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project_id}/traffic-api:latest"
        
        env {
          name  = "DB_HOST"
          value = google_sql_database_instance.traffic_database.private_ip_address
        }
        
        env {
          name  = "DB_NAME"
          value = google_sql_database.traffic_data.name
        }

        resources {
          limits = {
            cpu    = "1000m"
            memory = "512Mi"
          }
        }
      }
      
      service_account_name = google_service_account.api_sa.email
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "100"
        "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.connector.name
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Service Account for Cloud Run API
resource "google_service_account" "api_sa" {
  account_id   = "public-api-gateway-sa"
  display_name = "Public API Gateway Service Account"
  description  = "Service account for public API gateway"
}

# VPC Access Connector
resource "google_vpc_access_connector" "connector" {
  name          = "smart-city-traffic-management-platform-connector-vpc"
  ip_cidr_range = "10.8.0.0/28"
  network       = google_compute_network.smart_city_vpc.name
  region        = var.region
}

# Cloud Run IAM
resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_service.public_api_gateway.name
  location = google_cloud_run_service.public_api_gateway.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}