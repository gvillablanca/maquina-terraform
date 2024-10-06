provider "google" {
  credentials = file("<ruta_a_tu_archivo_json_de_credenciales>")
  project     = "<tu_proyecto>"
  region      = "us-central1"  # Cambia la región si lo necesitas
  zone        = "us-central1-a"
}

resource "google_compute_network" "vpc_network" {
  name = "vpc-network"
}

resource "google_compute_instance" "vm_instance" {
  name         = "terraform-vm"
  machine_type = "n1-standard-1"
  zone         = "us-central1-a"  # O la zona de tu elección

  # Conecta la instancia a la red
  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
      # Por defecto, obtiene una IP pública
    }
  }

  # Especifica la imagen que quieres usar para la máquina
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  # Metadata opcional para configurar la VM en su creación
  metadata = {
    startup-script = <<-EOT
      #! /bin/bash
      echo "Hello, Terraform!" > /var/www/html/index.html
    EOT
  }

  tags = ["web", "dev"]

  # Etiquetas de firewall para permitir tráfico HTTP/HTTPS
  metadata_startup_script = <<-EOT
    #! /bin/bash
    sudo apt-get update
    sudo apt-get install -y apache2
    sudo systemctl start apache2
    sudo systemctl enable apache2
  EOT
}

resource "google_compute_firewall" "default-allow-http" {
  name    = "allow-http"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]
}
