# ------------------------------------------------------------
# IAM convenience grants (optional)
# Lets env0 runner SA manage created project (if configured)
# Lets the human deployer see/delete what was created
# ------------------------------------------------------------

# Ensure env0 SA can manage the new project (optional)
resource "google_project_iam_member" "grant_editor_to_caller" {
  count   = (var.caller_sa_email != null && var.caller_sa_email != "") ? 1 : 0
  project = module.project_factory.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${var.caller_sa_email}"
}

# Give the deployer broad ability to delete resources in the created project (optional)
# NOTE: roles/editor allows deleting most resources created in the project,
# but it does NOT grant org/folder-level ability to delete the project itself.
resource "google_project_iam_member" "deployer_editor" {
  count   = (var.deployer_user_email != null && var.deployer_user_email != "" && var.grant_deployer_editor) ? 1 : 0
  project = module.project_factory.project_id
  role    = "roles/editor"
  member  = "user:${var.deployer_user_email}"
}

# Bucket-level admin for deployer (optional)
# This is the cleanest way to allow them to delete/list/describe the bucket they created.
resource "google_storage_bucket_iam_member" "deployer_bucket_admin" {
  count  = (var.deployer_user_email != null && var.deployer_user_email != "" && var.grant_deployer_bucket_admin) ? 1 : 0
  bucket = google_storage_bucket.one_bucket.name
  role   = "roles/storage.admin"
  member = "user:${var.deployer_user_email}"

  depends_on = [google_storage_bucket.one_bucket]
}
