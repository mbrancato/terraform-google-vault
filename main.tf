provider "random" {}

locals {
  vault_config = jsonencode(
    {
      "storage" : {
        "gcs" : {
          "bucket" : "${google_storage_bucket.vault.name}"
        }
      },
      "seal" : {
        "gcpckms" : {
          "project" : "${var.project}",
          "region" : "${var.location}",
          "key_ring" : "${google_kms_key_ring.vault.name}",
          "crypto_key" : "${google_kms_crypto_key.vault.name}"
        }
      },
      "default_lease_ttl" : "168h",
      "max_lease_ttl" : "720h",
      "disable_mlock" : "true",
      "listener" : {
        "tcp" : {
          "address" : "0.0.0.0:8080",
          "tls_disable" : "1"
        }
      }
    }
  )
}


resource "random_id" "vault" {
  byte_length = 2
}

resource "google_service_account" "vault" {
  account_id   = "vault-sa"
  display_name = "Vault Service Account for KMS auto-unseal"
}

resource "google_storage_bucket" "vault" {
  name = "${var.name}-${lower(random_id.vault.hex)}-bucket"
}

resource "google_storage_bucket_iam_member" "member" {
  bucket = google_storage_bucket.vault.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.vault.email}"
}

# Create a KMS key ring
resource "google_kms_key_ring" "vault" {
  name     = "${var.name}-${lower(random_id.vault.hex)}-kr"
  location = var.location
}

# Create a crypto key for the key ring, rotate daily
resource "google_kms_crypto_key" "vault" {
  name            = "${var.name}-key"
  key_ring        = google_kms_key_ring.vault.self_link
  rotation_period = "86400s"
}

# Add the service account to the Keyring
resource "google_kms_key_ring_iam_member" "vault" {
  key_ring_id = google_kms_key_ring.vault.id
  role        = "roles/owner"
  member      = "serviceAccount:${google_service_account.vault.email}"
}

resource "google_cloud_run_service" "default" {
  name     = var.name
  location = var.location

  metadata {
    namespace = var.project
  }

  template {
    spec {
      service_account_name  = google_service_account.vault.email
      container_concurrency = 1
      containers {
        # Specifying args seems to require the command / entrypoint
        image   = var.vault_image
        command = ["/usr/local/bin/docker-entrypoint.sh"]
        args    = ["server"]

        env {
          name  = "SKIP_SETCAP"
          value = "true"
        }

        env {
          name  = "VAULT_LOCAL_CONFIG"
          value = local.vault_config
        }

      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].spec[0].containers[0].resources,
    ]
  }
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "noauth" {
  location = google_cloud_run_service.default.location
  project  = google_cloud_run_service.default.project
  service  = google_cloud_run_service.default.name

  policy_data = data.google_iam_policy.noauth.policy_data
}

output "app_url" {
  value = google_cloud_run_service.default.status[0].url
}