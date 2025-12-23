// iam_access.tf
// Grants your user read access to the newly-created project and the bucket,
// so you can see/query it in Console and with gcloud/gsutil.

variable "user_viewer_email" {
  type        = string
  description = "User email to grant read access in the new project & bucket"
  default     = "artem.artyunov@env0.com"
}

locals {
  user_member = "user:${var.user_viewer_email}"
}

/*
  Project-level read (general):
  - roles/viewer gives you read-only visibility across most services,
    but does NOT include storage.buckets.get in all orgs/policies.
*/
resource "google_project_iam_member" "viewer_me" {
  project = module.project_factory.project_id
  role    = "roles/viewer"
  member  = local.user_member
  depends_on = [module.project_factory]
}

/*
  Bucket-level read (least-privilege for Cloud Storage):
  - roles/storage.objectViewer      : list/get objects (no writes)
  - roles/storage.legacyBucketReader: bucket metadata (includes storage.buckets.get)
    Note: legacyBucketReader is the standard way to allow bucket metadata reads
    without broad project-wide storage roles.
*/
resource "google_storage_bucket_iam_member" "bucket_object_viewer_me" {
  bucket = google_storage_bucket.test_bucket.name
  role   = "roles/storage.objectViewer"
  member = local.user_member
  depends_on = [google_storage_bucket.test_bucket]
}

resource "google_storage_bucket_iam_member" "bucket_metadata_viewer_me" {
  bucket = google_storage_bucket.test_bucket.name
  role   = "roles/storage.legacyBucketReader"
  member = local.user_member
  depends_on = [google_storage_bucket.test_bucket]
}

/* --------------------------------------------------------------------------
   OPTIONAL: If you prefer a quick/unlock at project scope instead of the
   two bucket-level bindings above, comment them out and use this instead.
   This grants broad Storage admin at the project (temporary recommended).
---------------------------------------------------------------------------

resource "google_project_iam_member" "storage_admin_me" {
  project = module.project_factory.project_id
  role    = "roles/storage.admin"
  member  = local.user_member
  depends_on = [module.project_factory]
}
*/
