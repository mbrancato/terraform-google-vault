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

variable "vault_version" {
  description = "Vault version to run"
  type        = string
  default     = "1.2.0"
}
