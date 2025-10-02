output "orchestration_engine_ip" {
  description = "IP address of the backup orchestration engine"
  value       = google_compute_instance.backup_orchestration_engine.network_interface[0].access_config[0].nat_ip
}

output "monitoring_dashboard_ip" {
  description = "IP address of the monitoring dashboard"
  value       = google_compute_instance.monitoring_dashboard.network_interface[0].access_config[0].nat_ip
}

output "recovery_database_connection" {
  description = "Connection string for the recovery database"
  value       = google_sql_database_instance.recovery_database.connection_name
  sensitive   = true
}

output "primary_backup_bucket" {
  description = "Name of the primary backup storage bucket"
  value       = google_storage_bucket.primary_backup_storage.name
}

output "secondary_backup_bucket" {
  description = "Name of the secondary backup storage bucket"
  value       = google_storage_bucket.secondary_backup_storage.name
}

output "recovery_testing_function_url" {
  description = "URL of the recovery testing cloud function"
  value       = google_cloudfunctions_function.recovery_testing_service.https_trigger_url
}

output "notification_service_function_url" {
  description = "URL of the notification service cloud function"
  value       = google_cloudfunctions_function.notification_service.https_trigger_url
}

output "vpc_network_id" {
  description = "ID of the VPC network"
  value       = google_compute_network.dr_vpc.id
}

output "dashboard_load_balancer_ip" {
  description = "IP address of the dashboard load balancer"
  value       = google_compute_global_address.dashboard_ip.address
}

output "pubsub_topics" {
  description = "Pub/Sub topics for function triggers"
  value = {
    testing      = google_pubsub_topic.recovery_testing_trigger.name
    notification = google_pubsub_topic.notification_trigger.name
  }
}