# =============================================================================
# main.tf — PKI CMPv2 sign-verbatim Sentinel EGP policy
#
# Resources managed:
#   - PKI secrets engine mount (with required CMPv2 response headers)
#   - PKI root CA (dev/iteration only — replace with proper issuer in prod)
#   - PKI role
#   - Cert auth mount (batch tokens, required by CMPv2 authentication)
#   - pki/config/cmp with enable_sentinel_parsing=true
#   - Vault ACL policy
#   - Sentinel EGP policy bound to pki/cmp
#
# Usage:
#   cp terraform.tfvars.example terraform.tfvars   # fill in your values
#   export VAULT_TOKEN="your-token"
#   terraform init && terraform apply
# =============================================================================

terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.10.1"
    }
  }
  required_version = ">= 1.14.0"
}

provider "vault" {
  # VAULT_ADDR and VAULT_TOKEN are read from environment variables.
  # address falls back to VAULT_ADDR env var when var.vault_addr is empty.
  address   = var.vault_addr != "" ? var.vault_addr : null
  namespace = var.vault_namespace != "" ? var.vault_namespace : null
}

# -----------------------------------------------------------------------------
# Cert auth mount — created first so its accessor is available for PKI tuning.
# CMPv2 authenticates each request via cert auth; batch tokens avoid excessive
# lease generation.
# -----------------------------------------------------------------------------

resource "vault_auth_backend" "cert_cmpv2" {
  type = "cert"
  path = var.cert_auth_mount

  tune {
    default_lease_ttl = "1h"
    token_type        = "batch"
  }
}

# -----------------------------------------------------------------------------
# PKI secrets engine.
# allowed_response_headers and delegated_auth_accessors are required for CMPv2.
# -----------------------------------------------------------------------------

resource "vault_mount" "pki" {
  path                      = var.pki_mount
  type                      = "pki"
  default_lease_ttl_seconds = 86400
  max_lease_ttl_seconds     = 315360000 # 10 years

  allowed_response_headers = [
    "Content-Transfer-Encoding",
    "Content-Length",
    "WWW-Authenticate",
  ]

  delegated_auth_accessors = [vault_auth_backend.cert_cmpv2.accessor]

  depends_on = [vault_auth_backend.cert_cmpv2]
}

# Root CA — DigitalSignature key usage is required because CMPv2 uses the
# issuer CA certificate to sign CMP protocol messages.
resource "vault_pki_secret_backend_root_cert" "root" {
  backend     = vault_mount.pki.path
  type        = "internal"
  common_name = "Dev Root CA"
  ttl         = "87600h"
  key_type    = "ec"
  key_bits    = 256
  key_usage   = ["CertSign", "CRLSign", "DigitalSignature"]
}

resource "vault_pki_secret_backend_config_urls" "urls" {
  backend                 = vault_mount.pki.path
  issuing_certificates    = ["${var.vault_addr}/v1/${var.pki_mount}/ca"]
  crl_distribution_points = ["${var.vault_addr}/v1/${var.pki_mount}/crl"]
}

resource "vault_pki_secret_backend_role" "role" {
  backend           = vault_mount.pki.path
  name              = var.pki_role
  allow_any_name    = true
  enforce_hostnames = false
  key_type          = "ec"
  key_bits          = 256
  ttl               = "8760h"
  max_ttl           = "8760h"
  no_store          = false
}

# -----------------------------------------------------------------------------
# pki/config/cmpv2 — enable CMPv2 with Sentinel parsing.
# Uses the dedicated vault_pki_secret_backend_config_cmpv2 resource
# introduced in hashicorp/vault provider 5.x.
# -----------------------------------------------------------------------------

resource "vault_pki_secret_backend_config_cmpv2" "cmpv2" {
  backend             = vault_mount.pki.path
  enabled             = true
  default_path_policy = "sign-verbatim"

  authenticators {
    cert = {
      accessor = vault_auth_backend.cert_cmpv2.accessor
    }
  }

  enable_sentinel_parsing = true

  audit_fields = [
    "csr", "common_name", "alt_names", "ip_sans", "uri_sans", "other_sans",
    "signature_bits", "exclude_cn_from_sans", "ou", "organization", "country",
    "locality", "province", "street_address", "postal_code", "serial_number",
    "use_pss", "key_type", "key_bits", "add_basic_constraints",
  ]
}

# -----------------------------------------------------------------------------
# ACL policy — grants CMPv2 clients access to the CMP endpoint.
# -----------------------------------------------------------------------------

resource "vault_policy" "acl" {
  name = var.acl_policy_name

  policy = <<-EOT
    path "${var.pki_mount}/cmp" {
      capabilities = ["create", "update"]
    }
    path "${var.pki_mount}/roles/+/cmp" {
      capabilities = ["create", "update"]
    }
    path "${var.pki_mount}/+/cert/ca_chain" {
      capabilities = ["read"]
    }
    path "${var.pki_mount}/*" {
      capabilities = ["deny"]
    }
  EOT
}

# -----------------------------------------------------------------------------
# Sentinel EGP policy — deployed via vault_generic_endpoint so that both the
# policy source and the bind-time parameters are written in a single API call.
# vault_egp_policy (the dedicated resource) has no parameters argument.
# -----------------------------------------------------------------------------

resource "vault_generic_endpoint" "pki_cmpv2_sign_verbatim" {
  path                 = "sys/policies/egp/${var.egp_policy_name}"
  ignore_absent_fields = true
  disable_read         = false

  # Vault Enterprise v2.x sys/policies/egp does not support runtime parameter
  # injection via the API — param default values in policy.sentinel are used.
  data_json = jsonencode({
    policy            = base64encode(file("${path.module}/../policy.sentinel"))
    paths             = ["${var.pki_mount}/cmp"]
    enforcement_level = "hard-mandatory"
  })

  depends_on = [vault_pki_secret_backend_config_cmpv2.cmpv2]
}
