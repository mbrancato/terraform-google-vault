data "google_project" "project" {
  project_id = var.project
}

resource "google_project_service" "cloudresourcemanager" {
  project = data.google_project.project.number
  service = "cloudresourcemanager.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "containerregistry" {
  project = data.google_project.project.number
  service = "containerregistry.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "iam" {
  project = data.google_project.project.number
  service = "iam.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "cloudkms" {
  project = data.google_project.project.number
  service = "cloudkms.googleapis.com"

  disable_dependent_services = true
}

resource "google_project_service" "run" {
  project = data.google_project.project.number
  service = "run.googleapis.com"

  disable_dependent_services = true
}