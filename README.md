# Vault Google Cloud Run Module

This is a Terraform module to deploy a [Vault](https://www.vaultproject.io/)
instance on Google's [Cloud Run](https://cloud.google.com/run/) service. Vault
is an open-source secrets management tool that generally is run in a
high-availability (HA) cluster. This implementation is a single instance
with auto-unseal and no HA support. Cloud Run is a way to easily run a
container on Google Cloud without an orchestrator. This module makes use of the
following Google Cloud resources:

* Google Cloud Run
* Google Cloud Storage
* Google Cloud Key Management Service

## Caveats

**PLEASE READ**

### Goole Cloud Container Registry

Cloud Run will only run containers hosted on `gcr.io` (GCR) and its subdomains.
This means that the Vault container will need to be pushed to GCR in the Google
Cloud Project. Terraform cannot currently create the container registry and it
is automatically created using `docker push`. Read the
[documentation](https://cloud.google.com/container-registry/docs/pushing-and-pulling)
for more details on pushing containers to GCR.

## Getting Started

To get started, a Google Cloud Project is needed. This should be created ahead
of time or using Terraform, but is outside the scope of this module. This
project ID is provided to the module invocation and a basic implementation
would look like the following:

```hcl
provider "google" {}

module "vault" {
  source   = "github.com/mbrancato/terraform-google-vault"
  name     = "vault"
  project  = "vault-543676"
  location = "us-central1"
}
```

After creating the resources, the Vault instance may be initialized.

Set the `VAULT_ADDR` environment variable. See [Vault URL](#vault-url).

```
$ export VAULT_ADDR=https://vault-jsn3uj5s1c-sg.a.run.app
```

Ensure the vault is operational (might take a minute or two), uninitialized and
sealed.

```
$ vault status
Key                      Value
---                      -----
Recovery Seal Type       gcpckms
Initialized              false
Sealed                   true
Total Recovery Shares    0
Threshold                0
Unseal Progress          0/0
Unseal Nonce             n/a
Version                  n/a
HA Enabled               false
```

Initialize the vault.

```
$ vault operator init
Recovery Key 1: ...
Recovery Key 2: ...
Recovery Key 3: ...
Recovery Key 4: ...
Recovery Key 5: ...

Initial Root Token: s....

Success! Vault is initialized

Recovery key initialized with 5 key shares and a key threshold of 3. Please
securely distribute the key shares printed above.
```

From here, Vault is operational. Configure the auth methods needed and other
settings. The Cloud Run Service may scale the container to zero, but the server
configuration and unseal keys are configured. When restarting, the Vault should
unseal itself automatically using the Google KMS. For more information on
deploying Vault, read
[Deploy Vault](https://learn.hashicorp.com/vault/getting-started/deploy).

## Security Concerns

The following things may be of concern from a security perspective:

* This is a publicly accessible Vault instance. Anyone with the DNS name can connect to it.
* By default, Vault is running on shared compute infrastructure.
