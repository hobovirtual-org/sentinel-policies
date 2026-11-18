# sentinel-policies

**Central repository for Sentinel policies: HCP Terraform policy sets and Vault Enterprise EGP policies.** HCP Terraform policy sets cover rules that per-resource policies in [`tf-policies`](https://github.com/hobovirtual-org/tf-policies) (Terraform Policy) cannot express. The Vault policies guard requests inside Vault.

![Sentinel](https://img.shields.io/badge/Sentinel-0.41.0-7A3FF2)
![Status](https://img.shields.io/badge/Status-draft-57606a)

## At a Glance

| | |
| --- | --- |
| Layout | One folder per policy set, under [`terraform/`](terraform) or [`vault/`](vault) |
| HCP Terraform sets | [`terraform/change-guardrails`](terraform/change-guardrails) |
| Vault Enterprise policies | [`vault/pki_cmpv2_sign_verbatim`](vault/pki_cmpv2_sign_verbatim) |
| CI | `make ci` for every set, plus `terraform validate` for the Vault deployment modules |

## Policy sets

### HCP Terraform

| Set | Policies path | What it does | Enforcement |
| --- | --- | --- | --- |
| [`change-guardrails`](terraform/change-guardrails) | `terraform/change-guardrails` | Caps creates, deletes, replaces and total changes per run, by workspace `environment` tag | `advisory` |

### Vault Enterprise

| Policy | What it does | Enforcement |
| --- | --- | --- |
| [`pki_cmpv2_sign_verbatim`](vault/pki_cmpv2_sign_verbatim) | EGP guardrail for Vault PKI CMPv2: subject DN, CN regex, EKU and SAN constraints | `hard-mandatory` |

## Layout

```text
terraform/<set>/
├── sentinel.hcl            policy set config, read by HCP Terraform
├── <policy>.sentinel
└── test/<policy>/*.hcl     sentinel test cases and mocks
vault/<policy>/
├── sentinel.hcl            test configuration for sentinel test
├── <policy>.sentinel       EGP source
├── acl.hcl                 Vault ACL policy for the clients
├── test/<policy>/*.hcl
└── terraform/              deploys the EGP to Vault
scripts/                    install-sentinel.sh, new-policy.sh, gen-test-data.py
```

`make test` runs `sentinel test` in every folder that has a `sentinel.hcl`, so both kinds of set are tested the same way.

## Quick Start

```bash
make tools   # install the pinned Sentinel CLI, checksum and GPG verified
make ci      # format check and tests for every policy set
```

## Prerequisites

- `make`, `python3`, `curl`, `gpg`, `unzip` (for `make tools`)
- A Sentinel CLI on `PATH`, or the one installed by `make tools`
- Terraform >= 1.14.0 and Vault Enterprise >= 1.18, only to deploy a Vault policy

## Make targets

| Target | Description |
| --- | --- |
| `make tools` | Install the pinned Sentinel CLI |
| `make fmt` | Check formatting of every `.sentinel` file in every set |
| `make test` | Run `sentinel test` in every set |
| `make gen` | Regenerate the `terraform/change-guardrails` mocks from `scripts/gen-test-data.py` |
| `make ci` | `fmt` then `test`, as CI runs them |
| `make new-policy` | Scaffold a set: `make new-policy TARGET=terraform NAME=my-policy` |

## HCP Terraform policy sets

HCP Terraform loads one policy set from one folder, the Policies path. Each folder under `terraform/` is a separate set with its own enforcement levels and workspace scope. The repository root is not a policy set.

```bash
make new-policy TARGET=terraform NAME=my-policy
make ci
```

This creates `terraform/my-policy/` with a placeholder rule and one passing test. Replace the rule, add failing cases, then attach the set in HCP Terraform with Policies path `terraform/my-policy`. Start at `advisory`.

> [!IMPORTANT]
> Every set needs its own policy set in HCP Terraform (Settings, Policy Sets) with the Policies path set to its folder. A set pointing at the repository root finds no `sentinel.hcl` and fails to load.

## Vault policies

HCP Terraform does not serve these. Vault evaluates Sentinel itself, with the policy bound to request paths (EGP) or identities (RGP) through Vault's own API. The deployment module in each `vault/<policy>/terraform/` does that for its policy. Each policy folder has a README with its deploy steps.

```bash
make new-policy TARGET=vault NAME=my-policy
make ci
```

This creates `vault/my-policy/` with a placeholder rule and one passing test. It does not create `acl.hcl` or a `terraform/` module. Copy those from [`vault/pki_cmpv2_sign_verbatim`](vault/pki_cmpv2_sign_verbatim) when the policy needs them.

> [!IMPORTANT]
> `terraform.tfvars` and Terraform state are gitignored. Never commit them. Commit `terraform.tfvars.example` only.

### Vault EGP Sentinel dialect

Vault's EGP runtime enforces a restricted subset of Sentinel. `sentinel test` accepts more than Vault does, so a passing test does not prove the policy loads.

- Only `func` definitions and `main = rule { ... }` are allowed. No named `rule` blocks.
- No variable assignments inside `main = rule { ... }`. Pass `request.data` directly to functions.
- No module-scope assignments that call functions accessing `request`. `request` is only valid inside function bodies at runtime.
- `for ... as`, `if/return` and multi-line arithmetic inside `func` bodies are supported.
- Vault Enterprise `sys/policies/egp` does not inject parameters at runtime. Set values as `param ... default ...` in the policy source.

To check that a policy compiles against Vault before applying it:

```bash
VAULT_ADDR="..." VAULT_NAMESPACE="..." VAULT_TOKEN="..." \
  vault write sys/policies/egp/test-parse \
    policy="$(base64 < vault/<policy>/<policy>.sentinel | tr -d '\n')" \
    paths="pki/cmp" enforcement_level="advisory"
vault delete sys/policies/egp/test-parse
```

## Security

- Do not commit secrets, Vault tokens, licenses, private keys or environment files.
- Use scoped credentials and environment variables for local work and automation.
- Do not report vulnerabilities in public issues. Report them privately to the maintainers through your organization's approved security reporting channel.

## Contributing & License

Open a PR. CI runs `make ci`.
