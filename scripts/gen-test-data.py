#!/usr/bin/env python3
"""Generate Sentinel mocks and test cases for environment-change-guardrails.

Mocks follow the documented tfplan/v2 (resource_changes) and tfrun (workspace.tag_bindings)
imports. Each scenario is (name, environment tag or None, action counts, expected main).
Run from the repository root: python3 scripts/gen-test-data.py
"""
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
POLICY = "environment-change-guardrails"
POLICY_SET = ROOT / "terraform" / "change-guardrails"
CASES = POLICY_SET / "test" / POLICY
DATA = CASES / "testdata"

ACTIONS = {
    "create": ["create"],
    "delete": ["delete"],
    "replace": ["delete", "create"],
    "update": ["update"],
    "noop": ["no-op"],
}

# name, environment tag (None = no tag), {action: count}, expected result of rule main
SCENARIOS = [
    ("dev-within-limits", "dev", {"create": 5}, True),
    ("dev-at-creates-limit", "dev", {"create": 100}, True),
    ("dev-creates-over-limit", "dev", {"create": 101}, False),
    ("prod-at-creates-limit", "prod", {"create": 25}, True),
    ("prod-creates-over-limit", "prod", {"create": 26}, False),
    ("prod-deletes-over-limit", "prod", {"delete": 11}, False),
    ("prod-replaces-over-limit", "prod", {"replace": 6}, False),
    ("prod-replace-not-double-counted", "prod", {"create": 25, "replace": 5}, True),
    ("prod-total-over-limit", "prod", {"create": 25, "delete": 10, "replace": 5, "update": 11}, False),
    ("prod-noops-and-reads-not-counted", "prod", {"create": 3, "noop": 100, "read": 100}, True),
    ("staging-gets-test-limits", "staging", {"create": 26}, True),
    ("uat-creates-over-test-limit", "uat", {"create": 51}, False),
    ("untagged-gets-prod-limits", None, {"create": 26}, False),
    ("unknown-environment-gets-prod-limits", "sandbox", {"create": 26}, False),
]


def changes(counts):
    out = []
    for action, n in counts.items():
        for i in range(n):
            if action == "read":
                out.append((f"data.aws_ami.{action}_{i}", "data", ["read"]))
            else:
                out.append((f"aws_instance.{action}_{i}", "managed", ACTIONS[action]))
    return out


def hcl_list(items):
    return "[" + ", ".join(f'"{a}"' for a in items) + "]"


def write_tfplan(name, counts):
    lines = ['terraform_version = "1.17.2"', "", "resource_changes = {"]
    for address, mode, actions in changes(counts):
        rtype = address.split(".")[-2] if mode == "data" else address.split(".")[0]
        lines += [
            f'\t"{address}": {{',
            f'\t\t"address": "{address}",',
            f'\t\t"mode":    "{mode}",',
            f'\t\t"type":    "{rtype}",',
            '\t\t"change": {',
            f'\t\t\t"actions": {hcl_list(actions)},',
            "\t\t},",
            "\t},",
        ]
    lines.append("}")
    (DATA / f"mock-tfplan-{name}.sentinel").write_text("\n".join(lines) + "\n")


def write_tfrun(name, env):
    bindings = [
        '\t\t{"key": "app", "value": "guardrails-test", "inherited": false},',
        '\t\t{"key": "cloud_provider", "value": "aws", "inherited": false},',
    ]
    if env is not None:
        bindings.append(f'\t\t{{"key": "environment", "value": "{env}", "inherited": false}},')
    lines = [
        "workspace = {",
        '\t"name": "guardrails-test",',
        '\t"tag_bindings": [',
        *bindings,
        "\t],",
        "}",
    ]
    (DATA / f"mock-tfrun-{name}.sentinel").write_text("\n".join(lines) + "\n")


def write_case(name, expected):
    body = f'''mock "tfplan/v2" {{
  module {{
    source = "testdata/mock-tfplan-{name}.sentinel"
  }}
}}

mock "tfrun" {{
  module {{
    source = "testdata/mock-tfrun-{name}.sentinel"
  }}
}}

test {{
  rules = {{
    main = {str(expected).lower()}
  }}
}}
'''
    (CASES / f"{name}.hcl").write_text(body)


def main():
    DATA.mkdir(parents=True, exist_ok=True)
    for name, env, counts, expected in SCENARIOS:
        write_tfplan(name, counts)
        write_tfrun(name, env)
        write_case(name, expected)
    print(f"generated {len(SCENARIOS)} scenarios")


if __name__ == "__main__":
    main()
