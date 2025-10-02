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
resource "google_compute_network" "digital_asset_trading_vpc" {
  name                    = "digital-asset-trading-platform-vpc-main"
  auto_create_subnetworks = false
  routing_mode           = "REGIONAL"
}

# Public Subnet for Load Balancer
resource "google_compute_subnetwork" "public_subnet" {
  name          = "digital-asset-trading-platform-subnet-public"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.digital_asset_trading_vpc.id
  enable_flow_logs = false
}

# Private Subnet for API Gateway
resource "google_compute_subnetwork" "private_subnet" {
  name          = "digital-asset-trading-platform-subnet-private"
  ip_cidr_range = "10.0.2.0/24"
  region        = var.region
  network       = google_compute_network.digital_asset_trading_vpc.id
  enable_flow_logs = false
}

# Data Subnet for Trading Engine and Database
resource "google_compute_subnetwork" "data_subnet" {
  name          = "digital-asset-trading-platform-subnet-data"
  ip_cidr_range = "10.0.3.0/24"
  region        = var.region
  network       = google_compute_network.digital_asset_trading_vpc.id
}

# Firewall rule allowing SSH from anywhere (VULNERABILITY)
resource "google_compute_firewall" "allow_ssh_public" {
  name    = "digital-asset-trading-platform-firewall-ssh"
  network = google_compute_network.digital_asset_trading_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["trading-engine"]
}

# Firewall rule allowing HTTP/HTTPS traffic
resource "google_compute_firewall" "allow_http_https" {
  name    = "digital-asset-trading-platform-firewall-web"
  network = google_compute_network.digital_asset_trading_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

# Trading Engine Instance Template
resource "google_compute_instance_template" "trading_engine_template" {
  name         = "digital-asset-trading-platform-template-engine"
  machine_type = var.trading_engine_machine_type
  region       = var.region

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
    disk_size_gb = 50
  }

  network_interface {
    subnetwork = google_compute_subnetwork.data_subnet.id
    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    block-project-ssh-keys = false
    startup-script = "#!/bin/bash\napt-get update\napt-get install -y docker.io\nsystemctl start docker"
  }

  tags = ["trading-engine"]

  shielded_instance_config {
    enable_vtpm = false
    enable_integrity_monitoring = true
  }

  service_account {
    email  = google_service_account.trading_engine_sa.email
    scopes = ["cloud-platform"]
  }
}

# Trading Engine Instance Group
resource "google_compute_instance_group_manager" "trading_engine_cluster" {
  name               = "digital-asset-trading-platform-cluster-engine"
  base_instance_name = "trading-engine"
  zone               = "${var.region}-a"
  target_size        = var.trading_engine_instance_count

  version {
    instance_template = google_compute_instance_template.trading_engine_template.id
  }

  named_port {
    name = "http"
    port = 8080
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.trading_engine_health.id
    initial_delay_sec = 300
  }
}

# Health Check for Trading Engine
resource "google_compute_health_check" "trading_engine_health" {
  name               = "digital-asset-trading-platform-health-engine"
  check_interval_sec = 30
  timeout_sec        = 10

  http_health_check {
    port         = 8080
    request_path = "/health"
  }
}

# Service Account for Trading Engine
resource "google_service_account" "trading_engine_sa" {
  account_id   = "trading-engine-sa"
  display_name = "Trading Engine Service Account"
}

# Redis Instance for Market Data Cache
resource "google_redis_instance" "market_data_cache" {
  name           = "digital-asset-trading-platform-cache-market"
  tier           = "STANDARD_HA"
  memory_size_gb = var.redis_memory_size
  region         = var.region

  authorized_network = google_compute_network.digital_asset_trading_vpc.id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"
  redis_version      = "REDIS_6_X"

  display_name = "Market Data Cache"
}

# Cloud SQL Database Instance
resource "google_sql_database_instance" "trading_database" {
  name             = "digital-asset-trading-platform-db-main"
  database_version = "POSTGRES_14"
  region           = var.region

  settings {
    tier = var.database_tier
    
    ip_configuration {
      ipv4_enabled    = true
      private_network = google_compute_network.digital_asset_trading_vpc.id
      authorized_networks {
        name  = "all"
        value = "0.0.0.0/0"
      }
    }

    backup_configuration {
      enabled    = true
      start_time = "03:00"
    }

    database_flags {
      name  = "log_min_messages"
      value = "PANIC"
    }
  }

  deletion_protection = false
}

# Cloud SQL Database
resource "google_sql_database" "trading_db" {
  name     = "trading_platform"
  instance = google_sql_database_instance.trading_database.name
}

# Cloud SQL User
resource "google_sql_user" "trading_user" {
  name     = var.database_user
  instance = google_sql_database_instance.trading_database.name
  password = var.database_password
}

# Cloud Run Service for API Gateway
resource "google_cloud_run_service" "api_gateway" {
  name     = "digital-asset-trading-platform-api-gateway"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/cloudrun/hello"
        
        env {
          name  = "DATABASE_URL"
          value = "postgresql://${google_sql_user.trading_user.name}:${var.database_password}@${google_sql_database_instance.trading_database.private_ip_address}:5432/${google_sql_database.trading_db.name}"
        }

        env {
          name  = "REDIS_URL"
          value = "redis://${google_redis_instance.market_data_cache.host}:${google_redis_instance.market_data_cache.port}"
        }

        resources {
          limits = {
            cpu    = "2000m"
            memory = "2Gi"
          }
        }
      }
      
      service_account_name = google_service_account.api_gateway_sa.email
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "100"
        "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.api_connector.name
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Service Account for API Gateway
resource "google_service_account" "api_gateway_sa" {
  account_id   = "api-gateway-sa"
  display_name = "API Gateway Service Account"
}

# VPC Access Connector for Cloud Run
resource "google_vpc_access_connector" "api_connector" {
  name          = "digital-asset-trading-platform-connector-api"
  ip_cidr_range = "10.8.0.0/28"
  network       = google_compute_network.digital_asset_trading_vpc.name
  region        = var.region
}

# Cloud Run IAM Policy
resource "google_cloud_run_service_iam_binding" "api_gateway_invoker" {
  location = google_cloud_run_service.api_gateway.location
  project  = google_cloud_run_service.api_gateway.project
  service  = google_cloud_run_service.api_gateway.name
  role     = "roles/run.invoker"
  members  = ["user:trader@company.com"]
}

# Storage Bucket for Compliance Data
resource "google_storage_bucket" "compliance_storage" {
  name     = "${var.project_id}-digital-asset-trading-platform-compliance"
  location = var.region

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 2555
    }
    action {
      type = "Delete"
    }
  }
}

# Load Balancer Backend Service
resource "google_compute_backend_service" "api_backend" {
  name        = "digital-asset-trading-platform-backend-api"
  protocol    = "HTTP"
  timeout_sec = 30

  backend {
    group = google_compute_instance_group_manager.trading_engine_cluster.instance_group
  }

  health_checks = [google_compute_health_check.trading_engine_health.id]
}

# Load Balancer URL Map
resource "google_compute_url_map" "load_balancer" {
  name            = "digital-asset-trading-platform-urlmap-main"
  default_service = google_compute_backend_service.api_backend.id
}

# Load Balancer HTTP Proxy
resource "google_compute_target_http_proxy" "load_balancer_proxy" {
  name    = "digital-asset-trading-platform-proxy-http"
  url_map = google_compute_url_map.load_balancer.id
}

# Global Forwarding Rule
resource "google_compute_global_forwarding_rule" "load_balancer" {
  name       = "digital-asset-trading-platform-forwarding-rule-main"
  target     = google_compute_target_http_proxy.load_balancer_proxy.id
  port_range = "80"
}

# Additional Storage Buckets for different data types
resource "google_storage_bucket" "audit_logs" {
  name     = "${var.project_id}-digital-asset-trading-platform-audit-logs"
  location = var.region

  uniform_bucket_level_access = true
}

resource "google_storage_bucket" "trade_records" {
  name     = "${var.project_id}-digital-asset-trading-platform-trade-records"
  location = var.region

  retention_policy {
    retention_period = 31536000
  }
}