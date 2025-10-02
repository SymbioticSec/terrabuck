terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# VPC Network
resource "google_compute_network" "autonomous_drone_delivery_vpc" {
  name                    = "autonomous-drone-delivery-management-platform-vpc-main"
  auto_create_subnetworks = false
  description             = "VPC for drone delivery management platform"
}

# Public Subnet for API endpoints
resource "google_compute_subnetwork" "public_subnet" {
  name                     = "autonomous-drone-delivery-management-platform-subnet-public"
  ip_cidr_range            = "10.0.1.0/24"
  region                   = var.region
  network                  = google_compute_network.autonomous_drone_delivery_vpc.id
  private_ip_google_access = false
}

# Private Subnet for internal services
resource "google_compute_subnetwork" "private_subnet" {
  name          = "autonomous-drone-delivery-management-platform-subnet-private"
  ip_cidr_range = "10.0.2.0/24"
  region        = var.region
  network       = google_compute_network.autonomous_drone_delivery_vpc.id
}

# Data Subnet for databases
resource "google_compute_subnetwork" "data_subnet" {
  name          = "autonomous-drone-delivery-management-platform-subnet-data"
  ip_cidr_range = "10.0.3.0/24"
  region        = var.region
  network       = google_compute_network.autonomous_drone_delivery_vpc.id
}

# Firewall rule for SSH access (vulnerable - allows 0.0.0.0/0)
resource "google_compute_firewall" "allow_ssh" {
  name    = "autonomous-drone-delivery-management-platform-firewall-ssh"
  network = google_compute_network.autonomous_drone_delivery_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["flight-coordination-engine"]
}

# Firewall rule for HTTP/HTTPS
resource "google_compute_firewall" "allow_http_https" {
  name    = "autonomous-drone-delivery-management-platform-firewall-web"
  network = google_compute_network.autonomous_drone_delivery_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

# Service Account for Flight Coordination Engine
resource "google_service_account" "flight_coordination_sa" {
  account_id   = "flight-coordination-engine-sa"
  display_name = "Flight Coordination Engine Service Account"
  description  = "Service account for drone flight coordination engine"
}

# IAM binding with direct user permissions (vulnerable)
resource "google_project_iam_binding" "flight_coordination_permissions" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin"

  members = [
    "user:drone-operator@${var.domain}",
    "serviceAccount:${google_service_account.flight_coordination_sa.email}"
  ]
}

# Flight Coordination Engine - Compute Instance
resource "google_compute_instance" "flight_coordination_engine" {
  name         = "autonomous-drone-delivery-management-platform-compute-flight-coordination"
  machine_type = var.flight_coordination_machine_type
  zone         = var.zone

  tags = ["flight-coordination-engine", "web-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 50
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = google_compute_network.autonomous_drone_delivery_vpc.id
    subnetwork = google_compute_subnetwork.private_subnet.id
    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    block-project-ssh-keys = false
    startup-script = <<-EOF
      #!/bin/bash
      apt-get update
      apt-get install -y docker.io
      systemctl start docker
      systemctl enable docker
    EOF
  }

  service_account {
    email  = google_service_account.flight_coordination_sa.email
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_vtpm = false
  }
}

# Operational Database - Cloud SQL
resource "google_sql_database_instance" "operational_database" {
  name             = "autonomous-drone-delivery-management-platform-sql-operational"
  database_version = "POSTGRES_14"
  region           = var.region

  settings {
    tier = var.database_tier

    ip_configuration {
      ipv4_enabled = true
      authorized_networks {
        value = "10.0.0.0/16"
        name  = "internal-network"
      }
      authorized_networks {
        value = "0.0.0.0/0"
        name  = "internet"
      }
      require_ssl = false
    }

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = true
    }

    database_flags {
      name  = "log_statement"
      value = "all"
    }
  }

  deletion_protection = false
}

# Database
resource "google_sql_database" "drone_delivery_db" {
  name     = "drone_delivery_platform"
  instance = google_sql_database_instance.operational_database.name
}

# Database User
resource "google_sql_user" "db_user" {
  name     = var.db_username
  instance = google_sql_database_instance.operational_database.name
  password = var.db_password
}

# Telemetry Data Lake - Cloud Storage
resource "google_storage_bucket" "telemetry_data_lake" {
  name          = "autonomous-drone-delivery-management-platform-storage-telemetry-${random_id.bucket_suffix.hex}"
  location      = var.region
  force_destroy = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }
}

# Archive Storage for Compliance Data
resource "google_storage_bucket" "compliance_archive" {
  name          = "autonomous-drone-delivery-management-platform-storage-compliance-${random_id.bucket_suffix.hex}"
  location      = var.region
  force_destroy = true
  storage_class = "COLDLINE"

  versioning {
    enabled = true
  }
}

# Random ID for bucket naming
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Archive for Cloud Functions
data "archive_file" "telemetry_function_zip" {
  type        = "zip"
  output_path = "/tmp/telemetry_function.zip"
  source {
    content = <<EOF
import json
import logging
from google.cloud import storage

def telemetry_ingestion(request):
    """Ingests drone telemetry data"""
    try:
        telemetry_data = request.get_json()
        logging.info(f"Received telemetry: {telemetry_data}")
        
        # Store in Cloud Storage
        client = storage.Client()
        bucket = client.bucket('${google_storage_bucket.telemetry_data_lake.name}')
        blob = bucket.blob(f"telemetry/{telemetry_data.get('drone_id', 'unknown')}/{telemetry_data.get('timestamp', 'unknown')}.json")
        blob.upload_from_string(json.dumps(telemetry_data))
        
        return {"status": "success", "message": "Telemetry data ingested"}
    except Exception as e:
        logging.error(f"Error processing telemetry: {str(e)}")
        return {"status": "error", "message": str(e)}, 500
EOF
    filename = "main.py"
  }
  source {
    content = "google-cloud-storage==2.10.0"
    filename = "requirements.txt"
  }
}

# Drone Telemetry Ingestion Function
resource "google_cloudfunctions_function" "drone_telemetry_ingestion" {
  name        = "autonomous-drone-delivery-management-platform-function-telemetry-ingestion"
  description = "Ingests real-time telemetry data from drone fleet"
  runtime     = "python39"
  region      = var.region

  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.telemetry_data_lake.name
  source_archive_object = google_storage_bucket_object.telemetry_function_source.name
  trigger {
    https_trigger {
      url = ""
    }
  }
  entry_point = "telemetry_ingestion"

  service_account_email = google_service_account.flight_coordination_sa.email
}

# Upload function source to bucket
resource "google_storage_bucket_object" "telemetry_function_source" {
  name   = "telemetry_function.zip"
  bucket = google_storage_bucket.telemetry_data_lake.name
  source = data.archive_file.telemetry_function_zip.output_path
}

# Archive for Compliance Function
data "archive_file" "compliance_function_zip" {
  type        = "zip"
  output_path = "/tmp/compliance_function.zip"
  source {
    content = <<EOF
import json
import logging
from google.cloud import storage, sql

def compliance_reporting(request):
    """Generates FAA compliance reports"""
    try:
        report_type = request.args.get('type', 'daily')
        logging.info(f"Generating {report_type} compliance report")
        
        # Generate compliance report
        report_data = {
            "report_type": report_type,
            "generated_at": "2024-01-01T00:00:00Z",
            "flight_count": 150,
            "compliance_status": "COMPLIANT"
        }
        
        return {"status": "success", "report": report_data}
    except Exception as e:
        logging.error(f"Error generating compliance report: {str(e)}")
        return {"status": "error", "message": str(e)}, 500
EOF
    filename = "main.py"
  }
  source {
    content = "google-cloud-storage==2.10.0"
    filename = "requirements.txt"
  }
}

# Compliance Reporting Function
resource "google_cloudfunctions_function" "compliance_reporting_service" {
  name        = "autonomous-drone-delivery-management-platform-function-compliance-reporting"
  description = "Automated generation of FAA compliance reports"
  runtime     = "python39"
  region      = var.region

  available_memory_mb   = 512
  source_archive_bucket = google_storage_bucket.compliance_archive.name
  source_archive_object = google_storage_bucket_object.compliance_function_source.name
  trigger {
    https_trigger {
      url = ""
    }
  }
  entry_point = "compliance_reporting"

  service_account_email = google_service_account.flight_coordination_sa.email
}

# Upload compliance function source to bucket
resource "google_storage_bucket_object" "compliance_function_source" {
  name   = "compliance_function.zip"
  bucket = google_storage_bucket.compliance_archive.name
  source = data.archive_file.compliance_function_zip.output_path
}

# Cloud Run Service for Delivery Tracking API
resource "google_cloud_run_service" "delivery_tracking_api" {
  name     = "autonomous-drone-delivery-management-platform-run-delivery-tracking"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/cloudrun/hello"
        ports {
          container_port = 8080
        }
        env {
          name  = "DATABASE_URL"
          value = "postgresql://${google_sql_user.db_user.name}:${var.db_password}@${google_sql_database_instance.operational_database.connection_name}/${google_sql_database.drone_delivery_db.name}"
        }
        resources {
          limits = {
            cpu    = "1000m"
            memory = "512Mi"
          }
        }
      }
      service_account_name = google_service_account.flight_coordination_sa.email
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Cloud Run IAM
resource "google_cloud_run_service_iam_binding" "delivery_api_invoker" {
  location = google_cloud_run_service.delivery_tracking_api.location
  project  = google_cloud_run_service.delivery_tracking_api.project
  service  = google_cloud_run_service.delivery_tracking_api.name
  role     = "roles/run.invoker"

  members = [
    "allUsers",
  ]
}

# Load Balancer for API endpoints
resource "google_compute_global_address" "api_lb_ip" {
  name = "autonomous-drone-delivery-management-platform-lb-api-ip"
}

# Health Check
resource "google_compute_health_check" "api_health_check" {
  name = "autonomous-drone-delivery-management-platform-healthcheck-api"

  http_health_check {
    port = 8080
    path = "/health"
  }

  check_interval_sec  = 30
  timeout_sec         = 10
  healthy_threshold   = 2
  unhealthy_threshold = 3
}