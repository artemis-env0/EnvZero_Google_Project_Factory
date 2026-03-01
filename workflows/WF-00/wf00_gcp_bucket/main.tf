locals {
  effective_prefix = var.bucket_name_prefix != "" ? var.bucket_name_prefix : "${var.project_id}-bkt"
  deployer_member  = trimspace(var.deployer_user_email) != "" ? "user:${trimspace(var.deployer_user_email)}" : ""
}

resource "random_id" "suffix" {
  count       = var.enable_bucket ? 1 : 0
  byte_length = 2
}

resource "google_storage_bucket" "bucket" {
  count                       = var.enable_bucket ? 1 : 0
  name                        = "${local.effective_prefix}-${random_id.suffix[0].hex}"
  project                     = var.project_id
  location                    = var.bucket_location
  uniform_bucket_level_access = true
  force_destroy               = var.force_destroy

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30
    }
  }
}

# Optional: grant deployer full bucket control so they can verify and delete the bucket
resource "google_storage_bucket_iam_member" "deployer_bucket_admin" {
  count  = var.enable_bucket && local.deployer_member != "" ? 1 : 0
  bucket = google_storage_bucket.bucket[0].name
  role   = "roles/storage.admin"
  member = local.deployer_member
}
