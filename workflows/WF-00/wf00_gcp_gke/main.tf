locals {
  effective_cluster_name = var.gke_cluster_name != "" ? var.gke_cluster_name : "${var.project_id}-gke"
  create_count           = var.enable_gke ? 1 : 0
}

resource "google_container_cluster" "cluster" {
  count    = local.create_count
  name     = local.effective_cluster_name
  location = var.gke_location

  network    = var.network_self_link
  subnetwork = var.subnet_self_link

  # Use a separate node pool resource
  remove_default_node_pool = true
  initial_node_count       = 1

  # Let GKE allocate secondary ranges automatically (VPC-native)
  ip_allocation_policy {}

  release_channel {
    channel = var.gke_release_channel
  }

  # Reasonable defaults for a demo
  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  deletion_protection = false
}

resource "google_container_node_pool" "primary" {
  count    = local.create_count
  name     = "${local.effective_cluster_name}-np"
  location = var.gke_location
  cluster  = google_container_cluster.cluster[0].name

  node_count = var.gke_node_count

  node_config {
    machine_type = var.gke_machine_type
    disk_size_gb = var.gke_disk_size_gb

    # Keep nodes with minimal broad scope. Adjust later if workloads need more.
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

    labels = {
      env0_workflow = "wf-00"
      component     = "gke"
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
