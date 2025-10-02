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
resource "google_compute_network" "ecommerce_analytics_vpc" {
  name                    = "e-commerce-real-time-analytics-platform-vpc-main"
  auto_create_subnetworks = false
  description             = "VPC for e-commerce analytics platform"
}

# Public subnet for ingestion gateway
resource "google_compute_subnetwork" "public_subnet" {
  name          = "e-commerce-real-time-analytics-platform-subnet-public"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.ecommerce_analytics_vpc.id
  description   = "Public subnet for data ingestion gateway"
}

# Private subnet for processing components
resource "google_compute_subnetwork" "private_subnet" {
  name          = "e-commerce-real-time-analytics-platform-subnet-private"
  ip_cidr_range = "10.0.2.0/24"
  region        = var.region
  network       = google_compute_network.ecommerce_analytics_vpc.id
  description   = "Private subnet for analytics processing"
}

# Data subnet for databases
resource "google_compute_subnetwork" "data_subnet" {
  name          = "e-commerce-real-time-analytics-platform-subnet-data"
  ip_cidr_range = "10.0.3.0/24"
  region        = var.region
  network       = google_compute_network.ecommerce_analytics_vpc.id
  description   = "Data subnet for databases and storage"
}

# Cloud NAT for private subnet internet access
resource "google_compute_router" "analytics_router" {
  name    = "e-commerce-real-time-analytics-platform-router-main"
  region  = var.region
  network = google_compute_network.ecommerce_analytics_vpc.id
}

resource "google_compute_router_nat" "analytics_nat" {
  name                               = "e-commerce-real-time-analytics-platform-nat-gateway"
  router                            = google_compute_router.analytics_router.name
  region                            = var.region
  nat_ip_allocate_option            = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Firewall rules
resource "google_compute_firewall" "allow_ingestion" {
  name    = "e-commerce-real-time-analytics-platform-firewall-ingestion"
  network = google_compute_network.ecommerce_analytics_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "8080"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ingestion-gateway"]
}

resource "google_compute_firewall" "allow_internal" {
  name    = "e-commerce-real-time-analytics-platform-firewall-internal"
  network = google_compute_network.ecommerce_analytics_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "5432", "3306"]
  }

  source_ranges = ["10.0.0.0/16"]
  target_tags   = ["internal"]
}

# Service account for analytics processor
resource "google_service_account" "analytics_processor_sa" {
  account_id   = "analytics-processor"
  display_name = "Analytics Processor Service Account"
  description  = "Service account for Cloud Functions analytics processor"
}

# IAM binding with default service account (vulnerability)
resource "google_project_iam_member" "processor_permissions" {
  project = var.project_id
  role    = "roles/editor"
  member  = "${var.project_id}-compute@developer.gserviceaccount.com"
}

# Pub/Sub topic for event streaming
resource "google_pubsub_topic" "event_streaming_pipeline" {
  name = "e-commerce-real-time-analytics-platform-pubsub-events"
  
  message_storage_policy {
    allowed_persistence_regions = [var.region]
  }
}

resource "google_pubsub_subscription" "analytics_processor_sub" {
  name  = "e-commerce-real-time-analytics-platform-subscription-processor"
  topic = google_pubsub_topic.event_streaming_pipeline.name

  ack_deadline_seconds = 20
  
  retry_policy {
    minimum_backoff = "10s"
    maximum_backoff = "600s"
  }
}

# Cloud Storage bucket for function source code
resource "google_storage_bucket" "function_source" {
  name     = "${var.project_id}-analytics-function-source"
  location = var.region
  
  uniform_bucket_level_access = true
  
  versioning {
    enabled = true
  }
}

resource "google_storage_bucket_object" "function_zip" {
  name   = "analytics-processor.zip"
  bucket = google_storage_bucket.function_source.name
  source = "analytics-processor.zip"
}

# Cloud Function for analytics processing
resource "google_cloudfunctions_function" "analytics_processor" {
  name        = "e-commerce-real-time-analytics-platform-function-processor"
  description = "Processes streaming data for real-time analytics"
  runtime     = "python39"
  region      = var.region

  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.function_source.name
  source_archive_object = google_storage_bucket_object.function_zip.name
  entry_point          = "process_analytics"

  event_trigger {
    event_type = "providers/cloud.pubsub/eventTypes/topic.publish"
    resource   = google_pubsub_topic.event_streaming_pipeline.name
  }

  environment_variables = {
    DATABASE_URL = "postgresql://${google_sql_user.analytics_user.name}:${var.db_password}@${google_sql_database_instance.analytics_database.connection_name}/${google_sql_database.analytics_db.name}"
    PROJECT_ID   = var.project_id
  }
}

# Cloud SQL instance for analytics database
resource "google_sql_database_instance" "analytics_database" {
  name             = "e-commerce-real-time-analytics-platform-sql-analytics"
  database_version = "POSTGRES_13"
  region           = var.region

  settings {
    tier = "db-f1-micro"
    
    ip_configuration {
      ipv4_enabled = true
      authorized_networks {
        value = "0.0.0.0/0"
        name  = "internet"
      }
      authorized_networks {
        value = "10.0.0.0/16"
        name  = "internal"
      }
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

  deletion_protection = false
}

resource "google_sql_database" "analytics_db" {
  name     = "analytics"
  instance = google_sql_database_instance.analytics_database.name
}

resource "google_sql_user" "analytics_user" {
  name     = "analytics_user"
  instance = google_sql_database_instance.analytics_database.name
  password = var.db_password
}

# BigQuery dataset for data warehouse
resource "google_bigquery_dataset" "data_warehouse" {
  dataset_id  = "e_commerce_analytics_warehouse"
  description = "Data warehouse for long-term analytics storage"
  location    = var.region

  access {
    role          = "OWNER"
    user_by_email = var.admin_email
  }

  access {
    role   = "READER"
    domain = var.organization_domain
  }
}

resource "google_bigquery_table" "customer_analytics" {
  dataset_id = google_bigquery_dataset.data_warehouse.dataset_id
  table_id   = "customer_analytics"

  schema = jsonencode([
    {
      name = "customer_id"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "event_timestamp"
      type = "TIMESTAMP"
      mode = "REQUIRED"
    },
    {
      name = "event_type"
      type = "STRING"
      mode = "REQUIRED"
    },
    {
      name = "product_id"
      type = "STRING"
      mode = "NULLABLE"
    },
    {
      name = "revenue"
      type = "FLOAT"
      mode = "NULLABLE"
    }
  ])
}

# Compute instance for dashboard application
resource "google_compute_instance" "dashboard_application" {
  name         = "e-commerce-real-time-analytics-platform-vm-dashboard"
  machine_type = "e2-medium"
  zone         = var.zone

  tags = ["internal", "dashboard"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
      size  = 20
    }
  }

  network_interface {
    network    = google_compute_network.ecommerce_analytics_vpc.name
    subnetwork = google_compute_subnetwork.private_subnet.name
  }

  metadata = {
    enable-oslogin     = false
    serial-port-enable = true
    startup-script     = file("${path.module}/dashboard-startup.sh")
  }

  shielded_instance_config {
    enable_integrity_monitoring = false
    enable_secure_boot          = true
    enable_vtpm                 = true
  }

  service_account {
    email  = google_service_account.analytics_processor_sa.email
    scopes = ["cloud-platform"]
  }
}

# Cloud Run service for data ingestion gateway
resource "google_cloud_run_service" "data_ingestion_gateway" {
  name     = "e-commerce-real-time-analytics-platform-run-ingestion"
  location = var.region

  template {
    spec {
      containers {
        image = "gcr.io/${var.project_id}/ingestion-gateway:latest"
        
        ports {
          container_port = 8080
        }

        env {
          name  = "PUBSUB_TOPIC"
          value = google_pubsub_topic.event_streaming_pipeline.name
        }

        env {
          name  = "PROJECT_ID"
          value = var.project_id
        }

        resources {
          limits = {
            cpu    = "1000m"
            memory = "512Mi"
          }
        }
      }

      service_account_name = google_service_account.analytics_processor_sa.email
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

# VPC Access Connector for Cloud Run
resource "google_vpc_access_connector" "connector" {
  name          = "analytics-connector"
  ip_cidr_range = "10.8.0.0/28"
  network       = google_compute_network.ecommerce_analytics_vpc.name
  region        = var.region
}

# Cloud Run IAM
resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_service.data_ingestion_gateway.name
  location = google_cloud_run_service.data_ingestion_gateway.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}