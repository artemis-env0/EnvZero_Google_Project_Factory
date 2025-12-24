// ============================
// iam_access.tf
// ============================
// Grants the human deployer rights to delete the resources they created:
// Full admin on the created bucket (can delete bucket & objects)
// If PD is enabled, Compute Storage Admin for disks/images (delete PD)
// Also optional viewer so they can see the project in the UI.
//
// Uses local.effective_project_id & google_storage_bucket.one_bucket from main.tf

variable "deployer_user_email" {
  type        = string
  description = "Human deployer to grant delete rights to (i.e., some.user@domain.com). Leave empty to skip."
  default     = ""
}

locals {
  deployer_member = var.deployer_user_email != "" ? "user:${var.deployer_user_email}" : ""
}

# ---- Bucket-level admin (delete bucket & objects) ----
resource "google_storage_bucket_iam_member" "bucket_admin_deployer" {
  count  = local.deployer_member == "" ? 0 : 1
  bucket = google_storage_bucket.one_bucket.name
  role   = "roles/storage.admin"
  member = local.deployer_member
}

# ---- Disk delete rights when PD is enabled ----
# roles/compute.storageAdmin lets a user delete disks/snapshots/images.
resource "google_project_iam_member" "compute_storage_admin_deployer" {
  count   = local.deployer_member != "" && var.enable_persistent_disk ? 1 : 0
  project = local.effective_project_id
  role    = "roles/compute.storageAdmin"
  member  = local.deployer_member
}

# (Optional) If you also want the deployer to see the project in UI:
resource "google_project_iam_member" "viewer_deployer" {
  count   = local.deployer_member == "" ? 0 : 1
  project = local.effective_project_id
  role    = "roles/viewer"
  member  = local.deployer_member
}
