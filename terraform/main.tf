provider "google" {
  project = "heroic-overview-478821-n0"
  region  = "us-central1"
  zone    = "us-central1-a"
}

# 1. Create a Custom Network (VPC)
resource "google_compute_network" "spark_vpc" {
  name                    = "spark-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "spark_subnet" {
  name          = "spark-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.spark_vpc.id
}

# 2. Firewall Rules
# Allow internal traffic between Master and Workers
resource "google_compute_firewall" "allow_internal" {
  name    = "allow-internal"
  network = google_compute_network.spark_vpc.name

  allow {
    protocol = "icmp"
  }
  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }
  source_ranges = ["10.0.1.0/24"]
}

# Allow SSH from the outside world
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.spark_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

# Allow Spark UI (8080)
resource "google_compute_firewall" "allow_spark_ui" {
  name    = "allow-spark-ui"
  network = google_compute_network.spark_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["8080", "4040"]
  }
  source_ranges = ["0.0.0.0/0"]
}

# 3. VM Instances
# Spark Master
resource "google_compute_instance" "spark_master" {
  name         = "spark-master"
  machine_type = "e2-medium"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.spark_subnet.id
    access_config {}
  }

  metadata = {
    ssh-keys = "ubuntu:${file("../keys/spark_key.pub")}"
  }
}

# Spark Worker
resource "google_compute_instance" "spark_worker_1" {
  name         = "spark-worker-1"
  machine_type = "e2-medium"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.spark_subnet.id
    access_config {}
  }

  metadata = {
    ssh-keys = "ubuntu:${file("../keys/spark_key.pub")}"
  }
}

# Spark Edge
resource "google_compute_instance" "spark_edge" {
  name         = "spark-edge"
  machine_type = "e2-small"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.spark_subnet.id
    access_config {}
  }

  metadata = {
    ssh-keys = "ubuntu:${file("../keys/spark_key.pub")}"
  }
}

# Output IPs
output "master_ip" {
  value = google_compute_instance.spark_master.network_interface.0.access_config.0.nat_ip
}
output "worker_ip" {
  value = google_compute_instance.spark_worker_1.network_interface.0.access_config.0.nat_ip
}
output "edge_ip" {
  value = google_compute_instance.spark_edge.network_interface.0.access_config.0.nat_ip
}