# Provider / bootstrap

variable "bootstrap_project_id" {
  description = "Existing project used by the google provider for auth/lookups."
  type        = string
}

variable "region" {
  description = "Default region for provider context."
  type        = string
  default     = "us-central1"
}

# Org / folder / billing

variable "org_id" {
  description = "Organization ID (leave empty if using folder_id)."
  type        = string
  default     = ""
}

variable "folder_id" {
  description = "Folder ID in the form 'folders/123456789012' (leave empty if using org_id)."
  type        = string
  default     = ""
}

variable "billing_account" {
  description = "Billing account ID (e.g., 000000-000000-000000)."
  type        = string
}

# Convenience / naming

variable "project_name_prefix" {
  description = "Prefix for the new project's display name."
  type        = string
  default     = "env0-tofu-gpf"
}

# APIs to enable in NEW project

variable "activate_apis" {
  description = "APIs to enable in the new project."
  type        = list(string)
  default = [
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "iam.googleapis.com",
    "storage.googleapis.com",
    "compute.googleapis.com" # needed if you enable the persistent disk
  ]
}

# Optional: grant runner SA access

variable "caller_sa_email" {
  description = "Service account email used by env0 (to grant project-level role). Leave empty to skip."
  type        = string
  default     = ""
}

# Optional: grant the deploying human access (to view/delete what was created)

variable "deployer_user_email" {
  description = "User email to grant access in the created project/bucket (e.g., artem.artyunov@env0.com). Leave empty to skip."
  type        = string
  default     = ""
}

variable "grant_deployer_editor" {
  description = "If true and deployer_user_email is set, grants roles/editor on the created project to the deployer."
  type        = bool
  default     = true
}

variable "grant_deployer_bucket_admin" {
  description = "If true and deployer_user_email is set, grants bucket-level roles/storage.admin on the created bucket to the deployer."
  type        = bool
  default     = true
}

# Bucket settings

variable "bucket_location" {
  description = "Bucket location/region or multi-region (e.g., US, EU, us-central1)."
  type        = string
  default     = "US"
}

# Persistent Disk (optional)

variable "enable_persistent_disk" {
  description = "Set true to create a test persistent disk in the new project."
  type        = bool
  default     = false
}

variable "disk_zone" {
  description = "Zone for the test persistent disk (must match your region family)."
  type        = string
  default     = "us-central1-a"
}

variable "disk_type" {
  description = "Disk type: pd-standard | pd-balanced | pd-ssd."
  type        = string
  default     = "pd-standard"
}

variable "disk_size_gb" {
  description = "Disk size in GB."
  type        = number
  default     = 14
}
