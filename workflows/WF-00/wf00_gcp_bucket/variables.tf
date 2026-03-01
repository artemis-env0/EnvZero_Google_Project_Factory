variable "project_id" {
  description = "Target project ID where the bucket is created."
  type        = string
}

variable "region" {
  description = "Default region for provider context."
  type        = string
  default     = "us-east1"
}

variable "bucket_location" {
  description = "Bucket location (multi-region like US or region like us-east1)."
  type        = string
  default     = "US"
}

variable "bucket_name_prefix" {
  description = "Optional. If empty, uses <project_id>-bkt."
  type        = string
  default     = ""
}

variable "force_destroy" {
  description = "If true, bucket will be deleted even if it contains objects."
  type        = bool
  default     = true
}

variable "deployer_user_email" {
  description = "Optional. If set, grants roles/storage.admin on this bucket to the deployer user."
  type        = string
  default     = ""
}

variable "enable_bucket" {
  description = "If false, create no bucket."
  type        = bool
  default     = true
}
