# Media Streaming Platform Infrastructure
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
resource "google_compute_network" "media_streaming_vpc" {
  name                    = "media-streaming-platform-with-content-delivery-vpc-main"
  auto_create_subnetworks = false
  description            = "VPC for media streaming platform"
}

# Public Subnet for API instances
resource "google_compute_subnetwork" "public_subnet" {
  name          = "media-streaming-platform-with-content-delivery-subnet-public"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.media_streaming_vpc.id
  # VULNERABILITY: Missing private_ip_google_access = true
}

# Private Subnet for database
resource "google_compute_subnetwork" "private_subnet" {
  name                     = "media-streaming-platform-with-content-delivery-subnet-private"
  ip_cidr_range           = "10.0.2.0/24"
  region                  = var.region
  network                 = google_compute_network.media_streaming_vpc.id
  private_ip_google_access = false  # VULNERABILITY: Should be true
}

# Project metadata for OS Login
resource "google_compute_project_metadata" "streaming_metadata" {
  metadata = {
    enable-oslogin = false  # VULNERABILITY: Should be true
  }
}

# Firewall rule for streaming API - VULNERABLE
resource "google_compute_firewall" "streaming_api_firewall" {
  name    = "media-streaming-platform-with-content-delivery-firewall-api"
  network = google_compute_network.media_streaming_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]  # VULNERABILITY: Allows all ports
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["streaming-api"]
}

# Firewall rule for SSH access
resource "google_compute_firewall" "ssh_firewall" {
  name    = "media-streaming-platform-with-content-delivery-firewall-ssh"
  network = google_compute_network.media_streaming_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["streaming-api"]
}

# Content Storage Bucket
resource "google_storage_bucket" "content_storage" {
  name          = "media-streaming-platform-with-content-delivery-storage-content-${random_id.bucket_suffix.hex}"
  location      = var.region
  force_destroy = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}

# Transcoded Content Storage Bucket
resource "google_storage_bucket" "transcoded_storage" {
  name          = "media-streaming-platform-with-content-delivery-storage-transcoded-${random_id.bucket_suffix.hex}"
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
}

# Random ID for unique bucket names
resource "random_id" "bucket_suffix" {
  byte_length = 8
}

# Cloud Function for transcoding service
resource "google_cloudfunctions_function" "transcoding_service" {
  name        = "media-streaming-platform-with-content-delivery-function-transcoding"
  description = "Video transcoding service"
  runtime     = "python39"

  available_memory_mb   = 512
  source_archive_bucket = google_storage_bucket.function_source.name
  source_archive_object = google_storage_bucket_object.function_source.name
  trigger {
    event_type = "google.storage.object.finalize"
    resource   = google_storage_bucket.content_storage.name
  }
  entry_point = "transcode_video"

  environment_variables = {
    OUTPUT_BUCKET = google_storage_bucket.transcoded_storage.name
  }
}

# Function source bucket
resource "google_storage_bucket" "function_source" {
  name          = "media-streaming-platform-with-content-delivery-storage-functions-${random_id.bucket_suffix.hex}"
  location      = var.region
  force_destroy = true
}

# Function source code
resource "google_storage_bucket_object" "function_source" {
  name   = "transcoding-function.zip"
  bucket = google_storage_bucket.function_source.name
  source = data.archive_file.function_source.output_path
}

data "archive_file" "function_source" {
  type        = "zip"
  output_path = "/tmp/transcoding-function.zip"
  source {
    content = <<EOF
import os
from google.cloud import storage

def transcode_video(event, context):
    """Triggered by a change to a Cloud Storage bucket."""
    file = event
    print(f'Processing file: {file["name"]}')
    
    # Placeholder for actual transcoding logic
    output_bucket = os.environ.get('OUTPUT_BUCKET')
    print(f'Would transcode to bucket: {output_bucket}')
    
    return 'OK'
EOF
    filename = "main.py"
  }
}

# User Database - Cloud SQL PostgreSQL
resource "google_sql_database_instance" "user_database" {
  name             = "media-streaming-platform-with-content-delivery-database-users"
  database_version = "POSTGRES_13"
  region           = var.region

  settings {
    tier = "db-f1-micro"
    
    backup_configuration {
      enabled = false  # VULNERABILITY: Backups disabled
    }

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.media_streaming_vpc.id
    }

    database_flags {
      name  = "log_lock_waits"
      value = "off"  # VULNERABILITY: Should be "on"
    }
  }

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

# Database
resource "google_sql_database" "streaming_db" {
  name     = "streaming_platform"
  instance = google_sql_database_instance.user_database.name
}

# Database user
resource "google_sql_user" "streaming_user" {
  name     = "streaming_app"
  instance = google_sql_database_instance.user_database.name
  password = var.db_password
}

# Private VPC connection for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  name          = "media-streaming-platform-with-content-delivery-ip-private"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.media_streaming_vpc.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.media_streaming_vpc.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

# Streaming API Compute Instance
resource "google_compute_instance" "streaming_api" {
  name         = "media-streaming-platform-with-content-delivery-instance-api"
  machine_type = "e2-medium"
  zone         = var.zone

  tags = ["streaming-api"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
    disk_encryption_key_raw = "YjJoaGJtOGdkR2hwY3lCcGN5QmlZV1E9"  # VULNERABILITY: Plaintext key
  }

  network_interface {
    network    = google_compute_network.media_streaming_vpc.name
    subnetwork = google_compute_subnetwork.public_subnet.name
    access_config {
      // Ephemeral public IP
    }
  }

  service_account {
    email  = "${var.project_number}-compute@developer.gserviceaccount.com"  # VULNERABILITY: Default service account
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    apt-get update
    apt-get install -y python3 python3-pip nginx
    pip3 install flask google-cloud-storage google-cloud-sql-connector
    
    # Create simple streaming API
    cat > /opt/streaming_api.py << 'PYEOF'
import os
from flask import Flask, jsonify
from google.cloud import storage

app = Flask(__name__)

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'})

@app.route('/content')
def list_content():
    return jsonify({'content': ['video1.mp4', 'video2.mp4']})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
PYEOF

    python3 /opt/streaming_api.py &
  EOF
}

# Analytics Pipeline - Pub/Sub Topic
resource "google_pubsub_topic" "analytics_pipeline" {
  name = "media-streaming-platform-with-content-delivery-topic-analytics"

  message_retention_duration = "86400s"
}

# Pub/Sub Subscription
resource "google_pubsub_subscription" "analytics_subscription" {
  name  = "media-streaming-platform-with-content-delivery-subscription-analytics"
  topic = google_pubsub_topic.analytics_pipeline.name

  message_retention_duration = "1200s"
  retain_acked_messages      = true

  ack_deadline_seconds = 20

  expiration_policy {
    ttl = "300000.5s"
  }
}

# CDN Backend Bucket
resource "google_compute_backend_bucket" "cdn_backend" {
  name        = "media-streaming-platform-with-content-delivery-backend-cdn"
  description = "CDN backend for content delivery"
  bucket_name = google_storage_bucket.transcoded_storage.name
  enable_cdn  = true
}

# URL Map for CDN
resource "google_compute_url_map" "cdn_url_map" {
  name            = "media-streaming-platform-with-content-delivery-urlmap-cdn"
  description     = "URL map for media streaming CDN"
  default_service = google_compute_backend_bucket.cdn_backend.id
}

# HTTPS Proxy
resource "google_compute_target_https_proxy" "cdn_https_proxy" {
  name             = "media-streaming-platform-with-content-delivery-proxy-https"
  url_map          = google_compute_url_map.cdn_url_map.id
  ssl_certificates = [google_compute_managed_ssl_certificate.cdn_ssl_cert.id]
}

# SSL Certificate
resource "google_compute_managed_ssl_certificate" "cdn_ssl_cert" {
  name = "media-streaming-platform-with-content-delivery-cert-ssl"

  managed {
    domains = [var.domain_name]
  }
}

# Global Forwarding Rule (CDN Distribution)
resource "google_compute_global_forwarding_rule" "cdn_distribution" {
  name       = "media-streaming-platform-with-content-delivery-forwarding-rule-cdn"
  target     = google_compute_target_https_proxy.cdn_https_proxy.id
  port_range = "443"
}