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

# This provider is only used for auth & lookups.
# We point it at a *bootstrap* project you already have.
provider "google" {
  project = var.bootstrap_project_id
  region  = var.region
}
