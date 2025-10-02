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
resource "google_compute_network" "trading_platform_vpc" {
  name                    = "real-time-financial-trading-platform-vpc-main"
  auto_create_subnetworks = false
  description             = "VPC for high-frequency trading platform"
}

# Public Subnet for Load Balancers
resource "google_compute_subnetwork" "public_subnet" {
  name                     = "real-time-financial-trading-platform-subnet-public"
  ip_cidr_range            = "10.0.1.0/24"
  region                   = var.region
  network                  = google_compute_network.trading_platform_vpc.id
  private_ip_google_access = false
}

# Private Subnet for Application Services
resource "google_compute_subnetwork" "private_subnet" {
  name                     = "real-time-financial-trading-platform-subnet-private"
  ip_cidr_range            = "10.0.2.0/24"
  region                   = var.region
  network                  = google_compute_network.trading_platform_vpc.id
  private_ip_google_access = false
}

# Data Subnet for Database
resource "google_compute_subnetwork" "data_subnet" {
  name          = "real-time-financial-trading-platform-subnet-data"
  ip_cidr_range = "10.0.3.0/24"
  region        = var.region
  network       = google_compute_network.trading_platform_vpc.id
}

# Firewall Rule - Overpermissive
resource "google_compute_firewall" "trading_platform_firewall" {
  name    = "real-time-financial-trading-platform-firewall-main"
  network = google_compute_network.trading_platform_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["trading-engine", "market-data"]
}

# Service Account for Trading Engine
resource "google_service_account" "trading_engine_sa" {
  account_id   = "trading-engine-sa"
  display_name = "Trading Engine Service Account"
  description  = "Service account for trading engine compute instance"
}

# Trading Database Instance
resource "google_sql_database_instance" "trading_database" {
  name             = "real-time-financial-trading-platform-database-trading"
  database_version = "POSTGRES_13"
  region           = var.region
  deletion_protection = false

  settings {
    tier = "db-n1-standard-2"
    
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.trading_platform_vpc.id
    }

    database_flags {
      name  = "log_connections"
      value = "off"
    }

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = true
    }
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# Database
resource "google_sql_database" "trading_db" {
  name     = "trading_data"
  instance = google_sql_database_instance.trading_database.name
}

# Private Service Connection for Database
resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.trading_platform_vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.trading_platform_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# Market Data Storage Bucket
resource "google_storage_bucket" "market_data_storage" {
  name     = "real-time-financial-trading-platform-storage-market-data-${random_id.bucket_suffix.hex}"
  location = var.region

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }

  versioning {
    enabled = true
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# Pub/Sub Topic for Market Data
resource "google_pubsub_topic" "market_data_topic" {
  name = "real-time-financial-trading-platform-pubsub-market-data"
}

# Pub/Sub Topic for Trade Signals
resource "google_pubsub_topic" "trade_signals_topic" {
  name = "real-time-financial-trading-platform-pubsub-trade-signals"
}

# Trading Engine Compute Instance
resource "google_compute_instance" "trading_engine" {
  name         = "real-time-financial-trading-platform-compute-trading-engine"
  machine_type = "c2-standard-8"
  zone         = var.zone

  tags = ["trading-engine"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 50
      type  = "pd-ssd"
    }
  }

  network_interface {
    network    = google_compute_network.trading_platform_vpc.id
    subnetwork = google_compute_subnetwork.private_subnet.id
  }

  service_account {
    email  = google_service_account.trading_engine_sa.email
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_vtpm = false
    enable_integrity_monitoring = true
  }

  metadata_startup_script = file("${path.module}/startup-script.sh")
}

# Cloud Run Service for Market Data Ingester
resource "google_cloud_run_service" "market_data_ingester" {
  name     = "real-time-financial-trading-platform-cloudrun-market-data-ingester"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project_id}/market-data-ingester:latest"
        
        env {
          name  = "PUBSUB_TOPIC"
          value = google_pubsub_topic.market_data_topic.name
        }
        
        env {
          name  = "STORAGE_BUCKET"
          value = google_storage_bucket.market_data_storage.name
        }

        resources {
          limits = {
            cpu    = "2000m"
            memory = "2Gi"
          }
        }
      }
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "100"
        "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.trading_connector.name
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# VPC Access Connector
resource "google_vpc_access_connector" "trading_connector" {
  name          = "trading-connector"
  region        = var.region
  ip_cidr_range = "10.8.0.0/28"
  network       = google_compute_network.trading_platform_vpc.name
}

# Cloud Function for Risk Manager
resource "google_cloudfunctions_function" "risk_manager" {
  name        = "real-time-financial-trading-platform-function-risk-manager"
  description = "Risk calculation and position monitoring"
  runtime     = "python39"
  region      = var.region

  available_memory_mb   = 512
  source_archive_bucket = google_storage_bucket.function_source.name
  source_archive_object = google_storage_bucket_object.risk_manager_source.name
  entry_point          = "process_risk"

  event_trigger {
    event_type = "providers/cloud.pubsub/eventTypes/topic.publish"
    resource   = google_pubsub_topic.trade_signals_topic.name
  }

  environment_variables = {
    DATABASE_CONNECTION = "postgresql://${google_sql_user.trading_user.name}:${google_sql_user.trading_user.password}@${google_sql_database_instance.trading_database.private_ip_address}:5432/${google_sql_database.trading_db.name}"
  }

  vpc_connector = google_vpc_access_connector.trading_connector.name
}

# Function Source Bucket
resource "google_storage_bucket" "function_source" {
  name     = "real-time-financial-trading-platform-storage-functions-${random_id.function_bucket_suffix.hex}"
  location = var.region
}

resource "random_id" "function_bucket_suffix" {
  byte_length = 4
}

# Function Source Object
resource "google_storage_bucket_object" "risk_manager_source" {
  name   = "risk-manager-source.zip"
  bucket = google_storage_bucket.function_source.name
  source = "risk-manager-source.zip"
}

# Database User
resource "google_sql_user" "trading_user" {
  name     = "trading_app"
  instance = google_sql_database_instance.trading_database.name
  password = var.db_password
}

# IAM Binding - Direct User Permission
resource "google_project_iam_binding" "trading_platform_admin" {
  project = var.project_id
  role    = "roles/editor"

  members = [
    "user:trader@${var.organization_domain}",
    "user:admin@${var.organization_domain}",
  ]
}

# Service Account IAM
resource "google_project_iam_member" "trading_engine_permissions" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.trading_engine_sa.email}"
}

# Pub/Sub Subscriptions
resource "google_pubsub_subscription" "market_data_subscription" {
  name  = "market-data-subscription"
  topic = google_pubsub_topic.market_data_topic.name

  ack_deadline_seconds = 20
}

resource "google_pubsub_subscription" "trade_signals_subscription" {
  name  = "trade-signals-subscription"
  topic = google_pubsub_topic.trade_signals_topic.name

  ack_deadline_seconds = 10
}