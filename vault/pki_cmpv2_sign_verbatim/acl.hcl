# ============================================================================
# acl.hcl
#
# Vault ACL policy — grants the minimum capabilities needed for a CMPv2
# client to authenticate and issue certificates via the CMP endpoint.
#
# Assign this policy to the token / AppRole / identity entity used by the
# CMPv2 client. Combine with the EGP Sentinel policy to enforce subject
# field constraints on every request.
#
# Usage:
#   vault policy write pki-cmpv2-sign-verbatim \
#     vault/pki_cmpv2_sign_verbatim/acl.hcl
# ============================================================================

# Allow CMPv2 client requests on the default CMP path.
# Tighten to a specific mount (e.g. "pki/cmp") once you know the exact
# mount path used in your environment.
path "pki/cmp" {
  capabilities = ["create", "update"]
}

# Role-based CMP path (alternative to default path policy).
path "pki/roles/+/cmp" {
  capabilities = ["create", "update"]
}

# Read-only access to the PKI CA chain (needed by CMPv2 clients to
# build the certificate response).
path "pki/+/cert/ca_chain" {
  capabilities = ["read"]
}

# Deny everything else on the PKI mount by default (belt-and-suspenders).
path "pki/*" {
  capabilities = ["deny"]
}
