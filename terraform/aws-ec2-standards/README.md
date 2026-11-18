# terraform/aws-ec2-standards

**HCP Terraform Sentinel policy set that requires tags and an approved instance type on every `aws_instance` a run creates or updates, with both lists chosen by the workspace `environment` tag.** It fails closed and reports every violation.

![Sentinel](https://img.shields.io/badge/Sentinel-0.41.0-7A3FF2)
![Enforcement](https://img.shields.io/badge/Enforcement-advisory-57606a)

## At a Glance

| | |
| --- | --- |
| Policies path | `terraform/aws-ec2-standards` |
| Config | [`sentinel.hcl`](sentinel.hcl) |
| Policy | [`aws-ec2-standards.sentinel`](aws-ec2-standards.sentinel) |
| Enforcement level | `advisory` until the results match real plans |
| Imports | `tfplan/v2`, `tfrun`, `types` |
| Tests | 36 scenarios in [`test/aws-ec2-standards/`](test/aws-ec2-standards) |

## Quick Start

From the repository root:

```bash
make tools   # install the pinned Sentinel CLI
make ci      # format check and tests for every policy set
```

## Rules

| Rule | Passes when |
| --- | --- |
| `mandatory_instance_tags` | Every in-scope instance has every tag required for its environment, with a non-empty value |
| `instance_type_allowed` | Every in-scope instance has an `instance_type` allowed for its environment |
| `main` | Both rules pass |

## Environments

The environment comes from the workspace tag `environment`, read from `tfrun.workspace.tag_bindings`.

| Tier | Tag value | Required tags | Allowed instance types |
| --- | --- | --- | --- |
| `dev` | `dev` | `Name` | `t2.micro`, `t2.small`, `t2.medium`, `t3.micro`, `t3.small`, `t3.medium` |
| `test` | `uat`, `staging`, `qa` | `Name` | The same six types |
| `prod` | `prod` | `Name`, `Owner`, `CostCenter` | The six types, plus `m5.large`, `m5.xlarge`, `m5.2xlarge`, `m6i.large`, `m6i.xlarge`, `m6i.2xlarge` |
| Unknown | No tag, or any other value | The `prod` tags | The `dev` types |

- An untagged workspace or an unknown value takes the strictest of each list. Tags and types are resolved separately, because the strictest tags are `prod`'s and the strictest types are `dev`'s. A missing or mistyped tag never loosens either list.
- This differs from `change-guardrails`, where an unknown value gets the `prod` tier. Here `prod` is the loosest tier for instance types, so it cannot be the fallback.
- The lists are in `standards` at the top of the policy file. They apply to the whole policy set, not per workspace.

### Scope

- Only `managed` resources of type `aws_instance` are checked.
- An instance is in scope when its actions include `create` or `update`. A replacement (`["delete", "create"]`) is in scope.
- Deletes, `no-op` changes and data sources are ignored.
- Tags are read from both `tags_all`, which includes provider `default_tags`, and `tags`. A tag set in either counts.

### Fails closed

- A null or missing tag map is a violation.
- An empty tag value is a violation.
- An `instance_type` unknown at plan time is a violation, because it cannot be checked against the allowlist.
- A tag, or the whole tag map, that is known only after apply counts as set. Nothing more can be checked at plan time.

> [!NOTE]
> The policy lists every violating instance in the run log, not only the first.

## Changes from the original policy

I ran the original rules against this set's scenarios and recorded what happened. `else true` on `main` only applies to an undefined result. It did not turn a false or an error into a pass, so it added nothing and is removed.

| Original behavior | Now | Scenario |
| --- | --- | --- |
| Errored when `tags` was null: `left operand for contains must be list, map, or string got null` | A null or missing tag map is a violation | `null-tags-fails`, `noncompliant-replace-fails` |
| Errored when the tag came from provider `default_tags` (`tags_all`) and `tags` was null | Reads `tags_all` and `tags` | `name-tag-only-in-tags-all` |
| Errored when the whole tag map was known only after apply | Counts as set, since nothing more can be checked at plan time | `tag-map-known-after-apply` |
| Rejected a plan whose `Name` tag was known only after apply | Counts as set | `name-tag-known-after-apply` |
| Passed an empty `Name` tag | An empty value is a violation | `empty-name-tag-fails` |
| Passed an `instance_type` unknown at plan time | A violation, because it cannot be checked | `unknown-instance-type-fails` |
| Passed an instance with no `tags` attribute | A violation | `missing-tag-attributes-fails` |
| No `mode` filter | `mode is "managed"`, so data sources are ignored | `data-source-is-ignored` |
| Scope was `create` or exactly `["update"]` | `create` or `update` in the actions. Same result for real plans, simpler to read | |
| Reported nothing about which instance failed | Logs every violating instance | `one-bad-among-good-fails` |

Unchanged: a missing `Name` tag, a disallowed type and a non-compliant update were already rejected.

## Attaching to workspaces

Create the policy set in HCP Terraform (Settings, Policy Sets) with:

| Setting | Value |
| --- | --- |
| Policy framework | Sentinel |
| Source | This repository, VCS |
| Policies path | `terraform/aws-ec2-standards` |
| Scope | A workspace tag, a project, or named workspaces. Every workspace needs the `environment` tag to get its own tier |

Tag scoping and explicit workspace attachment are mutually exclusive on one policy set.

> [!IMPORTANT]
> Raise `enforcement_level` in `sentinel.hcl` to `soft-mandatory`, then `hard-mandatory`, only after the advisory results have matched real plans on a pilot workspace.

## Testing

Tests use hand-written mocks of `tfplan/v2` and `tfrun` in [`test/aws-ec2-standards/testdata/`](test/aws-ec2-standards/testdata), one plan per scenario and one `tfrun` per environment.

> [!WARNING]
> The mocks follow the documented import shape, not a real exported plan. Compare the first advisory result on a pilot workspace with the real plan before relying on it, especially for `tags_all` and `after_unknown`.

## Contributing & License

Open a PR. CI runs `make ci`.
