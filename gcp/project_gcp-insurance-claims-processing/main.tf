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
resource "google_compute_network" "claims_vpc" {
  name                    = "insurance-claims-processing-platform-vpc-main"
  auto_create_subnetworks = false
  description             = "VPC for insurance claims processing platform"
}

# Public subnet for API Gateway
resource "google_compute_subnetwork" "public_subnet" {
  name          = "insurance-claims-processing-platform-subnet-public"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.claims_vpc.id
  description   = "Public subnet for API gateway and load balancers"
}

# Private subnet for application servers
resource "google_compute_subnetwork" "private_subnet" {
  name          = "insurance-claims-processing-platform-subnet-private"
  ip_cidr_range = "10.0.2.0/24"
  region        = var.region
  network       = google_compute_network.claims_vpc.id
  description   = "Private subnet for claims processing engine"
  
  private_ip_google_access = true
}

# Data subnet for database
resource "google_compute_subnetwork" "data_subnet" {
  name          = "insurance-claims-processing-platform-subnet-data"
  ip_cidr_range = "10.0.3.0/24"
  region        = var.region
  network       = google_compute_network.claims_vpc.id
  description   = "Data subnet for Cloud SQL database"
  
  private_ip_google_access = true
}

# NAT Gateway for outbound internet access
resource "google_compute_router" "claims_router" {
  name    = "insurance-claims-processing-platform-router-nat"
  region  = var.region
  network = google_compute_network.claims_vpc.id
}

resource "google_compute_router_nat" "claims_nat" {
  name                               = "insurance-claims-processing-platform-nat-gateway"
  router                            = google_compute_router.claims_router.name
  region                            = var.region
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Firewall rule with vulnerability - allows unrestricted public access
resource "google_compute_firewall" "allow_http_https" {
  name    = "insurance-claims-processing-platform-firewall-web"
  network = google_compute_network.claims_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
  description   = "Allow HTTP and HTTPS traffic"
}

# Claims Document Storage Bucket
resource "google_storage_bucket" "claims_documents" {
  name          = "insurance-claims-processing-platform-storage-documents-${random_id.bucket_suffix.hex}"
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

  logging {
    log_bucket = google_storage_bucket.audit_logs.name
  }
}

# Audit logs storage bucket
resource "google_storage_bucket" "audit_logs" {
  name          = "insurance-claims-processing-platform-storage-audit-${random_id.bucket_suffix.hex}"
  location      = var.region
  force_destroy = true

  versioning {
    enabled = true
  }
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Claims Database (Cloud SQL PostgreSQL)
resource "google_sql_database_instance" "claims_database" {
  name             = "insurance-claims-processing-platform-database-main"
  database_version = "POSTGRES_14"
  region           = var.region
  deletion_protection = false

  settings {
    tier = "db-f1-micro"
    
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.claims_vpc.id
      require_ssl     = true
    }

    backup_configuration {
      enabled = true
      start_time = "03:00"
      backup_retention_settings {
        retained_backups = 7
      }
    }

    # Vulnerability - PostgreSQL logging issues
    database_flags {
      name  = "log_lock_waits"
      value = "off"
    }

    database_flags {
      name  = "log_min_messages"
      value = "PANIC"
    }
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

resource "google_sql_database" "claims_db" {
  name     = "claims_processing"
  instance = google_sql_database_instance.claims_database.name
}

# Private service networking for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  name          = "insurance-claims-processing-platform-ip-private"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.claims_vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.claims_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# Claims Processing Engine (Compute Instance)
resource "google_compute_instance" "claims_processing_engine" {
  name         = "insurance-claims-processing-platform-compute-engine"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
      type  = "pd-standard"
    }
    # Vulnerability - no customer-managed encryption key
  }

  network_interface {
    network    = google_compute_network.claims_vpc.id
    subnetwork = google_compute_subnetwork.private_subnet.id
  }

  # Vulnerability - using default service account
  service_account {
    email  = "${var.project_number}-compute@developer.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  tags = ["claims-processor"]

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl start nginx
    systemctl enable nginx
  EOF
}

# Document Analysis Function (Cloud Function)
resource "google_storage_bucket" "function_source" {
  name          = "insurance-claims-processing-platform-storage-functions-${random_id.bucket_suffix.hex}"
  location      = var.region
  force_destroy = true
}

resource "google_storage_bucket_object" "function_zip" {
  name   = "document-analysis-function.zip"
  bucket = google_storage_bucket.function_source.name
  source = "function-source.zip"
}

resource "google_cloudfunctions_function" "document_analysis" {
  name        = "insurance-claims-processing-platform-function-analysis"
  description = "Document analysis and OCR processing function"
  runtime     = "python39"
  region      = var.region

  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.function_source.name
  source_archive_object = google_storage_bucket_object.function_zip.name
  trigger {
    event_type = "google.storage.object.finalize"
    resource   = google_storage_bucket.claims_documents.name
  }
  timeout     = 60
  entry_point = "analyze_document"

  environment_variables = {
    DATABASE_URL = "postgresql://user:pass@${google_sql_database_instance.claims_database.private_ip_address}:5432/claims_processing"
  }
}

# Fraud Detection Service (Cloud Run)
resource "google_cloud_run_service" "fraud_detection" {
  name     = "insurance-claims-processing-platform-run-fraud"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/cloudrun/hello"
        
        env {
          name  = "DATABASE_URL"
          value = "postgresql://user:pass@${google_sql_database_instance.claims_database.private_ip_address}:5432/claims_processing"
        }

        resources {
          limits = {
            cpu    = "1000m"
            memory = "512Mi"
          }
        }
      }
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = "10"
        "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.connector.name
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# VPC Connector for Cloud Run
resource "google_vpc_access_connector" "connector" {
  name          = "insurance-claims-processing-platform-connector-vpc"
  ip_cidr_range = "10.8.0.0/28"
  network       = google_compute_network.claims_vpc.name
  region        = var.region
}

# Notification Queue (Pub/Sub)
resource "google_pubsub_topic" "notification_queue" {
  name = "insurance-claims-processing-platform-pubsub-notifications"

  labels = {
    environment = "production"
    component   = "notifications"
  }
}

resource "google_pubsub_subscription" "notification_subscription" {
  name  = "insurance-claims-processing-platform-pubsub-sub"
  topic = google_pubsub_topic.notification_queue.name

  message_retention_duration = "604800s"
  retain_acked_messages      = true
  ack_deadline_seconds       = 20

  expiration_policy {
    ttl = "300000.5s"
  }
}

# Load Balancer for API Gateway
resource "google_compute_global_address" "api_gateway_ip" {
  name = "insurance-claims-processing-platform-ip-gateway"
}

# SSL Policy with vulnerability - weak TLS version
resource "google_compute_ssl_policy" "api_ssl_policy" {
  name            = "insurance-claims-processing-platform-ssl-policy"
  profile         = "MODERN"
  min_tls_version = "TLS_1_1"
}

# IAM with vulnerability - direct user permissions
resource "google_project_iam_member" "claims_processor_access" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "user:claims-processor@${var.domain}"
}

resource "google_project_iam_member" "database_user_access" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "user:database-admin@${var.domain}"
}