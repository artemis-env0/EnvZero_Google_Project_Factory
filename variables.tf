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
  description = "Folder ID (numeric, e.g., 621599609930). Leave empty if using org_id."
  type        = string
  default     = ""
}

variable "billing_account" {
  description = "Billing account ID (e.g., 000000-000000-000000)."
  type        = string
}

# Project selection (create vs adopt)
# Set existing_project_id to ADOPT that project (skip Project Factory).
# Otherwise we CREATE a new project with project_id (or auto-generate one).
variable "existing_project_id" {
  description = "If non-empty, adopt/manage this existing project instead of creating one."
  type        = string
  default     = ""
}

variable "project_id" {
  description = "Exact project ID to create (only used when existing_project_id is empty). If empty, env0 pre-step generates env-demo-<hex>."
  type        = string
  default     = ""
}

# Convenience / naming
variable "project_name_prefix" {
  description = "Prefix for generated project IDs when project_id is empty."
  type        = string
  default     = "env-demo"
}

# APIs to enable
variable "activate_apis" {
  description = "APIs to enable in the project."
  type        = list(string)
  default = [
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "iam.googleapis.com",
    "storage.googleapis.com",
    "compute.googleapis.com"
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
  description = "Bucket region or multi-region (e.g., US, EU, us-central1)."
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
