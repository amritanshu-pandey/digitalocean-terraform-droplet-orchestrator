# Terraform DigitalOcean Droplet Orchestrator

Create Pre-Provisioned DigitalOcean droplets and associated firewalls and
domain name associations using Terraform.

## Prerequisites 
- Terraform binary installed on client machine ([download here](https://www.terraform.io/downloads.html))
- DigitalOcean API key ([Refer to this link for generating API key](https://www.digitalocean.com/community/tutorials/how-to-use-the-digitalocean-api-v2))

## How to provision DIgitalocean droplets
- Clone this git repo
```bash
git clone git@github.com:amritanshu-pandey/digitalocean-terraform-droplet-orchestrator.git
```
- Copy file `terraform.tfvars.sample` as `terraform.vars` at the same path
and fill the required information.
- Execute command `terraform validate` to check for any mistakes in terraform files
- Execute command `terraform plan -out plan.out` to generate the execution plan and
save the same in a file named `plan.out`
- Execute command `terraform apply "plan.out"` to provision droplet and other
resources as specified in file `resource.tf`