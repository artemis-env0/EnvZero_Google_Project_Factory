// iam_access.tf
// Grants your user read access to the newly-created project and bucket,
// looking up the bucket by NAME (no dependency on how the bucket resource is named).

variable "user_viewer_email" {
  type        = string
  description = "User email to grant read access in the new project & bucket"
  default     = "artem.artyunov@env0.com"
}

variable "bucket_name_for_iam" {
  type        = string
  description = "Existing GCS bucket name to grant read access to (e.g., env0-demo-0d2a-bkt-1983)"
}

locals {
  user_member = "user:${var.user_viewer_email}"
}

/*
  Project-level read:
  - roles/viewer provides general, read-only visibility across most services.
*/
resource "google_project_iam_member" "viewer_me" {
  project = module.project_factory.project_id
  role    = "roles/viewer"
  member  = local.user_member

  depends_on = [module.project_factory]
}

/*
  Bucket lookup by name (no dependency on a local resource name/address).
*/
data "google_storage_bucket" "target" {
  name = var.bucket_name_for_iam
}

/*
  Bucket-level read (least-privilege for Cloud Storage):
  - roles/storage.objectViewer      : list/get objects
  - roles/storage.legacyBucketReader: bucket metadata (includes storage.buckets.get)
*/
resource "google_storage_bucket_iam_member" "bucket_object_viewer_me" {
  bucket = data.google_storage_bucket.target.name
  role   = "roles/storage.objectViewer"
  member = local.user_member
}

resource "google_storage_bucket_iam_member" "bucket_metadata_viewer_me" {
  bucket = data.google_storage_bucket.target.name
  role   = "roles/storage.legacyBucketReader"
  member = local.user_member
}
