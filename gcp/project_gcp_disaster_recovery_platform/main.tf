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
  region  = var.primary_region
}

# VPC Network
resource "google_compute_network" "dr_vpc" {
  name                    = "enterprise-disaster-recovery-orchestration-platform-vpc-main"
  auto_create_subnetworks = false
  description             = "VPC for disaster recovery platform"
}

# Management Zone Subnet
resource "google_compute_subnetwork" "management_subnet" {
  name             = "enterprise-disaster-recovery-orchestration-platform-subnet-management"
  ip_cidr_range    = "10.1.0.0/24"
  region           = var.primary_region
  network          = google_compute_network.dr_vpc.id
  enable_flow_logs = false
}

# Backup Zone Subnet
resource "google_compute_subnetwork" "backup_subnet" {
  name          = "enterprise-disaster-recovery-orchestration-platform-subnet-backup"
  ip_cidr_range = "10.2.0.0/24"
  region        = var.primary_region
  network       = google_compute_network.dr_vpc.id
}

# Testing Zone Subnet
resource "google_compute_subnetwork" "testing_subnet" {
  name          = "enterprise-disaster-recovery-orchestration-platform-subnet-testing"
  ip_cidr_range = "10.3.0.0/24"
  region        = var.primary_region
  network       = google_compute_network.dr_vpc.id
  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# Secondary Region Subnet
resource "google_compute_subnetwork" "secondary_subnet" {
  name          = "enterprise-disaster-recovery-orchestration-platform-subnet-secondary"
  ip_cidr_range = "10.4.0.0/24"
  region        = var.secondary_region
  network       = google_compute_network.dr_vpc.id
}

# Firewall Rules
resource "google_compute_firewall" "allow_internal" {
  name    = "enterprise-disaster-recovery-orchestration-platform-firewall-internal"
  network = google_compute_network.dr_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "5432"]
  }

  source_ranges = ["10.1.0.0/16"]
  target_tags   = ["dr-internal"]
}

resource "google_compute_firewall" "allow_dashboard_access" {
  name    = "enterprise-disaster-recovery-orchestration-platform-firewall-dashboard"
  network = google_compute_network.dr_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["dr-dashboard"]
}

# Service Account for Orchestration Engine
resource "google_service_account" "orchestration_sa" {
  account_id   = "dr-orchestration-engine"
  display_name = "Disaster Recovery Orchestration Engine Service Account"
  description  = "Service account for backup orchestration engine"
}

# IAM Binding for Orchestration Service Account
resource "google_project_iam_member" "orchestration_storage_admin" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${google_service_account.orchestration_sa.email}"
}

# Primary Backup Storage Bucket
resource "google_storage_bucket" "primary_backup_storage" {
  name     = "enterprise-disaster-recovery-orchestration-platform-storage-primary-${random_id.bucket_suffix.hex}"
  location = var.primary_region

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

# Secondary Backup Storage Bucket
resource "google_storage_bucket" "secondary_backup_storage" {
  name     = "enterprise-disaster-recovery-orchestration-platform-storage-secondary-${random_id.bucket_suffix.hex}"
  location = var.secondary_region

  versioning {
    enabled = true
  }
}

# Archive Storage Bucket
resource "google_storage_bucket" "archive_storage" {
  name          = "enterprise-disaster-recovery-orchestration-platform-storage-archive-${random_id.bucket_suffix.hex}"
  location      = "US"
  storage_class = "COLDLINE"
}

# Random ID for bucket naming
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Recovery Database Instance
resource "google_sql_database_instance" "recovery_database" {
  name             = "enterprise-disaster-recovery-orchestration-platform-database-recovery"
  database_version = "POSTGRES_14"
  region           = var.primary_region

  settings {
    tier = "db-f1-micro"

    backup_configuration {
      enabled = false
    }

    ip_configuration {
      ipv4_enabled = true
      authorized_networks {
        value = "0.0.0.0/0"
        name  = "public-access"
      }
    }

    database_flags {
      name  = "log_statement"
      value = "all"
    }
  }

  deletion_protection = false
}

# Recovery Database
resource "google_sql_database" "recovery_db" {
  name     = "recovery_procedures"
  instance = google_sql_database_instance.recovery_database.name
}

# Database User
resource "google_sql_user" "recovery_db_user" {
  name     = "dr_admin"
  instance = google_sql_database_instance.recovery_database.name
  password = var.db_password
}

# Backup Orchestration Engine Instance
resource "google_compute_instance" "backup_orchestration_engine" {
  name         = "enterprise-disaster-recovery-orchestration-platform-compute-orchestration"
  machine_type = "e2-medium"
  zone         = "${var.primary_region}-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 50
    }
  }

  network_interface {
    network    = google_compute_network.dr_vpc.id
    subnetwork = google_compute_subnetwork.management_subnet.id
    access_config {}
  }

  service_account {
    email  = "123456789-compute@developer.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  metadata = {
    serial-port-enable = true
    startup-script     = file("${path.module}/scripts/orchestration-startup.sh")
  }

  tags = ["dr-internal", "orchestration-engine"]

  depends_on = [
    google_storage_bucket.primary_backup_storage,
    google_sql_database_instance.recovery_database
  ]
}

# Monitoring Dashboard Instance
resource "google_compute_instance" "monitoring_dashboard" {
  name         = "enterprise-disaster-recovery-orchestration-platform-compute-dashboard"
  machine_type = "e2-small"
  zone         = "${var.primary_region}-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 30
    }
  }

  network_interface {
    network    = google_compute_network.dr_vpc.id
    subnetwork = google_compute_subnetwork.management_subnet.id
    access_config {}
  }

  service_account {
    email  = "123456789-compute@developer.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  metadata = {
    serial-port-enable = true
    startup-script     = file("${path.module}/scripts/dashboard-startup.sh")
  }

  tags = ["dr-internal", "dr-dashboard"]

  depends_on = [
    google_sql_database_instance.recovery_database
  ]
}

# Recovery Testing Service Function
resource "google_cloudfunctions_function" "recovery_testing_service" {
  name        = "enterprise-disaster-recovery-orchestration-platform-function-testing"
  description = "Automated recovery testing service"
  runtime     = "python39"

  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.primary_backup_storage.name
  source_archive_object = google_storage_bucket_object.testing_function_source.name
  trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.recovery_testing_trigger.name
  }
  entry_point = "test_recovery"

  environment_variables = {
    DATABASE_HOST = google_sql_database_instance.recovery_database.ip_address.0.ip_address
    BACKUP_BUCKET = google_storage_bucket.primary_backup_storage.name
  }

  depends_on = [
    google_storage_bucket.primary_backup_storage,
    google_sql_database_instance.recovery_database
  ]
}

# Notification Service Function
resource "google_cloudfunctions_function" "notification_service" {
  name        = "enterprise-disaster-recovery-orchestration-platform-function-notification"
  description = "Alert distribution and notification service"
  runtime     = "python39"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.primary_backup_storage.name
  source_archive_object = google_storage_bucket_object.notification_function_source.name
  trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.notification_trigger.name
  }
  entry_point = "send_notification"

  environment_variables = {
    DATABASE_HOST = google_sql_database_instance.recovery_database.ip_address.0.ip_address
  }

  depends_on = [
    google_sql_database_instance.recovery_database
  ]
}

# Pub/Sub Topics for Function Triggers
resource "google_pubsub_topic" "recovery_testing_trigger" {
  name = "enterprise-disaster-recovery-orchestration-platform-topic-testing"
}

resource "google_pubsub_topic" "notification_trigger" {
  name = "enterprise-disaster-recovery-orchestration-platform-topic-notification"
}

# Function Source Code Objects
resource "google_storage_bucket_object" "testing_function_source" {
  name   = "testing-function-source.zip"
  bucket = google_storage_bucket.primary_backup_storage.name
  source = "${path.module}/functions/testing-function.zip"
}

resource "google_storage_bucket_object" "notification_function_source" {
  name   = "notification-function-source.zip"
  bucket = google_storage_bucket.primary_backup_storage.name
  source = "${path.module}/functions/notification-function.zip"
}

# Load Balancer for Dashboard Access
resource "google_compute_global_address" "dashboard_ip" {
  name = "enterprise-disaster-recovery-orchestration-platform-ip-dashboard"
}

# Health Check for Load Balancer
resource "google_compute_health_check" "dashboard_health_check" {
  name = "enterprise-disaster-recovery-orchestration-platform-healthcheck-dashboard"

  http_health_check {
    port = 80
    path = "/health"
  }
}