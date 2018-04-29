data "template_file" "docker-registry-config" {
  template = "${file("applications/docker-registry/config.yaml.tpl")}"

  vars {
    spaces_accesskey = "${var.spaces_accesskey}"
    spaces_secretkey = "${var.spaces_secretkey}"
    spaces_region = "${var.spaces_region}"
    spaces_bucket = "${var.spaces_bucket}"
    spaces_root = "${var.spaces_root}"
    registry_port = "${var.registry_port}"
  }
}

data "template_file" "docker-registry-init" {
  template = "${file("applications/docker-registry/init.sh.tpl")}"

  vars {
    domain_name = "${var.domain_name}"
  }
}

data "template_file" "nginx-config" {
  template = "${file("applications/nginx/reverseproxy.config")}"

  vars {
    domain_name = "${var.domain_name}"
    delimited_domain_name = "${var.delimited_domain_name}"
  }
}