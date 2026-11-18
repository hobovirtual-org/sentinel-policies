variable "vault_namespace" {
  description = "Vault namespace to deploy into. Leave empty for root namespace."
  type        = string
  default     = ""
}

variable "vault_addr" {
  description = "Vault server address. Used for PKI issuing/CRL URLs. Defaults to VAULT_ADDR env var."
  type        = string
  default     = ""
}

variable "pki_mount" {
  description = "PKI secrets engine mount path."
  type        = string
  default     = "pki"
}

variable "pki_role" {
  description = "PKI role name."
  type        = string
  default     = "cmpv2-role"
}

variable "cert_auth_mount" {
  description = "Cert auth mount path dedicated to CMPv2."
  type        = string
  default     = "cert-cmpv2"
}

variable "egp_policy_name" {
  description = "Name of the Sentinel EGP policy."
  type        = string
  default     = "pki-cmpv2-sign-verbatim"
}

variable "acl_policy_name" {
  description = "Name of the Vault ACL policy."
  type        = string
  default     = "pki-cmpv2-sign-verbatim"
}
