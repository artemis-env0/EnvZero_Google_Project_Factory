// iam_access.tf
// Grants your user read access to the newly-created project and (optionally) the bucket.
// If TF_VAR_bucket_name_for_iam is not set, bucket IAM is skipped (plan still succeeds).

variable "user_viewer_email" {
  type        = string
  description = "User email to grant read access in the new project & bucket"
  default     = "artem.artyunov@env0.com"
}

# OPTIONAL: set via env0 as TF_VAR_bucket_name_for_iam; if empty, bucket IAM is skipped
variable "bucket_name_for_iam" {
  type        = string
  description = "Existing GCS bucket name to grant read access to (e.g., env0-demo-0d2a-bkt-1983). If empty, bucket IAM is skipped."
  default     = ""
}

locals {
  user_member = "user:${var.user_viewer_email}"
}

# Project-level read (general visibility)
resource "google_project_iam_member" "viewer_me" {
  project = module.project_factory.project_id
  role    = "roles/viewer"
  member  = local.user_member

  depends_on = [module.project_factory]
}

# Bucket-level read (least-privilege): only if bucket name provided
resource "google_storage_bucket_iam_member" "bucket_object_viewer_me" {
  count  = var.bucket_name_for_iam == "" ? 0 : 1
  bucket = var.bucket_name_for_iam
  role   = "roles/storage.objectViewer"
  member = local.user_member
}

resource "google_storage_bucket_iam_member" "bucket_metadata_viewer_me" {
  count  = var.bucket_name_for_iam == "" ? 0 : 1
  bucket = var.bucket_name_for_iam
  role   = "roles/storage.legacyBucketReader"
  member = local.user_member
}
