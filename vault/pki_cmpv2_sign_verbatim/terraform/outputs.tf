output "pki_mount" {
  description = "PKI secrets engine mount path."
  value       = vault_mount.pki.path
}

output "cert_auth_accessor" {
  description = "Cert auth mount accessor (used by CMPv2 authenticator)."
  value       = vault_auth_backend.cert_cmpv2.accessor
}

output "egp_policy_name" {
  description = "Name of the deployed Sentinel EGP policy."
  value       = var.egp_policy_name
}
