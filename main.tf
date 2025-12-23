################################################################################
# Who am I?
################################################################################

data "google_client_openid_userinfo" "me" {}

output "whoami_email" {
  value       = data.google_client_openid_userinfo.me.email
  description = "Authenticated principal email from GOOGLE_CREDENTIALS."
}

################################################################################
# Project ID strategy (module gets an explicit ID)
################################################################################

# If project_id is empty, a random-suffixed ID will be supplied by env0 pre-step.
# (We still keep a random here if you later want to switch to TF-only control.)
resource "random_id" "project" {
  byte_length = 2
}

locals {
  final_project_id = var.project_id != "" ? var.project_id : "${var.project_name_prefix}-${random_id.project.hex}"
  parent_org_id    = var.org_id    != "" ? var.org_id    : null
  parent_folder_id = var.folder_id != "" ? var.folder_id : null
}

################################################################################
# Create or adopt project via Project Factory v18
################################################################################

module "project_factory" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 18.0"

  # Parent (only matters when create_project=true)
  org_id    = local.parent_org_id
  folder_id = local.parent_folder_id

  # Creation vs adoption (env0 pre-step decides final values)
  create_project = var.create_project
  project_id     = local.final_project_id

  # Naming / billing / APIs
  name                   = var.project_name_prefix
  billing_account        = var.billing_account
  activate_apis          = var.activate_apis
  default_service_account = "deprivilege"

  # We supply an explicit project_id, so disable module's randomizer
  random_project_id = false
}

output "created_project_id" {
  value       = module.project_factory.project_id
  description = "ID of the created/adopted project."
}

output "created_project_number" {
  value       = module.project_factory.project_number
  description = "Number of the created/adopted project."
}

################################################################################
# Optional: ensure env0 SA can manage the project
################################################################################

resource "google_project_iam_member" "grant_editor_to_caller" {
  count   = var.caller_sa_email == "" ? 0 : 1
  project = module.project_factory.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${var.caller_sa_email}"
}

################################################################################
# Test Resource A: One GCS bucket in the project
################################################################################

resource "random_id" "suffix" {
  byte_length = 2
}

resource "google_storage_bucket" "one_bucket" {
  name                        = "${module.project_factory.project_id}-bkt-${random_id.suffix.hex}"
  project                     = module.project_factory.project_id
  location                    = var.bucket_location
  uniform_bucket_level_access = true
  force_destroy               = true

  lifecycle_rule {
    action    { type = "Delete" }
    condition { age = 30 }
  }
}

output "bucket_name" {
  value       = google_storage_bucket.one_bucket.name
  description = "Name of the bucket created in the project."
}

output "bucket_url" {
  value       = "gs://${google_storage_bucket.one_bucket.name}"
  description = "gs:// URL of the bucket."
}

################################################################################
# Test Resource B (optional): Persistent Disk
################################################################################

resource "google_compute_disk" "test_pd" {
  count   = var.enable_persistent_disk ? 1 : 0
  name    = "${module.project_factory.project_id}-pd-${var.disk_size_gb}g"
  project = module.project_factory.project_id
  zone    = var.disk_zone
  type    = var.disk_type
  size    = var.disk_size_gb
}

output "test_pd_self_link" {
  value       = try(google_compute_disk.test_pd[0].self_link, null)
  description = "Self link for the test persistent disk (only when enabled)."
}
