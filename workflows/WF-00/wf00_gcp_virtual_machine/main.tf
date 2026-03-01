locals {
  effective_count = var.enable_vms ? var.vm_count : 0
  name_prefix     = "${var.project_id}-vm"
}

resource "google_compute_instance" "vm" {
  count        = local.effective_count
  name         = "${local.name_prefix}-${count.index + 1}"
  machine_type = var.vm_machine_type
  zone         = var.vm_zone
  tags         = var.vm_tags

  boot_disk {
    initialize_params {
      image = var.vm_image
      size  = var.vm_disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = var.subnet_self_link

    # Add a public IP only when enabled
    dynamic "access_config" {
      for_each = var.enable_public_ip ? [1] : []
      content {}
    }
  }

  metadata = {
    "enable-oslogin" = "TRUE"
  }
}
