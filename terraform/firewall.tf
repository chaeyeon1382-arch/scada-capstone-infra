resource "google_compute_firewall" "allow_ssh" {
  name    = "terraform-allow-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["terraform-test"]
}

resource "google_compute_firewall" "allow_http" {
  name    = "terraform-allow-http"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["terraform-test"]
}

resource "google_compute_firewall" "allow_fastapi" {
  name    = "terraform-allow-fastapi"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["terraform-test"]
}