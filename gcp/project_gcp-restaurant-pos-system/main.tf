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
resource "google_compute_network" "multi_location_restaurant_pos_system_vpc_main" {
  name                    = "multi-location-restaurant-pos-system-vpc-main"
  auto_create_subnetworks = false
  description             = "Main VPC for restaurant POS system"
}

# Public subnet for load balancer
resource "google_compute_subnetwork" "multi_location_restaurant_pos_system_subnet_public" {
  name          = "multi-location-restaurant-pos-system-subnet-public"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.multi_location_restaurant_pos_system_vpc_main.id
  description   = "Public subnet for load balancer"
}

# Private subnet for GKE cluster
resource "google_compute_subnetwork" "multi_location_restaurant_pos_system_subnet_private" {
  name          = "multi-location-restaurant-pos-system-subnet-private"
  ip_cidr_range = "10.0.2.0/24"
  region        = var.region
  network       = google_compute_network.multi_location_restaurant_pos_system_vpc_main.id
  description   = "Private subnet for GKE cluster"

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = "10.1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = "10.2.0.0/16"
  }
}

# Database subnet
resource "google_compute_subnetwork" "multi_location_restaurant_pos_system_subnet_data" {
  name          = "multi-location-restaurant-pos-system-subnet-data"
  ip_cidr_range = "10.0.3.0/24"
  region        = var.region
  network       = google_compute_network.multi_location_restaurant_pos_system_vpc_main.id
  description   = "Database subnet for Cloud SQL"
}

# Cloud Router for NAT
resource "google_compute_router" "multi_location_restaurant_pos_system_router_nat" {
  name    = "multi-location-restaurant-pos-system-router-nat"
  region  = var.region
  network = google_compute_network.multi_location_restaurant_pos_system_vpc_main.id
}

# Cloud NAT
resource "google_compute_router_nat" "multi_location_restaurant_pos_system_nat_gateway" {
  name                               = "multi-location-restaurant-pos-system-nat-gateway"
  router                             = google_compute_router.multi_location_restaurant_pos_system_router_nat.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# GKE Cluster - VULNERABILITY: Private nodes disabled
resource "google_container_cluster" "multi_location_restaurant_pos_system_cluster_pos_application" {
  name     = "multi-location-restaurant-pos-system-cluster-pos-application"
  location = var.region
  network  = google_compute_network.multi_location_restaurant_pos_system_vpc_main.id
  subnetwork = google_compute_subnetwork.multi_location_restaurant_pos_system_subnet_private.id

  # VULNERABILITY: Basic logging instead of Kubernetes logging
  logging_service = "logging.googleapis.com"

  private_cluster_config {
    # VULNERABILITY: Private nodes disabled - exposes nodes to internet
    enable_private_nodes    = false
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.0.0/28"
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  remove_default_node_pool = true
  initial_node_count       = 1

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  depends_on = [
    google_sql_database_instance.multi_location_restaurant_pos_system_database_pos,
    google_storage_bucket.multi_location_restaurant_pos_system_bucket_inventory
  ]
}

# GKE Node Pool - VULNERABILITY: Legacy metadata access
resource "google_container_node_pool" "multi_location_restaurant_pos_system_nodepool_primary" {
  name       = "multi-location-restaurant-pos-system-nodepool-primary"
  location   = var.region
  cluster    = google_container_cluster.multi_location_restaurant_pos_system_cluster_pos_application.name
  node_count = 2

  node_config {
    preemptible  = false
    machine_type = "e2-medium"
    disk_size_gb = 50
    disk_type    = "pd-ssd"

    # VULNERABILITY: Legacy GCE metadata access instead of secure GKE metadata
    workload_metadata_config {
      mode = "GCE_METADATA"
    }

    service_account = google_service_account.multi_location_restaurant_pos_system_sa_gke.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    tags = ["gke-node", "pos-system"]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}

# Cloud SQL Instance - VULNERABILITY: Backups disabled
resource "google_sql_database_instance" "multi_location_restaurant_pos_system_database_pos" {
  name             = "multi-location-restaurant-pos-system-database-pos"
  database_version = "POSTGRES_14"
  region           = var.region
  deletion_protection = false

  settings {
    tier = "db-f1-micro"
    
    # VULNERABILITY: Backups disabled
    backup_configuration {
      enabled = false
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.multi_location_restaurant_pos_system_vpc_main.id
      require_ssl     = true
    }

    database_flags {
      name  = "log_statement"
      value = "all"
    }
  }

  depends_on = [google_service_networking_connection.multi_location_restaurant_pos_system_connection_private_vpc]
}

# Private VPC Connection for Cloud SQL
resource "google_compute_global_address" "multi_location_restaurant_pos_system_address_private_ip" {
  name          = "multi-location-restaurant-pos-system-address-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.multi_location_restaurant_pos_system_vpc_main.id
}

resource "google_service_networking_connection" "multi_location_restaurant_pos_system_connection_private_vpc" {
  network                 = google_compute_network.multi_location_restaurant_pos_system_vpc_main.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.multi_location_restaurant_pos_system_address_private_ip.name]
}

# Cloud SQL Database
resource "google_sql_database" "multi_location_restaurant_pos_system_db_transactions" {
  name     = "pos_transactions"
  instance = google_sql_database_instance.multi_location_restaurant_pos_system_database_pos.name
}

# Storage Bucket for Inventory
resource "google_storage_bucket" "multi_location_restaurant_pos_system_bucket_inventory" {
  name          = "multi-location-restaurant-pos-system-bucket-inventory-${random_id.bucket_suffix.hex}"
  location      = var.region
  force_destroy = true

  versioning {
    enabled = true
  }

  encryption {
    default_kms_key_name = google_kms_crypto_key.multi_location_restaurant_pos_system_key_storage.id
  }
}

# Random ID for bucket naming
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# KMS Key Ring
resource "google_kms_key_ring" "multi_location_restaurant_pos_system_keyring_main" {
  name     = "multi-location-restaurant-pos-system-keyring-main"
  location = var.region
}

# KMS Key for Storage
resource "google_kms_crypto_key" "multi_location_restaurant_pos_system_key_storage" {
  name     = "multi-location-restaurant-pos-system-key-storage"
  key_ring = google_kms_key_ring.multi_location_restaurant_pos_system_keyring_main.id
}

# Service Account for GKE
resource "google_service_account" "multi_location_restaurant_pos_system_sa_gke" {
  account_id   = "pos-system-gke-sa"
  display_name = "POS System GKE Service Account"
  description  = "Service account for GKE cluster nodes"
}

# Service Account for Cloud Functions
resource "google_service_account" "multi_location_restaurant_pos_system_sa_functions" {
  account_id   = "pos-system-functions-sa"
  display_name = "POS System Functions Service Account"
  description  = "Service account for payment processing functions"
}

# Cloud Function for Payment Processing
resource "google_cloudfunctions_function" "multi_location_restaurant_pos_system_function_payment_processor" {
  name        = "multi-location-restaurant-pos-system-function-payment-processor"
  description = "Payment processing function for POS system"
  runtime     = "python39"
  region      = var.region

  available_memory_mb   = 256
  source_archive_bucket = google_storage_bucket.multi_location_restaurant_pos_system_bucket_functions.name
  source_archive_object = google_storage_bucket_object.multi_location_restaurant_pos_system_object_function_source.name
  trigger {
    https_trigger {
      security_level = "SECURE_ALWAYS"
    }
  }
  entry_point = "process_payment"

  service_account_email = google_service_account.multi_location_restaurant_pos_system_sa_functions.email

  vpc_connector = google_vpc_access_connector.multi_location_restaurant_pos_system_connector_vpc.name

  depends_on = [google_sql_database_instance.multi_location_restaurant_pos_system_database_pos]
}

# Storage Bucket for Functions
resource "google_storage_bucket" "multi_location_restaurant_pos_system_bucket_functions" {
  name          = "multi-location-restaurant-pos-system-bucket-functions-${random_id.bucket_suffix.hex}"
  location      = var.region
  force_destroy = true
}

# Function Source Code
resource "google_storage_bucket_object" "multi_location_restaurant_pos_system_object_function_source" {
  name   = "payment-processor-source.zip"
  bucket = google_storage_bucket.multi_location_restaurant_pos_system_bucket_functions.name
  source = "payment-processor-source.zip"
}

# VPC Connector for Cloud Functions
resource "google_vpc_access_connector" "multi_location_restaurant_pos_system_connector_vpc" {
  name          = "multi-location-restaurant-pos-system-connector-vpc"
  ip_cidr_range = "10.8.0.0/28"
  network       = google_compute_network.multi_location_restaurant_pos_system_vpc_main.name
  region        = var.region
}

# SSL Policy - VULNERABILITY: Weak TLS version
resource "google_compute_ssl_policy" "multi_location_restaurant_pos_system_policy_ssl" {
  name            = "multi-location-restaurant-pos-system-policy-ssl"
  profile         = "MODERN"
  # VULNERABILITY: Using outdated TLS 1.1 instead of 1.2
  min_tls_version = "TLS_1_1"
}

# Global Load Balancer IP
resource "google_compute_global_address" "multi_location_restaurant_pos_system_address_lb" {
  name = "multi-location-restaurant-pos-system-address-lb"
}

# Global Forwarding Rule (Load Balancer)
resource "google_compute_global_forwarding_rule" "multi_location_restaurant_pos_system_rule_load_balancer" {
  name       = "multi-location-restaurant-pos-system-rule-load-balancer"
  target     = google_compute_target_https_proxy.multi_location_restaurant_pos_system_proxy_https.id
  port_range = "443"
  ip_address = google_compute_global_address.multi_location_restaurant_pos_system_address_lb.address

  depends_on = [google_container_cluster.multi_location_restaurant_pos_system_cluster_pos_application]
}

# HTTPS Proxy
resource "google_compute_target_https_proxy" "multi_location_restaurant_pos_system_proxy_https" {
  name             = "multi-location-restaurant-pos-system-proxy-https"
  url_map          = google_compute_url_map.multi_location_restaurant_pos_system_urlmap_main.id
  ssl_certificates = [google_compute_managed_ssl_certificate.multi_location_restaurant_pos_system_cert_ssl.id]
  ssl_policy       = google_compute_ssl_policy.multi_location_restaurant_pos_system_policy_ssl.id
}

# URL Map
resource "google_compute_url_map" "multi_location_restaurant_pos_system_urlmap_main" {
  name            = "multi-location-restaurant-pos-system-urlmap-main"
  default_service = google_compute_backend_service.multi_location_restaurant_pos_system_backend_gke.id
}

# Backend Service
resource "google_compute_backend_service" "multi_location_restaurant_pos_system_backend_gke" {
  name        = "multi-location-restaurant-pos-system-backend-gke"
  protocol    = "HTTP"
  timeout_sec = 30

  backend {
    group = google_container_node_pool.multi_location_restaurant_pos_system_nodepool_primary.instance_group_urls[0]
  }

  health_checks = [google_compute_health_check.multi_location_restaurant_pos_system_healthcheck_http.id]
}

# Health Check
resource "google_compute_health_check" "multi_location_restaurant_pos_system_healthcheck_http" {
  name = "multi-location-restaurant-pos-system-healthcheck-http"

  http_health_check {
    port = 80
    path = "/health"
  }
}

# Managed SSL Certificate
resource "google_compute_managed_ssl_certificate" "multi_location_restaurant_pos_system_cert_ssl" {
  name = "multi-location-restaurant-pos-system-cert-ssl"

  managed {
    domains = [var.domain_name]
  }
}

# VULNERABILITY: Direct user permissions instead of groups
resource "google_project_iam_member" "multi_location_restaurant_pos_system_iam_payment_access" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  # VULNERABILITY: Direct user access instead of service account or group
  member  = "user:${var.developer_email}"
}