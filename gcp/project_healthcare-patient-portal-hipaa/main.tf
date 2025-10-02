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
resource "google_compute_network" "hipaa_vpc" {
  name                    = "hipaa-compliant-patient-portal-vpc-main"
  auto_create_subnetworks = false
  description             = "VPC for HIPAA compliant patient portal"
}

# Public subnet for load balancer
resource "google_compute_subnetwork" "public_subnet" {
  name                     = "hipaa-compliant-patient-portal-subnet-public"
  ip_cidr_range            = "10.0.1.0/24"
  region                   = var.region
  network                  = google_compute_network.hipaa_vpc.id
  private_ip_google_access = false  # VULNERABILITY: Missing Private Google Access
}

# Private subnet for web frontend
resource "google_compute_subnetwork" "private_subnet" {
  name                     = "hipaa-compliant-patient-portal-subnet-private"
  ip_cidr_range            = "10.0.2.0/24"
  region                   = var.region
  network                  = google_compute_network.hipaa_vpc.id
  private_ip_google_access = true
}

# Data subnet for database
resource "google_compute_subnetwork" "data_subnet" {
  name                     = "hipaa-compliant-patient-portal-subnet-data"
  ip_cidr_range            = "10.0.3.0/24"
  region                   = var.region
  network                  = google_compute_network.hipaa_vpc.id
  private_ip_google_access = true
}

# Firewall rule - VULNERABILITY: Allows all ports
resource "google_compute_firewall" "allow_web_traffic" {
  name    = "hipaa-compliant-patient-portal-firewall-web"
  network = google_compute_network.hipaa_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]  # VULNERABILITY: All ports open
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

# Firewall rule for internal communication
resource "google_compute_firewall" "allow_internal" {
  name    = "hipaa-compliant-patient-portal-firewall-internal"
  network = google_compute_network.hipaa_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "5432"]
  }

  source_ranges = ["10.0.0.0/16"]
  target_tags   = ["web-server", "api-server", "database"]
}

# KMS Key Ring
resource "google_kms_key_ring" "hipaa_keyring" {
  name     = "hipaa-compliant-patient-portal-keyring"
  location = var.region
}

# KMS Crypto Key for encryption
resource "google_kms_crypto_key" "hipaa_key" {
  name     = "hipaa-compliant-patient-portal-key-encryption"
  key_ring = google_kms_key_ring.hipaa_keyring.id
  purpose  = "ENCRYPT_DECRYPT"

  version_template {
    algorithm = "GOOGLE_SYMMETRIC_ENCRYPTION"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Service Account for compute instances - VULNERABILITY: Will use default service account
resource "google_service_account" "app_service_account" {
  account_id   = "hipaa-portal-app-sa"
  display_name = "HIPAA Portal Application Service Account"
  description  = "Service account for patient portal application"
}

# IAM binding - VULNERABILITY: Excessive privileges
resource "google_project_iam_member" "app_sa_binding" {
  project = var.project_id
  role    = "roles/owner"  # VULNERABILITY: Overprivileged service account
  member  = "serviceAccount:${google_service_account.app_service_account.email}"
}

# Instance template for web frontend
resource "google_compute_instance_template" "web_template" {
  name         = "hipaa-compliant-patient-portal-template-web"
  machine_type = "e2-medium"
  region       = var.region

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
    disk_size_gb = 20
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private_subnet.id
  }

  service_account {
    email  = "${var.project_number}-compute@developer.gserviceaccount.com"  # VULNERABILITY: Using default service account
    scopes = ["cloud-platform"]
  }

  tags = ["web-server"]

  # VULNERABILITY: Missing shielded VM configuration
  metadata_startup_script = "apt-get update && apt-get install -y nginx"
}

# Instance template for API backend
resource "google_compute_instance_template" "api_template" {
  name         = "hipaa-compliant-patient-portal-template-api"
  machine_type = "e2-medium"
  region       = var.region

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
    disk_size_gb = 20
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private_subnet.id
  }

  service_account {
    email  = google_service_account.app_service_account.email
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_secure_boot = false  # VULNERABILITY: Secure boot disabled
  }

  tags = ["api-server"]

  metadata_startup_script = "apt-get update && apt-get install -y nodejs npm"
}

# Managed instance group for web frontend
resource "google_compute_region_instance_group_manager" "web_frontend" {
  name   = "hipaa-compliant-patient-portal-mig-web"
  region = var.region

  version {
    instance_template = google_compute_instance_template.web_template.id
  }

  base_instance_name = "web-frontend"
  target_size        = 2

  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.web_health_check.id
    initial_delay_sec = 300
  }
}

# Managed instance group for API backend
resource "google_compute_region_instance_group_manager" "api_backend" {
  name   = "hipaa-compliant-patient-portal-mig-api"
  region = var.region

  version {
    instance_template = google_compute_instance_template.api_template.id
  }

  base_instance_name = "api-backend"
  target_size        = 2

  named_port {
    name = "http"
    port = 3000
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.api_health_check.id
    initial_delay_sec = 300
  }
}

# Health check for web frontend
resource "google_compute_health_check" "web_health_check" {
  name = "hipaa-compliant-patient-portal-health-web"

  http_health_check {
    port = 80
    path = "/"
  }

  check_interval_sec  = 30
  timeout_sec         = 10
  healthy_threshold   = 2
  unhealthy_threshold = 3
}

# Health check for API backend
resource "google_compute_health_check" "api_health_check" {
  name = "hipaa-compliant-patient-portal-health-api"

  http_health_check {
    port = 3000
    path = "/health"
  }

  check_interval_sec  = 30
  timeout_sec         = 10
  healthy_threshold   = 2
  unhealthy_threshold = 3
}

# Backend service for load balancer
resource "google_compute_backend_service" "web_backend" {
  name        = "hipaa-compliant-patient-portal-backend-web"
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 30

  backend {
    group = google_compute_region_instance_group_manager.web_frontend.instance_group
  }

  health_checks = [google_compute_health_check.web_health_check.id]
}

# URL map for load balancer
resource "google_compute_url_map" "web_url_map" {
  name            = "hipaa-compliant-patient-portal-urlmap"
  default_service = google_compute_backend_service.web_backend.id
}

# HTTP proxy
resource "google_compute_target_http_proxy" "web_proxy" {
  name    = "hipaa-compliant-patient-portal-proxy"
  url_map = google_compute_url_map.web_url_map.id
}

# Global forwarding rule (load balancer)
resource "google_compute_global_forwarding_rule" "load_balancer" {
  name       = "hipaa-compliant-patient-portal-lb-main"
  target     = google_compute_target_http_proxy.web_proxy.id
  port_range = "80"
}

# Cloud SQL instance for patient database
resource "google_sql_database_instance" "patient_database" {
  name             = "hipaa-compliant-patient-portal-db-main"
  database_version = "POSTGRES_14"
  region           = var.region

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.hipaa_vpc.id
      require_ssl     = false  # VULNERABILITY: SSL not required
    }

    database_flags {
      name  = "log_lock_waits"
      value = "off"  # VULNERABILITY: Lock wait logging disabled
    }

    backup_configuration {
      enabled    = true
      start_time = "03:00"
    }

    disk_encryption_key_name = google_kms_crypto_key.hipaa_key.id
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# Private service connection for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  name          = "hipaa-compliant-patient-portal-ip-private"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.hipaa_vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.hipaa_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# Cloud Storage bucket for document storage
resource "google_storage_bucket" "document_storage" {
  name          = "hipaa-compliant-patient-portal-docs-${random_string.bucket_suffix.result}"
  location      = var.region
  force_destroy = false

  encryption {
    default_kms_key_name = google_kms_crypto_key.hipaa_key.id
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

# Random string for bucket naming
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Logging sink for audit logging
resource "google_logging_project_sink" "audit_logging" {
  name        = "hipaa-compliant-patient-portal-sink-audit"
  destination = "storage.googleapis.com/${google_storage_bucket.audit_logs.name}"

  filter = "protoPayload.serviceName=\"compute.googleapis.com\" OR protoPayload.serviceName=\"sqladmin.googleapis.com\" OR protoPayload.serviceName=\"storage.googleapis.com\""

  unique_writer_identity = true
}

# Storage bucket for audit logs
resource "google_storage_bucket" "audit_logs" {
  name          = "hipaa-compliant-patient-portal-audit-${random_string.audit_suffix.result}"
  location      = var.region
  force_destroy = false

  encryption {
    default_kms_key_name = google_kms_crypto_key.hipaa_key.id
  }

  lifecycle_rule {
    condition {
      age = 2555  # 7 years retention for HIPAA
    }
    action {
      type = "Delete"
    }
  }
}

resource "random_string" "audit_suffix" {
  length  = 8
  special = false
  upper   = false
}