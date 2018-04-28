variable "droplet_name" {}
variable "droplet_image" {}
variable "droplet_region" {}
variable "droplet_size" {}
variable "droplet_ssh_keys_fingerprints" {}
variable "firewall_name" {}
variable "domain_name" {}
variable "ssh_client_private_key" {}

resource "digitalocean_droplet" "droplet1" {
  image		= "${var.droplet_image}"
  name		= "${var.droplet_name}"
  region	= "${var.droplet_region}"
  size		= "${var.droplet_size}"
  ssh_keys	= ["${var.droplet_ssh_keys_fingerprints}"]

  connection {
    user          = "root"
    type          = "ssh"
    private_key   = "${var.ssh_client_private_key}"
    timeout       = "2m"
  }

  provisioner "remote-exec" {
    inline = [
      "#!/bin/bash",

      "# Create Information.txt",
      "echo 'Name: ${digitalocean_droplet.droplet1.name}' >> ~/information.txt",
      "echo 'ID: ${digitalocean_droplet.droplet1.id}' >> ~/information.txt",
      "echo 'Region: ${digitalocean_droplet.droplet1.region}' >> ~/information.txt",
      "echo 'Image: ${digitalocean_droplet.droplet1.image}' >> ~/information.txt",
      "echo 'IPV4: ${digitalocean_droplet.droplet1.ipv4_address}' >> ~/information.txt",
      "echo 'Price (Hourly): ${digitalocean_droplet.droplet1.price_hourly}' >> ~/information.txt",
      "echo 'Price (Monthly): ${digitalocean_droplet.droplet1.price_monthly}' >> ~/information.txt",
      "echo 'Size: ${digitalocean_droplet.droplet1.size}' >> ~/information.txt",
      "echo 'Disk: ${digitalocean_droplet.droplet1.disk}' >> ~/information.txt",
      "echo 'VCPUs: ${digitalocean_droplet.droplet1.vcpus}' >> ~/information.txt",

      "# Update repo and OS",
      "sudo apt update",
      "sudo apt dist-upgrade -y",

      "# Install softwares",
      "sudo apt install curl git wget build-essential -y",
      "curl https://get.docker.com | bash"
    ]
  }
}

resource "digitalocean_firewall" default {
  name = "${var.firewall_name}"
  droplet_ids = ["${digitalocean_droplet.droplet1.id}"]

  inbound_rule = [
    {
      protocol		= "tcp"
      port_range	= "22"
    }
]
}

resource "digitalocean_domain" "default" {
  name		= "${var.domain_name}"
  ip_address	= "${digitalocean_droplet.droplet1.ipv4_address}"
}

