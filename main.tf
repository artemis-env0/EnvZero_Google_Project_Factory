# Bootstrap sanity + APIs in provider project
# -------------------------------------------
# Who am I?

data "google_client_openid_userinfo" "me" {}

output "whoami_email" {
  value       = data.google_client_openid_userinfo.me.email
  description = "Authenticated principal email from GOOGLE_CREDENTIALS."
}

# Make sure required APIs are ON in the BOOTSTRAP project (provider context)
## Commented Out > Debugging (AGA) - Uncomment when going live [Likely SA Doesn't have Perms]
/*
resource "google_project_service" "bootstrap_services" {
  for_each = toset([
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "iam.googleapis.com",
    "cloudbilling.googleapis.com",
  ])
  project            = var.bootstrap_project_id
  service            = each.key
  disable_on_destroy = false
}
*/

# Create a NEW project via Project Factory v18

module "project_factory" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 18.0"

  # choose exactly one: org_id or folder_id (the other stays null)
  org_id    = var.org_id != "" ? var.org_id : null
  folder_id = var.folder_id != "" ? var.folder_id : null

  name              = var.project_name_prefix
  billing_account   = var.billing_account
  random_project_id = true

  # enable APIs in the NEW project (for our test resources)
  activate_apis = var.activate_apis

  # safer default SA posture
  default_service_account = "deprivilege"

  depends_on = [google_project_service.bootstrap_services]
}

output "created_project_id" {
  value       = module.project_factory.project_id
  description = "ID of the newly created project."
}

output "created_project_number" {
  value       = module.project_factory.project_number
  description = "Number of the newly created project."
}

# Optional: ensure env0 SA can manage the new project

resource "google_project_iam_member" "grant_editor_to_caller" {
  count   = var.caller_sa_email == "" ? 0 : 1
  project = module.project_factory.project_id
  role    = "roles/editor" # tighten to specific roles if you prefer
  member  = "serviceAccount:${var.caller_sa_email}"

  depends_on = [module.project_factory]
}

# Test Resource A: One GCS bucket in NEW project

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
    action { type = "Delete" }
    condition { age = 30 }
  }

  depends_on = [module.project_factory]
}

output "bucket_name" {
  value       = google_storage_bucket.one_bucket.name
  description = "Name of the bucket created in the new project."
}

output "bucket_url" {
  value       = "gs://${google_storage_bucket.one_bucket.name}"
  description = "gs:// URL of the bucket."
}

# Test Resource B (optional): Persistent Disk

resource "google_compute_disk" "test_pd" {
  count   = var.enable_persistent_disk ? 1 : 0
  name    = "${module.project_factory.project_id}-pd-${var.disk_size_gb}g"
  project = module.project_factory.project_id
  zone    = var.disk_zone
  type    = var.disk_type
  size    = var.disk_size_gb

  depends_on = [module.project_factory]
}

output "test_pd_self_link" {
  value       = try(google_compute_disk.test_pd[0].self_link, null)
  description = "Self link for the test persistent disk (only when enabled)."
}
