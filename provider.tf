variable "do_token" {} # Export DO token in an env variable named TF_VAR_do_token

provider "digitalocean" {
  token = "${var.do_token}"
}
