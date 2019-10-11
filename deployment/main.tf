# Global configurations
provider "google" {
  credentials = "${file("account.json")}"
  project = "${var.project_name}"
  region  = "${var.region}"
}

# Google App Engine application (needed for Google Cloud Scheduler)
resource "google_app_engine_application" "app" {
  project     = "${var.project_name}"
  location_id = "${var.location_id}"
}

# Google Cloud Scheduler
resource "google_pubsub_topic" "gather_information_schedule_topic" {
  name = "gather-information-schedule"
}

resource "google_cloud_scheduler_job" "gather_information_schedule_job" {
  name          = "gather-information-schedule"
  description   = "Schedule to gather information"
  schedule      = "30 7 * * 1-5"
  time_zone     = "Europe/Berlin"

  pubsub_target {
    topic_name  = "${google_pubsub_topic.gather_information_schedule_topic.id}"
    data        = "${base64encode("{}")}"
  }

  depends_on    = [google_app_engine_application.app]
}

# Google Storage Bucket
resource "google_storage_bucket" "cloud_functions_code_bucket" {
  name     = "cloud-functions-code-bucket-${var.project_name}"
  location = "${var.region}"
}
data "archive_file" "gather_information_archive" {
  type        = "zip"
  source_dir = "../gather-information/"
  output_path = "gather-information.zip"
}
resource "google_storage_bucket_object" "gather_information_zip" {
  name   = "${data.archive_file.gather_information_archive.output_path}"
  source = "${data.archive_file.gather_information_archive.output_path}"
  bucket = "${google_storage_bucket.cloud_functions_code_bucket.name}"
}
data "archive_file" "slash_commands_and_actions_archive" {
  type        = "zip"
  source_dir = "../slash-commands-and-actions/"
  output_path = "slash-commands-and-actions.zip"
}
resource "google_storage_bucket_object" "slash_commands_and_actions_zip" {
  name   = "${data.archive_file.slash_commands_and_actions_archive.output_path}"
  source = "${data.archive_file.slash_commands_and_actions_archive.output_path}"
  bucket = "${google_storage_bucket.cloud_functions_code_bucket.name}"
}

# Google Cloud Functions
resource "google_cloudfunctions_function" "gather_information_function" {
  name                  = "gather-information"
  description           = "Gather information"
  runtime               = "python37"

  available_memory_mb   = 128
  timeout               = 10
  entry_point           = "gather_information"
  max_instances         = 1

  source_archive_bucket = "${google_storage_bucket.cloud_functions_code_bucket.name}"
  source_archive_object = "${google_storage_bucket_object.gather_information_zip.name}"

  event_trigger {
      event_type        = "google.pubsub.topic.publish"
      resource          = "${google_pubsub_topic.gather_information_schedule_topic.id}"
  }

  environment_variables = {
      SLACK_API_TOKEN   = "${var.slack_api_token}"
      USER_ID           = "${var.user_id}"
  }
}

resource "google_cloudfunctions_function" "slack_actions_function" {
  name                  = "slack-actions"
  description           = "Slack actions"
  runtime               = "python37"

  available_memory_mb   = 256
  timeout               = 15
  trigger_http          = true
  entry_point           = "action"

  source_archive_bucket = "${google_storage_bucket.cloud_functions_code_bucket.name}"
  source_archive_object = "${google_storage_bucket_object.slash_commands_and_actions_zip.name}"

  environment_variables = {
    SLACK_API_VERIFICATION_TOKEN    = "${var.slack_api_verification_token}"
  }
}

resource "google_cloudfunctions_function" "slack_slash_commands_function" {
  name                  = "slack-slash-commands"
  description           = "Slack slash commands"
  runtime               = "python37"

  available_memory_mb   = 256
  timeout               = 15
  trigger_http          = true
  entry_point           = "slash_command"

  source_archive_bucket = "${google_storage_bucket.cloud_functions_code_bucket.name}"
  source_archive_object = "${google_storage_bucket_object.slash_commands_and_actions_zip.name}"

  environment_variables = {
    SLACK_API_VERIFICATION_TOKEN    = "${var.slack_api_verification_token}"
  }
}

output "slack_actions_function_url" {
  value       = "https://${var.region}-${var.project_name}.cloudfunctions.net/${google_cloudfunctions_function.slack_actions_function.name}"
  description = "Enter this endpoint URL in the 'Interactive Components' in the Slack API console under 'Interactivity'."
  depends_on  = [google_cloudfunctions_function.slack_actions_function]
}

output "slack_slash_commands_function_url" {
  value       = "https://${var.region}-${var.project_name}.cloudfunctions.net/${google_cloudfunctions_function.slack_slash_commands_function.name}"
  description = "Enter this endpoint URL in the 'Slash Commands' in the Slack API console."
  depends_on  = [google_cloudfunctions_function.slack_slash_commands_function]
}
