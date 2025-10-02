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
resource "google_compute_network" "carbon_tracking_vpc" {
  name                    = "corporate-carbon-footprint-tracking-platform-vpc-main"
  auto_create_subnetworks = false
  description             = "VPC for carbon tracking platform"
}

# Public subnet for load balancers and web services
resource "google_compute_subnetwork" "public_subnet" {
  name          = "corporate-carbon-footprint-tracking-platform-subnet-public"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.carbon_tracking_vpc.id
  # VULNERABILITY: Flow logs disabled
  enable_flow_logs = false
}

# Private subnet for compute resources
resource "google_compute_subnetwork" "private_subnet" {
  name          = "corporate-carbon-footprint-tracking-platform-subnet-private"
  ip_cidr_range = "10.0.2.0/24"
  region        = var.region
  network       = google_compute_network.carbon_tracking_vpc.id
}

# Data subnet for databases
resource "google_compute_subnetwork" "data_subnet" {
  name          = "corporate-carbon-footprint-tracking-platform-subnet-data"
  ip_cidr_range = "10.0.3.0/24"
  region        = var.region
  network       = google_compute_network.carbon_tracking_vpc.id
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# VULNERABILITY: Overpermissive firewall rule allowing all ports
resource "google_compute_firewall" "allow_all_internal" {
  name    = "corporate-carbon-footprint-tracking-platform-firewall-internal"
  network = google_compute_network.carbon_tracking_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  source_ranges = ["10.0.0.0/16"]
  target_tags   = ["carbon-tracking"]
}

resource "google_compute_firewall" "allow_web_traffic" {
  name    = "corporate-carbon-footprint-tracking-platform-firewall-web"
  network = google_compute_network.carbon_tracking_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

# Storage bucket for emissions data lake
resource "google_storage_bucket" "emissions_data_lake" {
  name          = "corporate-carbon-footprint-tracking-platform-storage-emissions-${random_id.bucket_suffix.hex}"
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

  encryption {
    default_kms_key_name = google_kms_crypto_key.storage_key.id
  }
}

# Storage bucket for reports
resource "google_storage_bucket" "reports_storage" {
  name          = "corporate-carbon-footprint-tracking-platform-storage-reports-${random_id.bucket_suffix.hex}"
  location      = var.region
  force_destroy = true

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.storage_key.id
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# KMS key for encryption
resource "google_kms_key_ring" "carbon_tracking_keyring" {
  name     = "corporate-carbon-footprint-tracking-platform-keyring"
  location = var.region
}

resource "google_kms_crypto_key" "storage_key" {
  name     = "corporate-carbon-footprint-tracking-platform-key-storage"
  key_ring = google_kms_key_ring.carbon_tracking_keyring.id
}

# VULNERABILITY: Using default service account
resource "google_project_iam_member" "default_service_account_assignment" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin"
  member  = "${var.project_id}-compute@developer.gserviceaccount.com"
}

# Service account for carbon calculation engine
resource "google_service_account" "carbon_calculation_sa" {
  account_id   = "carbon-calculation-engine"
  display_name = "Carbon Calculation Engine Service Account"
  description  = "Service account for carbon calculation compute instances"
}

# Carbon calculation engine compute instances
resource "google_compute_instance" "carbon_calculation_engine" {
  count        = 2
  name         = "corporate-carbon-footprint-tracking-platform-compute-calc-${count.index + 1}"
  machine_type = var.machine_type
  zone         = var.zone

  tags = ["carbon-tracking", "calculation-engine"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 50
      type  = "pd-ssd"
    }
  }

  # VULNERABILITY: Public IP exposure
  network_interface {
    network    = google_compute_network.carbon_tracking_vpc.name
    subnetwork = google_compute_subnetwork.private_subnet.name

    access_config {
      // Ephemeral IP
    }
  }

  # VULNERABILITY: Project-wide SSH keys enabled
  metadata = {
    block-project-ssh-keys = false
    startup-script = "#!/bin/bash\napt-get update\napt-get install -y python3 python3-pip\npip3 install pandas numpy scikit-learn"
  }

  service_account {
    email  = google_service_account.carbon_calculation_sa.email
    scopes = ["cloud-platform"]
  }

  # VULNERABILITY: Integrity monitoring disabled
  shielded_instance_config {
    enable_integrity_monitoring = false
    enable_vtpm                 = true
    enable_secure_boot          = true
  }
}

# Cloud SQL instance for reporting database
resource "google_sql_database_instance" "reporting_database" {
  name             = "corporate-carbon-footprint-tracking-platform-sql-reporting"
  database_version = "POSTGRES_14"
  region           = var.region

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.carbon_tracking_vpc.id
    }

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = true
    }

    # VULNERABILITY: Connection logging disabled
    database_flags {
      name  = "log_connections"
      value = "off"
    }

    # VULNERABILITY: Insufficient error logging
    database_flags {
      name  = "log_min_messages"
      value = "PANIC"
    }
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

resource "google_sql_database" "carbon_metrics_db" {
  name     = "carbon_metrics"
  instance = google_sql_database_instance.reporting_database.name
}

# Private service connection for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  name          = "corporate-carbon-footprint-tracking-platform-ip-private"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.carbon_tracking_vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.carbon_tracking_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# Cloud Functions for IoT data ingestion
resource "google_storage_bucket" "function_source" {
  name          = "corporate-carbon-footprint-tracking-platform-functions-${random_id.bucket_suffix.hex}"
  location      = var.region
  force_destroy = true
}

resource "google_storage_bucket_object" "function_zip" {
  name   = "iot-ingestion-function.zip"
  bucket = google_storage_bucket.function_source.name
  source = "function-source.zip"
}

resource "google_cloudfunctions_function" "iot_data_ingestion" {
  name        = "corporate-carbon-footprint-tracking-platform-function-iot-ingestion"
  description = "Function to ingest IoT sensor data"
  runtime     = "python39"

  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.function_source.name
  source_archive_object = google_storage_bucket_object.function_zip.name
  trigger {
    https_trigger {
      url = "https://us-central1-${var.project_id}.cloudfunctions.net/iot-data-ingestion"
    }
  }
  entry_point = "ingest_iot_data"

  environment_variables = {
    BUCKET_NAME = google_storage_bucket.emissions_data_lake.name
  }
}

# App Engine for sustainability dashboard
resource "google_app_engine_application" "sustainability_dashboard" {
  project     = var.project_id
  location_id = var.region
}

# Cloud Run service for report generation
resource "google_cloud_run_service" "report_generation_service" {
  name     = "corporate-carbon-footprint-tracking-platform-run-reports"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project_id}/report-generator:latest"
        
        env {
          name  = "DATABASE_URL"
          value = "postgresql://user:password@${google_sql_database_instance.reporting_database.private_ip_address}:5432/carbon_metrics"
        }
        
        env {
          name  = "STORAGE_BUCKET"
          value = google_storage_bucket.reports_storage.name
        }
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# IAM policy for Cloud Run
resource "google_cloud_run_service_iam_member" "report_service_invoker" {
  service  = google_cloud_run_service.report_generation_service.name
  location = google_cloud_run_service.report_generation_service.location
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.carbon_calculation_sa.email}"
}