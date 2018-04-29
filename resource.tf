
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
      "echo Created: $(date) >> ~/information.txt",

      "# Update repo and OS",
      "sudo apt update",
      "sudo apt dist-upgrade -y",

      "# Install softwares",
      "sudo apt install apache2-utils curl git neofetch nginx vim wget -y",
      
      "#Install Docker",
      <<EOF
      sudo apt-get install -y \
        apt-transport-https \
        ca-certificates \
        software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu artful stable"
        sudo apt-get update -y
        sudo apt-get install -y docker-ce docker-compose
      EOF
      ,

      "#Create user, setup ssh public key and add to group docker",
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

      "#disable root ssh access",
      "sed -i 's/PermitRootLogin yes/PermitRootLogin No/g' /etc/ssh/sshd_config",
      "echo - root ssh access will be disabled upon reboot",

      "#install letsencrypt",
      "git clone https://github.com/letsencrypt/letsencrypt /opt/letsencrypt",
      "echo - letsencrypt installed",
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
    },
    {
      protocol		= "tcp"
      port_range	= "80"
    }
]
}

resource "digitalocean_domain" "default" {
  name		= "${var.domain_name}"
  ip_address	= "${digitalocean_droplet.droplet1.ipv4_address}"
}

resource "digitalocean_record" "registry" {
  domain = "${digitalocean_domain.default.name}"
  type   = "A"
  name   = "registry"
  value  = "${digitalocean_droplet.droplet1.ipv4_address}"
}

resource "digitalocean_record" "portainer" {
  domain = "${digitalocean_domain.default.name}"
  type   = "A"
  name   = "portainer"
  value  = "${digitalocean_droplet.droplet1.ipv4_address}"
}

resource "digitalocean_record" "www" {
  domain = "${digitalocean_domain.default.name}"
  type   = "A"
  name   = "www"
  value  = "${digitalocean_droplet.droplet1.ipv4_address}"
}

resource "null_resource" "configure_droplet1" {

  connection {
    user = "root"
    host = "${digitalocean_droplet.droplet1.ipv4_address}"
    private_key="${var.ssh_client_private_key}"
    timeout = "3m"
  }
# Provisioning to be done after domain setup
provisioner "remote-exec" {
    inline = [
      "#!/bin/bash",
      "echo - generate SSL certificate for domain ${var.domain_name}",
      "sudo systemctl stop nginx",
      "echo 'N' | sudo /opt/letsencrypt/letsencrypt-auto certonly --agree-tos --keep-until-expiring --non-interactive --standalone -d ${var.domain_name} -d ${var.registry_domain_name} -d ${var.portainer_domain_name} --keep --expand --email ${var.letsencrypt_email}",
      "sudo mkdir /srv/docker-registry",
      "sudo mkdir /srv/portainer",
      "sudo mkdir /srv/nginx",
      <<EOF
      # Setup letsencrypt certificates renewing
      line="30 2 * * 1 /opt/letsencrypt/letsencrypt-auto renew >> /var/log/letsencrypt-renew.log"
      (crontab -u root -l; echo "$line" ) | crontab -u root -

      # Rename SSL certificates
      # https://community.letsencrypt.org/t/how-to-get-crt-and-key-files-from-i-just-have-pem-files/7348
      cd /etc/letsencrypt/live/${var.domain_name}/
      cp privkey.pem domain.key
      cat cert.pem chain.pem > domain.crt

      # Set credentials for docker registry
      sudo mkdir /auth
      sudo htpasswd -nbB ${var.docker_user} ${var.docker_password} > /auth/htpasswd
      EOF
      ,
    ]
  }

  provisioner "file" {
    content      = "${data.template_file.docker-registry-config.rendered}"
    destination = "/srv/docker-registry/config.yaml"
  }

  provisioner "file" {
    source      = "applications/portainer/init.sh"
    destination = "/srv/portainer/init.sh"
  }

  provisioner "file" {
    content      = "${data.template_file.nginx-config.rendered}"
    destination = "/etc/nginx/sites-available/default"
  }

}