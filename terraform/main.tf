provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# 1. VPC
resource "google_compute_network" "spark_vpc" {
  name                    = "spark-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "spark_subnet" {
  name          = "spark-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.spark_vpc.id
}

# 2. Firewalls
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

resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.spark_vpc.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "allow_spark_ui" {
  name    = "allow-spark-ui"
  network = google_compute_network.spark_vpc.name
  allow {
    protocol = "tcp"
    ports    = ["8080", "4040"]
  }
  source_ranges = ["0.0.0.0/0"]
}

# 3. Instances
# Master Node
resource "google_compute_instance" "spark_master" {
  name         = "spark-master"
  machine_type = "e2-medium"
  allow_stopping_for_update = true
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }
network_interface {
    subnetwork = google_compute_subnetwork.spark_subnet.id
    network_ip = "10.0.1.10"
    access_config {}
  }
  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_pub_key_path)}"
  }
  
  service_account {
    scopes = ["cloud-platform"]
  }
}

# Worker Node
resource "google_compute_instance" "spark_worker_1" {
  name         = "spark-worker-1"
  machine_type = "e2-medium"
  allow_stopping_for_update = true
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.spark_subnet.id
    access_config {}
  }
  service_account {
    scopes = ["cloud-platform"]
  }
  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_pub_key_path)}"
  }
}

resource "google_compute_instance" "spark_worker_2" {
  name         = "spark-worker-2"
  machine_type = "e2-medium"
  allow_stopping_for_update = true
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.spark_subnet.id
    access_config {}
  }
  service_account {
    scopes = ["cloud-platform"]
  }
  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_pub_key_path)}"
  }
}

# ADD THIS BLOCK
resource "google_compute_instance" "spark_worker_3" {
  name         = "spark-worker-3"
  machine_type = "e2-medium"
  allow_stopping_for_update = true
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.spark_subnet.id
    access_config {}
  }
  service_account {
    scopes = ["cloud-platform"]
  }
  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_pub_key_path)}"
  }
  
}

# Edge Node
resource "google_compute_instance" "spark_edge" {
  name         = "spark-edge"
  machine_type = "e2-small"
  allow_stopping_for_update = true
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }
  network_interface {
    subnetwork = google_compute_subnetwork.spark_subnet.id
    access_config {}
  }
  service_account {
    scopes = ["cloud-platform"]
  }
  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_pub_key_path)}"
  }
}

# Outputs
output "master_ip" {
  value = google_compute_instance.spark_master.network_interface.0.access_config.0.nat_ip
}
output "worker_ip" {
  value = google_compute_instance.spark_worker_1.network_interface.0.access_config.0.nat_ip
}
output "edge_ip" {
  value = google_compute_instance.spark_edge.network_interface.0.access_config.0.nat_ip
}
output "worker_2_ip" {
  value = google_compute_instance.spark_worker_2.network_interface.0.access_config.0.nat_ip
}
output "worker_3_ip" {
  value = google_compute_instance.spark_worker_3.network_interface.0.access_config.0.nat_ip
}