// iam_access.tf
// Grants your user read access to the project that GPF just created,
// so you can see/query the bucket and other resources.

// Change this if you want a different user (or set TF_VAR_user_viewer_email in env0)
variable "user_viewer_email" {
  type        = string
  description = "User email to grant read access in the new project"
  default     = "artem.artyunov@env0.com"
}

locals {
  user_member = "user:${var.user_viewer_email}"
}

// Ensure this runs after the project exists
// (assumes your GPF module is named `project_factory`)
resource "google_project_iam_member" "viewer_me" {
  project = module.project_factory.project_id
  role    = "roles/viewer"
  member  = local.user_member

  depends_on = [module.project_factory]
}

resource "google_project_iam_member" "storage_viewer_me" {
  project = module.project_factory.project_id
  role    = "roles/storage.viewer"
  member  = local.user_member

  depends_on = [module.project_factory]
}

/*
Optional: if you prefer bucket-level IAM instead of project-wide,
uncomment these and replace the bucket reference if needed.

resource "google_storage_bucket_iam_member" "bucket_viewer_me" {
  bucket = google_storage_bucket.test_bucket.name
  role   = "roles/storage.objectViewer"
  member = local.user_member

  depends_on = [google_storage_bucket.test_bucket]
}
*/
