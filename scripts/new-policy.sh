#!/usr/bin/env bash
# Scaffold a new policy set with one policy and one passing test.
#
# Usage: scripts/new-policy.sh <terraform|vault> <name>
#   terraform: policy set delivered by HCP Terraform (policies path terraform/<name>)
#   vault:     policy set delivered to Vault Enterprise as EGP/RGP policies
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "usage: $0 <terraform|vault> <name>" >&2
  exit 2
fi

target="$1"
name="$2"

case "${target}" in
  terraform | vault) ;;
  *)
    echo "error: target must be 'terraform' or 'vault'" >&2
    exit 2
    ;;
esac

if [[ ! "${name}" =~ ^[a-z][a-z0-9-]{0,62}$ ]]; then
  echo "error: name must be lowercase letters, digits and hyphens, starting with a letter" >&2
  exit 2
fi

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
dir="${root}/${target}/${name}"

if [[ -e "${dir}" ]]; then
  echo "error: ${target}/${name} already exists" >&2
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

echo "created ${target}/${name}"
echo "next: replace the placeholder rule, add failing test cases, then run 'make ci'"
