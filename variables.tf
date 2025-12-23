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
  description = "Folder ID (numeric digits, e.g., 621599609930). Leave empty if using org_id."
  type        = string
  default     = ""
}

variable "billing_account" {
  description = "Billing account ID (e.g., 000000-000000-000000)."
  type        = string
}

# Project ID control

variable "create_project" {
  description = "If true, create a new project. If false, adopt/manage an existing project_id."
  type        = bool
  default     = true
}

variable "project_id" {
  description = "If set (non-empty), use this exact project ID. If empty, a random-suffixed ID is generated from project_name_prefix."
  type        = string
  default     = ""
}

# Convenience / naming

variable "project_name_prefix" {
  description = "Prefix for the new project's display name and, if project_id is empty, the base for the generated project ID."
  type        = string
  default     = "env0-tofu-gpf"
}

# APIs to enable in NEW/existing project (managed by the module)

variable "activate_apis" {
  description = "APIs to enable in the project."
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

# Bucket settings

variable "bucket_location" {
  description = "Bucket location/region or multi-region (e.g., US, EU, us-central1)."
  type        = string
  default     = "US"
}

# Persistent Disk (optional)

variable "enable_persistent_disk" {
  description = "Set true to create a test persistent disk in the project."
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
