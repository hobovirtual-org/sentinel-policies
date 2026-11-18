# sentinel-policies

**Sentinel policy sets for HCP Terraform that need the whole plan.** They cover rules that per-resource policies in [`tf-policies`](https://github.com/hobovirtual-org/tf-policies) (Terraform Policy) cannot express, such as limiting how many resources one run changes.

![Sentinel](https://img.shields.io/badge/Sentinel-0.41.0-7A3FF2)
![Status](https://img.shields.io/badge/Status-draft-57606a)

## At a Glance

| | |
| --- | --- |
| Scope | HCP Terraform policy sets, Sentinel framework |
| Layout | One folder per policy set under [`terraform/`](terraform), each with its own `sentinel.hcl` |
| Policy sets | [`terraform/change-guardrails`](terraform/change-guardrails) |
| Vault Enterprise policies | [`vault-sentinel-policies`](https://github.com/hobovirtual-org/vault-sentinel-policies) |
| CI | `make ci`: format check and tests for every set |

## Policy sets

| Set | Policies path | What it does | Enforcement |
| --- | --- | --- | --- |
| [`change-guardrails`](terraform/change-guardrails) | `terraform/change-guardrails` | Caps creates, deletes, replaces and total changes per run, by workspace `environment` tag | `advisory` |

## Layout

```
terraform/<set>/
├── sentinel.hcl            policy set config, read by HCP Terraform
├── <policy>.sentinel
└── test/<policy>/*.hcl     sentinel test cases and mocks
scripts/                    install-sentinel.sh, new-policy.sh, gen-test-data.py
```

HCP Terraform loads one policy set from one folder, the Policies path. Each folder under `terraform/` is a separate set with its own enforcement levels and workspace scope. The repository root is not a policy set.

## Quick Start

```bash
make tools   # install the pinned Sentinel CLI, checksum and GPG verified
make ci      # format check and tests for every policy set
```

## Prerequisites

- `make`, `python3`, `curl`, `gpg`, `unzip` (for `make tools`)
- A Sentinel CLI on `PATH`, or the one installed by `make tools`

## Make targets

| Target | Description |
| --- | --- |
| `make tools` | Install the pinned Sentinel CLI |
| `make fmt` | Check formatting of every `.sentinel` file in every set |
| `make test` | Run `sentinel test` in every set |
| `make gen` | Regenerate mocks and test cases from `scripts/gen-test-data.py` |
| `make ci` | `fmt` then `test`, as CI runs them |
| `make new-policy` | Scaffold a set: `make new-policy NAME=my-policy` |

## Add a policy set

```bash
make new-policy NAME=my-policy
make ci
```

This creates `terraform/my-policy/` with a placeholder rule and one passing test. Replace the rule, add failing cases, then attach the set in HCP Terraform with Policies path `terraform/my-policy`. Start at `advisory`.

> [!IMPORTANT]
> Every set needs its own policy set in HCP Terraform (Settings, Policy Sets) with the Policies path set to its folder. A set pointing at the repository root finds no `sentinel.hcl` and fails to load.

## Contributing & License

Open a PR. CI runs `make ci`. MPL-2.0.
