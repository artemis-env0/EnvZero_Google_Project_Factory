variable "bootstrap_project_id" {
  description = "Existing project used by the google provider for auth/lookups."
  type        = string
}

variable "region" {
  description = "Default region (not used by the bucket itself)."
  type        = string
  default     = "us-central1"
}

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

variable "project_name_prefix" {
  description = "Prefix for the new project's display name."
  type        = string
  default     = "env0-tofu-gpf"
}

variable "bucket_location" {
  description = "Bucket location/region or multi-region (e.g., US, EU, us-central1)."
  type        = string
  default     = "US"
}

variable "activate_apis" {
  description = "APIs to enable in the new project."
  type        = list(string)
  default = [
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "iam.googleapis.com",
    "storage.googleapis.com"
  ]
}
