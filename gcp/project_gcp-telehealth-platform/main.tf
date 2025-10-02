terraform {
  required_version = ">= 1.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# VPC Network
resource "google_compute_network" "telehealth_vpc" {
  name                    = "telehealth-video-consultation-platform-vpc-main"
  auto_create_subnetworks = false
  routing_mode           = "REGIONAL"
}

# Public subnet for load balancer
resource "google_compute_subnetwork" "public_subnet" {
  name          = "telehealth-video-consultation-platform-subnet-public"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.telehealth_vpc.id
}

# Private subnet for application tier
resource "google_compute_subnetwork" "private_subnet" {
  name                     = "telehealth-video-consultation-platform-subnet-private"
  ip_cidr_range           = "10.0.2.0/24"
  region                  = var.region
  network                 = google_compute_network.telehealth_vpc.id
  private_ip_google_access = true
}

# Data subnet for database
resource "google_compute_subnetwork" "data_subnet" {
  name                     = "telehealth-video-consultation-platform-subnet-data"
  ip_cidr_range           = "10.0.3.0/24"
  region                  = var.region
  network                 = google_compute_network.telehealth_vpc.id
  private_ip_google_access = true
}

# Cloud NAT Router
resource "google_compute_router" "nat_router" {
  name    = "telehealth-video-consultation-platform-router-nat"
  region  = var.region
  network = google_compute_network.telehealth_vpc.id
}

# Cloud NAT Gateway
resource "google_compute_router_nat" "nat_gateway" {
  name                               = "telehealth-video-consultation-platform-nat-gateway"
  router                            = google_compute_router.nat_router.name
  region                            = var.region
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Firewall rule for patient portal - VULNERABLE: allows public access
resource "google_compute_firewall" "patient_portal_firewall" {
  name    = "telehealth-video-consultation-platform-firewall-portal"
  network = google_compute_network.telehealth_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["patient-portal"]
}

# Firewall rule for internal communication
resource "google_compute_firewall" "internal_firewall" {
  name    = "telehealth-video-consultation-platform-firewall-internal"
  network = google_compute_network.telehealth_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["8080", "5432"]
  }

  source_ranges = ["10.0.0.0/16"]
  target_tags   = ["internal"]
}

# Instance template for patient portal
resource "google_compute_instance_template" "patient_portal_template" {
  name         = "telehealth-video-consultation-platform-template-portal"
  machine_type = "e2-medium"

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = google_compute_subnetwork.private_subnet.id
    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    startup-script = "#!/bin/bash\napt-get update\napt-get install -y nginx\nsystemctl start nginx"
    # VULNERABLE: allows project-wide SSH keys
    block-project-ssh-keys = false
  }

  tags = ["patient-portal", "internal"]

  # VULNERABLE: vTPM disabled
  shielded_instance_config {
    enable_vtpm = false
  }
}

# Managed instance group for patient portal
resource "google_compute_instance_group_manager" "patient_portal_app" {
  name = "telehealth-video-consultation-platform-ig-portal"
  zone = var.zone

  version {
    instance_template = google_compute_instance_template.patient_portal_template.id
  }

  base_instance_name = "patient-portal"
  target_size        = 2

  named_port {
    name = "http"
    port = 80
  }
}

# Service account for Cloud Run services - VULNERABLE: excessive permissions
resource "google_service_account" "appointment_api_sa" {
  account_id   = "appointment-api-sa"
  display_name = "Appointment API Service Account"
}

resource "google_project_iam_member" "appointment_api_permissions" {
  project = var.project_id
  # VULNERABLE: overly broad permissions
  role   = "roles/owner"
  member = "serviceAccount:${google_service_account.appointment_api_sa.email}"
}

# Cloud Run service for appointment API
resource "google_cloud_run_service" "appointment_api" {
  name     = "telehealth-video-consultation-platform-cloudrun-appointment"
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
          value = "postgresql://${google_sql_user.app_user.name}:${google_sql_user.app_user.password}@${google_sql_database_instance.patient_database.connection_name}/patients"
        }
      }
      service_account_name = google_service_account.appointment_api_sa.email
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Service account for video service
resource "google_service_account" "video_service_sa" {
  account_id   = "video-service-sa"
  display_name = "Video Service Service Account"
}

resource "google_project_iam_member" "video_service_permissions" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.video_service_sa.email}"
}

# Cloud Run service for video service
resource "google_cloud_run_service" "video_service" {
  name     = "telehealth-video-consultation-platform-cloudrun-video"
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
          value = "postgresql://${google_sql_user.app_user.name}:${google_sql_user.app_user.password}@${google_sql_database_instance.patient_database.connection_name}/patients"
        }
        env {
          name  = "STORAGE_BUCKET"
          value = google_storage_bucket.medical_records_storage.name
        }
      }
      service_account_name = google_service_account.video_service_sa.email
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Database instance - VULNERABLE: SSL not required and logging disabled
resource "google_sql_database_instance" "patient_database" {
  name             = "telehealth-video-consultation-platform-db-patients"
  database_version = "POSTGRES_14"
  region          = var.region

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.telehealth_vpc.id
      # VULNERABLE: SSL not required
      require_ssl = false
    }

    backup_configuration {
      enabled = true
      start_time = "03:00"
    }

    # VULNERABLE: disconnection logging disabled
    database_flags {
      name  = "log_disconnections"
      value = "off"
    }
  }

  deletion_protection = false
}

# Database
resource "google_sql_database" "patients_db" {
  name     = "patients"
  instance = google_sql_database_instance.patient_database.name
}

# Database user
resource "google_sql_user" "app_user" {
  name     = "app_user"
  instance = google_sql_database_instance.patient_database.name
  password = var.db_password
}

# Private VPC connection for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  name          = "telehealth-video-consultation-platform-ip-private"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.telehealth_vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.telehealth_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# Storage bucket for medical records
resource "google_storage_bucket" "medical_records_storage" {
  name     = "telehealth-video-consultation-platform-bucket-records-${random_id.bucket_suffix.hex}"
  location = var.region

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 2555 # 7 years for HIPAA compliance
    }
    action {
      type = "Delete"
    }
  }

  uniform_bucket_level_access = true
}

resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# Audit logging bucket
resource "google_storage_bucket" "audit_logs_bucket" {
  name     = "telehealth-video-consultation-platform-bucket-audit-${random_id.audit_suffix.hex}"
  location = var.region

  versioning {
    enabled = true
  }

  uniform_bucket_level_access = true
}

resource "random_id" "audit_suffix" {
  byte_length = 8
}

# Logging sink for audit logging
resource "google_logging_project_sink" "audit_logging" {
  name        = "telehealth-video-consultation-platform-sink-audit"
  destination = "storage.googleapis.com/${google_storage_bucket.audit_logs_bucket.name}"

  filter = "protoPayload.serviceName=\"cloudsql.googleapis.com\" OR protoPayload.serviceName=\"storage.googleapis.com\" OR protoPayload.serviceName=\"run.googleapis.com\""

  unique_writer_identity = true
}

# Grant the logging sink permission to write to the bucket
resource "google_storage_bucket_iam_member" "audit_log_writer" {
  bucket = google_storage_bucket.audit_logs_bucket.name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.audit_logging.writer_identity
}

# DNS managed zone - VULNERABLE: DNSSEC disabled
resource "google_dns_managed_zone" "telehealth_zone" {
  name     = "telehealth-video-consultation-platform-dns-main"
  dns_name = "${var.domain_name}."

  # VULNERABLE: DNSSEC disabled
  dnssec_config {
    state = "off"
  }
}

# Load balancer for patient portal
resource "google_compute_global_address" "lb_ip" {
  name = "telehealth-video-consultation-platform-ip-lb"
}

resource "google_compute_health_check" "portal_health_check" {
  name = "telehealth-video-consultation-platform-hc-portal"

  http_health_check {
    port = 80
    request_path = "/"
  }
}

resource "google_compute_backend_service" "portal_backend" {
  name        = "telehealth-video-consultation-platform-backend-portal"
  protocol    = "HTTP"
  timeout_sec = 30

  backend {
    group = google_compute_instance_group_manager.patient_portal_app.instance_group
  }

  health_checks = [google_compute_health_check.portal_health_check.id]
}

resource "google_compute_url_map" "portal_url_map" {
  name            = "telehealth-video-consultation-platform-urlmap-portal"
  default_service = google_compute_backend_service.portal_backend.id
}

resource "google_compute_target_http_proxy" "portal_proxy" {
  name    = "telehealth-video-consultation-platform-proxy-portal"
  url_map = google_compute_url_map.portal_url_map.id
}

resource "google_compute_global_forwarding_rule" "portal_forwarding_rule" {
  name       = "telehealth-video-consultation-platform-fwd-portal"
  target     = google_compute_target_http_proxy.portal_proxy.id
  port_range = "80"
  ip_address = google_compute_global_address.lb_ip.address
}