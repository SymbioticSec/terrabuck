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
resource "google_compute_network" "fleet_management_vpc" {
  name                    = "fleet-management-and-gps-tracking-platform-vpc-main"
  auto_create_subnetworks = false
  routing_mode           = "REGIONAL"
}

# Public Subnet for Load Balancers
resource "google_compute_subnetwork" "public_subnet" {
  name          = "fleet-management-and-gps-tracking-platform-subnet-public"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.fleet_management_vpc.id
  
  # Vulnerability: VPC Flow Logs Not Enabled
  # Missing log_config block
}

# Private Subnet for Compute Resources
resource "google_compute_subnetwork" "private_subnet" {
  name          = "fleet-management-and-gps-tracking-platform-subnet-private"
  ip_cidr_range = "10.0.2.0/24"
  region        = var.region
  network       = google_compute_network.fleet_management_vpc.id
  
  # Vulnerability: VPC Flow Logs Not Enabled
  # Missing log_config block
}

# Cloud NAT for Private Subnet
resource "google_compute_router" "fleet_router" {
  name    = "fleet-management-and-gps-tracking-platform-router-nat"
  region  = var.region
  network = google_compute_network.fleet_management_vpc.id
}

resource "google_compute_router_nat" "fleet_nat" {
  name                               = "fleet-management-and-gps-tracking-platform-nat-gateway"
  router                            = google_compute_router.fleet_router.name
  region                            = var.region
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# KMS Key Ring and Crypto Key for Encryption
resource "google_kms_key_ring" "fleet_keyring" {
  name     = "fleet-management-and-gps-tracking-platform-keyring-main"
  location = var.region
}

resource "google_kms_crypto_key" "telemetry_key" {
  name     = "fleet-management-and-gps-tracking-platform-key-telemetry"
  key_ring = google_kms_key_ring.fleet_keyring.id
  
  # Vulnerability: KMS Key Rotation Period Too Long
  rotation_period = "15552000s"  # 180 days instead of recommended 90 days
}

# Telemetry Data Lake Storage Bucket
resource "google_storage_bucket" "telemetry_data_lake" {
  name          = "fleet-management-and-gps-tracking-platform-bucket-telemetry-${random_id.bucket_suffix.hex}"
  location      = var.region
  force_destroy = true

  encryption {
    default_kms_key_name = google_kms_crypto_key.telemetry_key.id
  }

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type = "Delete"
    }
  }
}

# Analytics Storage Bucket
resource "google_storage_bucket" "analytics_storage" {
  name          = "fleet-management-and-gps-tracking-platform-bucket-analytics-${random_id.bucket_suffix.hex}"
  location      = var.region
  force_destroy = true

  versioning {
    enabled = true
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Cloud SQL Database Instance
resource "google_sql_database_instance" "fleet_database" {
  name             = "fleet-management-and-gps-tracking-platform-sql-main"
  database_version = "POSTGRES_14"
  region           = var.region
  deletion_protection = false

  settings {
    tier = "db-f1-micro"
    
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.fleet_management_vpc.id
      require_ssl     = true
    }

    backup_configuration {
      enabled                        = true
      start_time                    = "03:00"
      point_in_time_recovery_enabled = true
    }

    database_flags {
      # Vulnerability: PostgreSQL Log Lock Waits Disabled
      name  = "log_lock_waits"
      value = "off"
    }

    database_flags {
      # Vulnerability: PostgreSQL Error Logging Insufficient
      name  = "log_min_messages"
      value = "PANIC"
    }
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# Private VPC Connection for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  name          = "fleet-management-and-gps-tracking-platform-ip-private"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.fleet_management_vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.fleet_management_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# Cloud SQL Database
resource "google_sql_database" "fleet_db" {
  name     = "fleetdb"
  instance = google_sql_database_instance.fleet_database.name
}

# Service Account for Dataflow (Vulnerability: Using default service account)
resource "google_project_iam_member" "dataflow_default_sa" {
  project = var.project_id
  role    = "roles/dataflow.worker"
  # Vulnerability: No Project Level Default Service Account Assignment
  member  = "${var.project_number}-compute@developer.gserviceaccount.com"
}

# Fleet Management API Compute Instance
resource "google_compute_instance" "fleet_management_api" {
  name         = "fleet-management-and-gps-tracking-platform-vm-api"
  machine_type = "e2-medium"
  zone         = var.zone

  # Vulnerability: VM Disk Encryption Customer Key Missing
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
    }
    # Missing kms_key_self_link
  }

  network_interface {
    network    = google_compute_network.fleet_management_vpc.name
    subnetwork = google_compute_subnetwork.private_subnet.name
  }

  metadata_startup_script = file("${path.module}/scripts/api-startup.sh")

  service_account {
    email  = google_service_account.api_service_account.email
    scopes = ["cloud-platform"]
  }

  tags = ["fleet-api", "private"]
}

# Dispatcher Dashboard Compute Instance
resource "google_compute_instance" "dispatcher_dashboard" {
  name         = "fleet-management-and-gps-tracking-platform-vm-dashboard"
  machine_type = "e2-medium"
  zone         = var.zone

  # Vulnerability: VM Disk Encryption Customer Key Missing
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
    }
    # Missing kms_key_self_link
  }

  network_interface {
    network    = google_compute_network.fleet_management_vpc.name
    subnetwork = google_compute_subnetwork.private_subnet.name
  }

  metadata_startup_script = file("${path.module}/scripts/dashboard-startup.sh")

  service_account {
    email  = google_service_account.dashboard_service_account.email
    scopes = ["cloud-platform"]
  }

  tags = ["fleet-dashboard", "private"]
}

# Service Accounts
resource "google_service_account" "api_service_account" {
  account_id   = "fleet-api-sa"
  display_name = "Fleet Management API Service Account"
}

resource "google_service_account" "dashboard_service_account" {
  account_id   = "fleet-dashboard-sa"
  display_name = "Fleet Dashboard Service Account"
}

# SSL Policy for Load Balancer
resource "google_compute_ssl_policy" "fleet_ssl_policy" {
  name    = "fleet-management-and-gps-tracking-platform-ssl-policy"
  profile = "MODERN"
  # Vulnerability: Insecure TLS Policy Configuration
  min_tls_version = "TLS_1_1"
}

# Load Balancer Components
resource "google_compute_global_address" "dashboard_ip" {
  name = "fleet-management-and-gps-tracking-platform-ip-dashboard"
}

resource "google_compute_instance_group" "dashboard_group" {
  name = "fleet-management-and-gps-tracking-platform-ig-dashboard"
  zone = var.zone

  instances = [google_compute_instance.dispatcher_dashboard.id]

  named_port {
    name = "http"
    port = "80"
  }
}

# Cloud Functions for Vehicle Telemetry Ingestion
resource "google_storage_bucket_object" "telemetry_function_source" {
  name   = "telemetry-ingestion-${random_id.function_suffix.hex}.zip"
  bucket = google_storage_bucket.analytics_storage.name
  source = data.archive_file.telemetry_function_zip.output_path
}

data "archive_file" "telemetry_function_zip" {
  type        = "zip"
  output_path = "/tmp/telemetry-function.zip"
  source {
    content  = file("${path.module}/functions/telemetry-ingestion/main.py")
    filename = "main.py"
  }
  source {
    content  = file("${path.module}/functions/telemetry-ingestion/requirements.txt")
    filename = "requirements.txt"
  }
}

resource "google_cloudfunctions_function" "vehicle_telemetry_ingestion" {
  name        = "fleet-management-and-gps-tracking-platform-function-telemetry"
  description = "Ingests vehicle telemetry data"
  runtime     = "python39"
  region      = var.region

  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.analytics_storage.name
  source_archive_object = google_storage_bucket_object.telemetry_function_source.name
  trigger {
    https_trigger {
      url = ""
    }
  }
  entry_point = "ingest_telemetry"

  service_account_email = google_service_account.telemetry_function_sa.email
}

# Analytics Processing Function
resource "google_storage_bucket_object" "analytics_function_source" {
  name   = "analytics-processing-${random_id.function_suffix.hex}.zip"
  bucket = google_storage_bucket.analytics_storage.name
  source = data.archive_file.analytics_function_zip.output_path
}

data "archive_file" "analytics_function_zip" {
  type        = "zip"
  output_path = "/tmp/analytics-function.zip"
  source {
    content  = file("${path.module}/functions/analytics-processing/main.py")
    filename = "main.py"
  }
  source {
    content  = file("${path.module}/functions/analytics-processing/requirements.txt")
    filename = "requirements.txt"
  }
}

resource "google_cloudfunctions_function" "analytics_processing" {
  name        = "fleet-management-and-gps-tracking-platform-function-analytics"
  description = "Processes analytics for fleet optimization"
  runtime     = "python39"
  region      = var.region

  available_memory_mb   = 512
  source_archive_bucket = google_storage_bucket.analytics_storage.name
  source_archive_object = google_storage_bucket_object.analytics_function_source.name
  trigger {
    event_trigger {
      event_type = "google.storage.object.finalize"
      resource   = google_storage_bucket.telemetry_data_lake.name
    }
  }
  entry_point = "process_analytics"

  service_account_email = google_service_account.analytics_function_sa.email
}

resource "random_id" "function_suffix" {
  byte_length = 4
}

# Service Accounts for Functions
resource "google_service_account" "telemetry_function_sa" {
  account_id   = "telemetry-function-sa"
  display_name = "Telemetry Function Service Account"
}

resource "google_service_account" "analytics_function_sa" {
  account_id   = "analytics-function-sa"
  display_name = "Analytics Function Service Account"
}

# Firewall Rules
resource "google_compute_firewall" "allow_internal" {
  name    = "fleet-management-and-gps-tracking-platform-fw-internal"
  network = google_compute_network.fleet_management_vpc.name

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

resource "google_compute_firewall" "allow_dashboard_http" {
  name    = "fleet-management-and-gps-tracking-platform-fw-dashboard"
  network = google_compute_network.fleet_management_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["fleet-dashboard"]
}