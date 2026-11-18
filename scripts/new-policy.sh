#!/usr/bin/env bash
# Scaffold a new HCP Terraform policy set with one policy and one passing test.
#
# Usage: scripts/new-policy.sh <name>
# Creates terraform/<name>; the HCP Terraform policies path is terraform/<name>.
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <name>" >&2
  exit 2
fi

name="$1"

if [[ ! "${name}" =~ ^[a-z][a-z0-9-]{0,62}$ ]]; then
  echo "error: name must be lowercase letters, digits and hyphens, starting with a letter" >&2
  exit 2
fi

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dir="${root}/terraform/${name}"

if [[ -e "${dir}" ]]; then
  echo "error: terraform/${name} already exists" >&2
  exit 1
fi

mkdir -p "${dir}/test/${name}"

cat >"${dir}/sentinel.hcl" <<EOF
# Start at advisory and raise the level only after the results match real runs.
policy "${name}" {
  source            = "./${name}.sentinel"
  enforcement_level = "advisory"
}
EOF

cat >"${dir}/${name}.sentinel" <<EOF
# ${name}
#
# TODO: describe what this policy enforces and which imports it uses.

main = rule {
	true
}
EOF

cat >"${dir}/test/${name}/pass.hcl" <<EOF
test {
  rules = {
    main = true
  }
}
EOF

echo "created terraform/${name}"
echo "next: replace the placeholder rule, add failing test cases, then run 'make ci'"
