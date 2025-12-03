<h3 align="left">
  <img width="600" height="128" alt="image" src="https://raw.githubusercontent.com/artemis-env0/Packages/refs/heads/main/Images/Logo%20Pack/01%20Main%20Logo/Digital/SVG/envzero_logomark_fullcolor_rgb.svg" />
</h3>
---

Deploy using OpenTofu + Google Project Factory (GPF) + env0
----
##  EnvZero | Demo Package

This repository demonstrates a minimal, **env0-driven** workflow that:

- Uses **OpenTofu** to call **Google Project Factory v18**
- **Creates a brand-new GCP project**
- **Deploys a single test resource** (default: a **GCS bucket**) in that new project
- *(Optional)* also creates a **Compute Persistent Disk (PD)**
- *(Optional)* grants your env0 runner **service account** a role in the newly created project

> You can run this in **env0** (recommended) or locally with **OpenTofu**.

---

### Prerequisites

- A **bootstrap GCP project** for provider auth/lookups (e.g., `env0-bootstrap-...`)
- A **service account (SA)** in the bootstrap project with a **JSON key** (store in env0 as `GOOGLE_CREDENTIALS`)
- Core APIs **enabled once** in the **bootstrap** project:
  - `cloudresourcemanager.googleapis.com`
  - `serviceusage.googleapis.com`
  - `iam.googleapis.com`
  - `cloudbilling.googleapis.com`
- The SA should ultimately have:
  - On **Org** or **Folder** scope (choose one):  
    `roles/resourcemanager.projectCreator`, `roles/serviceusage.serviceUsageAdmin`, `roles/iam.serviceAccountAdmin`, and a viewer role for that scope (`organizationViewer` or `folderViewer`)
  - On **Billing Account**: `roles/billing.user`
  - On **Bootstrap Project** (only if you want TF to manage bootstrap services): `roles/serviceusage.serviceUsageAdmin` + `roles/viewer`

> You can wire up env0 and run **Plan** today; **Apply** will succeed once those grants are in place.

---

### What this deploys

- **New GCP project** via `terraform-google-modules/project-factory/google` (v18)
- **One GCS bucket** in that new project
- *(Optional)* **Compute Persistent Disk** (zonal)
- *(Optional)* Project-level IAM for the env0 runner SA (e.g., `roles/editor`)

---

### Quick Start (env0)

1. **Connect this repo** to an env0 **Project** → create a new **Environment**.
2. In env0 **Environment Variables**:
   - **Secret**  
     - `GOOGLE_CREDENTIALS` → paste your SA JSON
   - **Plain**  
     - `ENV0_OPENTOFU_VERSION = 1.7.0`
     - `TF_VAR_bootstrap_project_id = <your-bootstrap-project-id>`
     - `TF_VAR_billing_account = 000000-000000-000000`
     - **Exactly one** of:
       - `TF_VAR_org_id = 123456789012` **(leave `TF_VAR_folder_id` empty)**, **or**
       - `TF_VAR_folder_id = folders/123456789012` **(leave `TF_VAR_org_id` empty)**
     - *(Optional)* `TF_VAR_project_name_prefix = env0-tofu-gpf`
     - *(Optional)* `TF_VAR_bucket_location = US`
     - *(Optional)* `TF_VAR_region = us-central1`
     - *(Optional)* `TF_VAR_enable_persistent_disk = false|true`
     - *(Optional)* `TF_VAR_disk_zone = us-central1-a`
     - *(Optional)* `TF_VAR_disk_type = pd-standard`
     - *(Optional)* `TF_VAR_disk_size_gb = 10`
     - *(Optional, recommended)* `TF_VAR_caller_sa_email = <the same SA email from GOOGLE_CREDENTIALS>`
3. Click **Plan**, then **Apply**.  
   The pipeline prints the caller SA email, validates required inputs, and shows outputs after apply.

---

### Files to Copy

#### `env0.yaml`
```yaml
version: 2
shell: bash

deploy:
  steps:
    setupVariables:
      after:
        - name: Print tool versions
          run: |
            echo "=== Tool versions ==="
            tofu version || true
            jq --version || true
            echo "ENV0_OPENTOFU_VERSION=${ENV0_OPENTOFU_VERSION:-unset}"

        - name: Show caller SA email from GOOGLE_CREDENTIALS
          run: |
            if [ -z "${GOOGLE_CREDENTIALS}" ]; then
              echo "GOOGLE_CREDENTIALS is empty or not set!" 1>&2
              exit 1
            fi
            SA_EMAIL="$(echo "$GOOGLE_CREDENTIALS" | jq -r '.client_email')"
            if [ -z "$SA_EMAIL" ] || [ "$SA_EMAIL" = "null" ]; then
              echo "Could not parse client_email from GOOGLE_CREDENTIALS" 1>&2
              exit 1
            fi
            echo "Caller SA email: $SA_EMAIL"

        - name: Echo key Terraform vars
          run: |
            echo "bootstrap_project_id=${TF_VAR_bootstrap_project_id:-unset}"
            echo "billing_account=${TF_VAR_billing_account:-unset}"
            echo "org_id=${TF_VAR_org_id:-<empty>}"
            echo "folder_id=${TF_VAR_folder_id:-<empty>}"
            echo "project_name_prefix=${TF_VAR_project_name_prefix:-unset}"
            echo "bucket_location=${TF_VAR_bucket_location:-unset}"
            echo "region=${TF_VAR_region:-unset}"
            echo "enable_persistent_disk=${TF_VAR_enable_persistent_disk:-unset}"
            echo "disk_zone=${TF_VAR_disk_zone:-unset}"

        - name: Validate required inputs
          run: |
            REQUIRED=( TF_VAR_bootstrap_project_id TF_VAR_billing_account )
            ONE_OF=( TF_VAR_org_id TF_VAR_folder_id )
            missing=0

            for v in "${REQUIRED[@]}"; do
              if [ -z "${!v}" ]; then echo "Missing required variable: $v" 1>&2; missing=1; fi
            done

            count_one_of=0
            for v in "${ONE_OF[@]}"; do
              [ -n "${!v}" ] && count_one_of=$((count_one_of+1))
            done
            if [ "$count_one_of" -ne 1 ]; then
              echo "Exactly one of TF_VAR_org_id or TF_VAR_folder_id must be set (not both / not none)." 1>&2
              missing=1
            fi

            if [ "$missing" -ne 0 ]; then
              exit 1
            fi

    terraformApply:
      after:
        - name: Print outputs (JSON)
          run: |
            echo "=== OpenTofu outputs (JSON) ==="
            tofu output -json || true
```
----

#### 'Providers.tf'
````hcl
terraform {
  required_version = ">= 1.3.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Provider uses the existing bootstrap project (not the new one)
provider "google" {
  project = var.bootstrap_project_id
  region  = var.region
}
````
----

#### 'Variables.tf'
````hcl

# Provider / bootstrap

variable "bootstrap_project_id" {
  description = "Existing project used by the google provider for auth/lookups."
  type        = string
}

variable "region" {
  description = "Default region for provider context."
  type        = string
  default     = "us-central1"
}


# Org / folder / billing

variable "org_id" {
  description = "Organization ID (leave empty if using folder_id)."
  type        = string
  default     = ""
}

variable "folder_id" {
  description = "Folder ID in the form 'folders/123456789012' (leave empty if using org_id)."
  type        = string
  default     = ""
}

variable "billing_account" {
  description = "Billing account ID (e.g., 000000-000000-000000)."
  type        = string
}


# Convenience / naming

variable "project_name_prefix" {
  description = "Prefix for the new project's display name."
  type        = string
  default     = "env0-tofu-gpf"
}


# APIs to enable in NEW project

variable "activate_apis" {
  description = "APIs to enable in the new project."
  type        = list(string)
  default = [
    "cloudresourcemanager.googleapis.com",
    "serviceusage.googleapis.com",
    "iam.googleapis.com",
    "storage.googleapis.com",
    "compute.googleapis.com" # needed if you enable the persistent disk
  ]
}


# Optional: grant runner SA access

variable "caller_sa_email" {
  description = "Service account email used by env0 (to grant project-level role). Leave empty to skip."
  type        = string
  default     = ""
}


# Bucket settings

variable "bucket_location" {
  description = "Bucket location/region or multi-region (e.g., US, EU, us-central1)."
  type        = string
  default     = "US"
}


# Persistent Disk (optional)

variable "enable_persistent_disk" {
  description = "Set true to create a test persistent disk in the new project."
  type        = bool
  default     = false
}

variable "disk_zone" {
  description = "Zone for the test persistent disk (must match your region family)."
  type        = string
  default     = "us-central1-a"
}

variable "disk_type" {
  description = "Disk type: pd-standard | pd-balanced | pd-ssd."
  type        = string
  default     = "pd-standard"
}

variable "disk_size_gb" {
  description = "Disk size in GB."
  type        = number
  default     = 10
}
````
----

#### 'Main.tf'
````hcl

# Sanity: who am I?


data "google_client_openid_userinfo" "me" {}

output "whoami_email" {
  value       = data.google_client_openid_userinfo.me.email
  description = "Authenticated principal email from GOOGLE_CREDENTIALS."
}


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
}

output "test_pd_self_link" {
  value       = try(google_compute_disk.test_pd[0].self_link, null)
  description = "Self link for the test persistent disk (only when enabled)."
}
````
----

#### 'Outputs.tf'
````hcl
# (Left intentionally empty : outputs are defined in main.tf) > artem@env0 was here

````
----

#### '.gitignore'
````gitignore
# OpenTofu/Terraform local files
.terraform/
.terraform.lock.hcl
*.tfstate
*.tfstate.*
crash.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json

# Keys (never commit)
*.json
*.pem
*.p12
````
----

### Debugging 
#### Running this locally

````bash
# 1) Set credentials (same SA used in env0)
export GOOGLE_CREDENTIALS="$(cat ./env0-gpf-admin.json)"
# or export GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json

# 2) Initialize and plan
tofu init
tofu plan

# 3) Apply
tofu apply

# 4) See outputs
tofu output

````
----

# README : Outputs, Troubleshooting, and Useful Commands

This document summarizes the key **outputs**, **common errors & fixes**, and a few **utility commands** for the env0 + OpenTofu + Google Project Factory deployment.

---

### Outputs

- **whoami_email** : the authenticated principal (from `GOOGLE_CREDENTIALS`)
- **created_project_id** : ID of the newly created project
- **created_project_number** : number of the newly created project
- **bucket_name** : created bucket name
- **bucket_url** : `gs://…`
- **test_pd_self_link** : self link of optional Persistent Disk (null if disabled)

---

### Common Errors & Fixes

#### `SERVICE_DISABLED: Cloud Billing API has not been used in project …`
Enable **Cloud Billing API** (and other core APIs) **in the bootstrap project**:

```bash
gcloud services enable cloudbilling.googleapis.com \
  --project "<bootstrap-project-id>"
```
----

# Troubleshooting & Quick Commands : env0 + OpenTofu + Google Project Factory

This README captures concise fixes and commands for common permission-related issues, plus quick validation steps.

---

### Error: `AUTH_PERMISSION_DENIED` from `serviceusage.googleapis.com`

**Cause:**  
The runner Service Account (SA) cannot list/enable services on the project it targets. For **bootstrap** API management, grant:

- `roles/serviceusage.serviceUsageAdmin`
- `roles/viewer`

**Commands (replace placeholders):**

    gcloud projects add-iam-policy-binding "<bootstrap-project-id>" \
      --member="serviceAccount:<sa-email>" \
      --role="roles/serviceusage.serviceUsageAdmin"

    gcloud projects add-iam-policy-binding "<bootstrap-project-id>" \
      --member="serviceAccount:<sa-email>" \
      --role="roles/viewer"

**Alternative:**  
Remove bootstrap API management from Terraform and enable those APIs **once** manually.

---

### Error: Project creation / billing link denied

**Fix:** Grant the runner SA these roles:

- **On Org/Folder**  
  - `roles/resourcemanager.projectCreator`  
  - `roles/serviceusage.serviceUsageAdmin`  
  - `roles/iam.serviceAccountAdmin`  
  - A viewer role for that scope (`roles/resourcemanager.organizationViewer` or `roles/resourcemanager.folderViewer`)
- **On Billing account**  
  - `roles/billing.user`

---

### Double-check which SA env0 is using

Add this step to your `env0.yaml` to print the caller SA email at runtime:

    - name: Show caller SA email
      run: echo "$GOOGLE_CREDENTIALS" | jq -r '.client_email'

---

### Example: Query the Bucket After Deploy

    # Replace with the output value
    BUCKET="<created-bucket-name>"
    gsutil ls "gs://${BUCKET}"

---

### Cleanup

From **env0**, click **Destroy** on the environment.  
This removes the bucket, optional PD, and the newly created project (via Project Factory).

---

### FAQ

**Q: Can I use OpenTofu with the upstream Terraform modules?**  
**A:** Yes. Google Project Factory v18 is tested with Terraform 1.10+ and works with OpenTofu in practice. Pin the **Google provider `~> 7.0`**.

**Q: Do I need `org_id`?**  
**A:** No. You can use **`folder_id`** if your org delegates via folders.

**Q: Where do I get `caller_sa_email`?**  
**A:** It’s the `client_email` in your `GOOGLE_CREDENTIALS` JSON (the same SA the pipeline uses).
