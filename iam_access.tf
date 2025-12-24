// iam_access.tf
// Grants your user read access to the effective project (create or adopt)
// and read access to the bucket. Uses local.effective_project_id so it works
// whether we created the project (module with count = 1) or adopted it.

variable "user_viewer_email" {
  type        = string
  description = "User email to grant read access in the project & bucket"
  default     = "artem.artyunov@env0.com"
}

# OPTIONAL: if left empty, we'll use the bucket created in main.tf
variable "bucket_name_for_iam" {
  type        = string
  description = "Existing GCS bucket name to grant read access to (e.g., env0-xxx-bkt-1234). If empty, use google_storage_bucket.one_bucket."
  default     = ""
}

locals {
  user_member      = "user:${var.user_viewer_email}"
  # Prefer explicit name when provided; otherwise use the bucket we create
  iam_bucket_name  = var.bucket_name_for_iam != "" ? var.bucket_name_for_iam : google_storage_bucket.one_bucket.name
}

# ----- Project-level read (general visibility) -----
resource "google_project_iam_member" "viewer_me" {
  project = local.effective_project_id
  role    = "roles/viewer"
  member  = local.user_member
}

# ----- Bucket-level read (least-privilege for Cloud Storage) -----
# objectViewer: list/get objects
resource "google_storage_bucket_iam_member" "bucket_object_viewer_me" {
  bucket = local.iam_bucket_name
  role   = "roles/storage.objectViewer"
  member = local.user_member

  # ensure bucket exists if we're using the created one
  lifecycle {
    ignore_changes = [bucket] # safe if you switch between explicit/created names
  }
}

# legacyBucketReader: bucket metadata (storage.buckets.get)
resource "google_storage_bucket_iam_member" "bucket_metadata_viewer_me" {
  bucket = local.iam_bucket_name
  role   = "roles/storage.legacyBucketReader"
  member = local.user_member

  lifecycle {
    ignore_changes = [bucket]
  }
}

/* --------------------------------------------------------------------------
   OPTIONAL (broader, quicker access): instead of the two bucket-level roles
   above, you can grant Storage Admin at the project level temporarily.

resource "google_project_iam_member" "storage_admin_me" {
  project = local.effective_project_id
  role    = "roles/storage.admin"
  member  = local.user_viewer_email
}
--------------------------------------------------------------------------- */
