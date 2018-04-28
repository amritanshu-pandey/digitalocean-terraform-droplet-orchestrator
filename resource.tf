variable "droplet_name" {}
variable "droplet_image" {}
variable "droplet_region" {}
variable "droplet_size" {}
variable "droplet_ssh_keys_fingerprints" {}
variable "firewall_name" {}
variable "domain_name" {}
variable "ssh_client_private_key" {}
variable "primary_user_name" {}
variable "ssh_client_pub_key" {}

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
      "set -eu",

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
      "sudo apt install curl git neofetch vim wget -y",
      
      "#Install Docker",
      <<EOF
      sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        software-properties-common
        
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu artful stable"

        sudo apt-get update

        sudo apt-get install -y docker-ce docker-compose
      EOF
      ,

      "echo - Create user, setup ssh public key and add to group docker",
      "sudo useradd -m -s /bin/bash ${var.primary_user_name}",
      "sudo echo '${var.primary_user_name} ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/${var.primary_user_name}",
      "mkdir -p /home/amritanshu/.ssh",
      "echo '${var.ssh_client_pub_key}' >> /home/${var.primary_user_name}/.ssh/authorized_keys",
      "chown -R ${var.primary_user_name}:${var.primary_user_name} /home/${var.primary_user_name}/.ssh",
      "chmod -R 700 /home/${var.primary_user_name}/.ssh",
      "usermod -aG docker ${var.primary_user_name}",
      "cp /root/information.txt /home/${var.primary_user_name}/",
      "echo '\nneofetch\n' >> /home/${var.primary_user_name}/.bashrc",
      "chown ${var.primary_user_name}:${var.primary_user_name} /home/${var.primary_user_name}/information.txt",
      "echo - user ${var.primary_user_name} setup succesfully",

      "echo - disable root ssh access",
      "sed -i 's/PermitRootLogin yes/PermitRootLogin No/g' /etc/ssh/sshd_config",
      "echo - root ssh access will be disabled upon reboot"
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

