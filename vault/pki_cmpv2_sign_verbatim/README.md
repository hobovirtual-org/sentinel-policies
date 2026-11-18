# pki_cmpv2_sign_verbatim

**Sentinel EGP guardrail for Vault PKI CMPv2 certificate lifecycle management.** Reduces blast radius of `sign-verbatim` usage by enforcing subject DN allowlists, CN pattern, UID format, extended key usage, and SAN constraints on every `pki/cmp` request before Vault issues a certificate.

![Vault](https://img.shields.io/badge/Vault-Enterprise%20%3E%3D%201.18-1F6FEB) ![Sentinel](https://img.shields.io/badge/Sentinel-EGP%20hard--mandatory-2EA043) ![Terraform](https://img.shields.io/badge/Provider-hashicorp%2Fvault%20~%3E%205.10.1-7A3FF2)

## At a Glance

| Item | Value |
|---|---|
| Enforcement level | `hard-mandatory` |
| Bound path | `pki/cmp` (configurable via `pki_mount`) |
| Vault provider | `hashicorp/vault ~> 5.10.1` |
| Terraform | >= 1.14.0 |
| Sentinel CLI | >= 0.41.0 |
| Test scenarios | 12 (2 pass, 10 fail) |

## Quick Start

### Run Tests — no Vault needed

```bash
cd vault/pki_cmpv2_sign_verbatim
sentinel test
```

Expected output:

```
PASS - policy.sentinel
  PASS - test/policy/fail_bad_cn.hcl
  PASS - test/policy/fail_bad_country.hcl
  PASS - test/policy/fail_bad_org.hcl
  PASS - test/policy/fail_bad_ou.hcl
  PASS - test/policy/fail_bad_uri_san.hcl
  PASS - test/policy/fail_li_missing_uid.hcl
  PASS - test/policy/fail_missing_eku.hcl
  PASS - test/policy/fail_san_dns_mismatch.hcl
  PASS - test/policy/fail_san_dns_missing.hcl
  PASS - test/policy/fail_san_dns_regex.hcl
  PASS - test/policy/pass_li_with_uid.hcl
  PASS - test/policy/pass_oam_valid.hcl
1 tests completed in ...
```

### Deploy with Terraform

**macOS / Linux**

```bash
cd vault/pki_cmpv2_sign_verbatim/terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set vault_addr and vault_namespace
export VAULT_TOKEN="<your-vault-token>"
terraform init && terraform apply
```

**Windows (PowerShell)**

```powershell
cd policies\pki_cmpv2_sign_verbatim\terraform
Copy-Item terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars — set vault_addr and vault_namespace
$env:VAULT_TOKEN = "<your-vault-token>"
terraform init; terraform apply
```

> [!IMPORTANT]
> The token must have `sys/auth/*`, `sys/mounts/*`, `sys/policies/*`, and `sys/policies/egp/*` write capabilities in the target namespace. Create the token inside the target namespace — a parent-namespace root token does not automatically carry these permissions into child namespaces.

> [!IMPORTANT]
> `terraform.tfvars` is gitignored — never commit it. Use `terraform.tfvars.example` as the committed reference template.

> [!NOTE]
> Vault Enterprise `sys/policies/egp` does not support runtime parameter injection. All policy parameter values are set as `param ... default ...` in `policy.sentinel` directly.

### Tear Down

```bash
cd vault/pki_cmpv2_sign_verbatim/terraform
terraform destroy
```

## Prerequisites

| Tool | Minimum version | Purpose | Download |
|---|---|---|---|
| [Sentinel CLI](https://developer.hashicorp.com/sentinel/downloads) | 0.41.0 | Unit tests — no Vault needed | All platforms |
| [Terraform](https://developer.hashicorp.com/terraform/downloads) | 1.14.0 | Vault resource provisioning | All platforms |
| [Vault CLI](https://developer.hashicorp.com/vault/downloads) | 1.18 Enterprise | Manual operations | All platforms |

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `vault_addr` | Vault server address. Used for PKI issuing/CRL URLs. Falls back to `VAULT_ADDR` env var when empty. | `string` | `""` | yes |
| `vault_namespace` | Vault namespace to deploy into. Leave empty for root namespace. | `string` | `""` | no |
| `pki_mount` | PKI secrets engine mount path. | `string` | `"pki"` | no |
| `pki_role` | PKI role name. | `string` | `"cmpv2-role"` | no |
| `cert_auth_mount` | Cert auth mount path dedicated to CMPv2. | `string` | `"cert-cmpv2"` | no |
| `egp_policy_name` | Name of the Sentinel EGP policy in Vault. | `string` | `"pki-cmpv2-sign-verbatim"` | no |
| `acl_policy_name` | Name of the Vault ACL policy. | `string` | `"pki-cmpv2-sign-verbatim"` | no |

## Outputs

| Name | Description |
|---|---|
| `pki_mount` | PKI secrets engine mount path. |
| `cert_auth_accessor` | Cert auth mount accessor (used by CMPv2 authenticator). |
| `egp_policy_name` | Name of the deployed Sentinel EGP policy. |

## Import

If Vault resources were created outside Terraform, import them into state.

> [!IMPORTANT]
> Import requires a token with `sudo` on `sys/*` and `auth/*`. A root token inside a child namespace cannot be created directly — Vault blocks it. Create a scoped admin token first, then delete it when done:
>
> ```bash
> vault policy write tf-import - <<'EOF'
> path "sys/*"  { capabilities = ["create", "read", "update", "delete", "list", "sudo"] }
> path "auth/*" { capabilities = ["create", "read", "update", "delete", "list", "sudo"] }
> path "pki/*"  { capabilities = ["create", "read", "update", "delete", "list"] }
> EOF
>
> export VAULT_TOKEN=$(vault token create -policy=tf-import -ttl=1h -field=token)
> ```

```bash
cd vault/pki_cmpv2_sign_verbatim/terraform
terraform import vault_mount.pki                               pki
terraform import vault_auth_backend.cert_cmpv2                 cert-cmpv2
terraform import vault_pki_secret_backend_config_cmpv2.cmpv2   pki/config/cmpv2
terraform import vault_policy.acl                              pki-cmpv2-sign-verbatim
terraform import vault_generic_endpoint.pki_cmpv2_sign_verbatim sys/policies/egp/pki-cmpv2-sign-verbatim
```

Clean up the temporary policy after import:

```bash
vault policy delete tf-import
```

## Policy Controls

All controls are driven by `param ... default ...` values in [`policy.sentinel`](policy.sentinel). Edit the defaults there to change enforcement behaviour — no Terraform changes are needed for parameter adjustments.

> [!NOTE]
> Vault Enterprise `sys/policies/egp` does not support runtime parameter injection via the API. Parameter values are baked into the policy source as defaults.

| Control | Parameter | Default | Behaviour |
|---|---|---|---|
| Subject country | `allowed_countries` | `[]` — denies all | Request C must be in list |
| Subject org | `allowed_organizations` | `[]` — denies all | Request O must be in list |
| Subject OU | `allowed_org_units` | `[]` — denies all | Request OU must be in list |
| Subject state | `allowed_states` | `[]` — denies all | Request ST must be in list |
| Subject locality | `allowed_localities` | `[]` — denies all | Request L must be in list |
| Subject email | `allowed_email` | `""` — skipped | Must equal value when set |
| CN pattern | `cn_regex` | `""` — skipped | CN must fully match regex (anchored) |
| SAN DNS.1 = CN | `require_dns_san_match` | `true` | First DNS SAN must equal CN |
| SAN DNS regex | `dns_san_regexes` | `[]` — skipped | Per-index regex validation |
| EKU | `required_eku` | `["serverAuth","clientAuth"]` | All listed values must be present |
| URI SAN prefix | `san_uri_prefix` | `""` — skipped | Every URI SAN must start with prefix |
| URI SAN regex | `uri_san_regex` | `""` — skipped | Every URI SAN must match regex |
| URI SAN required | `require_uri_sans` | `false` | At least one URI SAN when `true` |
| SAN count | `max_san_entries` | `20` | Total SANs must not exceed value |
| LI cert UID | `uid_regex` + `li_cn_prefix` | `""` — UID check skipped | UID required and validated when CN starts with prefix |

## Files

```text
pki_cmpv2_sign_verbatim/
├── README.md                    # this file
├── policy.sentinel              # EGP source — param defaults define enforcement values
├── acl.hcl                      # Vault ACL policy for CMPv2 clients
├── sentinel.hcl                 # Sentinel CLI test configuration
├── test/
│   └── policy/                  # must match source filename (policy.sentinel)
│       ├── pass_oam_valid.hcl   # valid OAM certificate
│       ├── pass_li_with_uid.hcl # valid LI certificate with UID
│       ├── fail_bad_country.hcl
│       ├── fail_bad_org.hcl
│       ├── fail_bad_ou.hcl
│       ├── fail_bad_cn.hcl
│       ├── fail_san_dns_missing.hcl
│       ├── fail_san_dns_mismatch.hcl
│       ├── fail_san_dns_regex.hcl
│       ├── fail_missing_eku.hcl
│       ├── fail_li_missing_uid.hcl
│       └── fail_bad_uri_san.hcl
└── terraform/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    └── terraform.tfvars.example
```

## Contributing

See [Vault policies](../../README.md#vault-policies) in the root README.

> [!NOTE]
> Vault EGP Sentinel policies use a restricted dialect — only `func` definitions and `main = rule { ... }` are valid. Named `rule` blocks and module-scope calls to `request` are not supported. See [Vault EGP Sentinel dialect](../../README.md#vault-egp-sentinel-dialect) for details.
