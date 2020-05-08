variable "name" {
  description = "Application name"
  type        = string
}

variable "location" {
  description = "Google location where resources are to be created"
  type        = string
}

variable "project" {
  description = "Project id"
  type        = string
}

variable "vault_image" {
  description = "Vault docker image i.e. us.gcr.io/vault-226618/vault:latest"
  type        = string
}
