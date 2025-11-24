# Stage 1 > Sanity Check: who am I authenticated as?
data "google_client_openid_userinfo" "me" {}

output "whoami_email" {
  value       = data.google_client_openid_userinfo.me.email
  description = "Authenticated principal email from GOOGLE_CREDENTIALS."
}

# Stage 2 > Small random suffix for the bucket name
resource "random_id" "suffix" {
  byte_length = 2
}

# Stage 3 > Project Factory: create a NEW project ----
module "project_factory" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 18.0"

  # choose either org_id or folder_id; leave the other as empty string
  org_id    = var.org_id != "" ? var.org_id : null
  folder_id = var.folder_id != "" ? var.folder_id : null

  name              = var.project_name_prefix
  billing_account   = var.billing_account
  random_project_id = true

  # enable the APIs we need for our single resource (bucket) + basics
  activate_apis = var.activate_apis

  # safer default SA posture in the new project
  default_service_account = "deprivilege"
}

# convenient outputs for the created project
output "created_project_id" {
  value       = module.project_factory.project_id
  description = "ID of the newly created project."
}

output "created_project_number" {
  value       = module.project_factory.project_number
  description = "Number of the newly created project."
}

# Stage 4 > Single resource in the NEW project: one GCS bucket ----
# we set project at the resource level (can't use outputs inside provider blocks)
resource "google_storage_bucket" "one_bucket" {
  name                        = "${module.project_factory.project_id}-bkt-${random_id.suffix.hex}"
  project                     = module.project_factory.project_id
  location                    = var.bucket_location
  uniform_bucket_level_access = true
  force_destroy               = true
  lifecycle_rule {
    action { type = "Delete" }
    condition {
      age = 30
    }
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
