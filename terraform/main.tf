resource "google_compute_instance" "test_vm" {
  name         = "terraform-test-vm"
  machine_type = "e2-micro"
  zone         = var.zone

  tags = ["terraform-test"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "default"
    access_config {
    }
  }

  labels = {
    purpose = "terraform-practice"
  }

  metadata_startup_script = replace(file("startup.sh"), "__DEPLOY_KEY_PLACEHOLDER__", var.vm_deploy_key)
}