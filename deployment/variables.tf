variable "project_name" {
  default   = "whereisrudi-<random_number>"
}

variable "region" {
  default   = "europe-west1"  # St. Ghislain, Belgium
}

variable "location_id" {
  default   = "europe-west"   # Belgium
}

# Variables from terraform.tfvars
variable "slack_api_verification_token" {
  type   = "string"
}

variable "slack_api_token" {
  type   = "string"
}

variable "user_id" {
  type   = "string"
}
