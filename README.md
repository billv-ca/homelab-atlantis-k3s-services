# homelab-k3s-services
This repo exists as part of the bbl232/homelab-* series of repositories containing IaC and documentation for my homelab.

This repo contains parts of the homelab running in Kubernetes that sould be applied after the `base-services` contained in a separate repo.

## Usage
This repo (once applied initially manually) is managed by Atlantis and upgraded automatically by renovatebot. To manually apply changes, read on.

### Manual usage
#### Prerequisites
Credentials must be in place for `Kubernetes` and `AWS` in your environment. Additionally there must be a variable in your environment containing the secret for Authentik to use as it's API key. This variable should be set as `TF_VAR_authentik_api_key=<value>`. Finally, you need a variabl in your environment indicating the path to your Kubernetes config such as `KUBE_CONFIG_PATH=~/.kube/config`. These variables can automatically be added to your environment by running `source setup_env.sh`


#### Terraform
To apply the terraform, once the pre-requesites are met, simply run the following
```sh
terraform init
terraform plan #to preview changes (optional, apply will be interactive anyway)
terraform apply
```