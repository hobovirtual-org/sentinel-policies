#!/usr/bin/env bash
# Install the Sentinel CLI pinned in .sentinel-version into .tools/bin/.
#
# Verifies the SHA256 checksum and the GPG signature of the release against
# HashiCorp's published signing key (fingerprint pinned below). gpg is required.
#
# Environment:
#   SENTINEL_VERSION  Override the version in .sentinel-version.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

die() {
  echo "error: $*" >&2
  exit 1
}

# HashiCorp Security primary key. https://www.hashicorp.com/trust/security
HASHICORP_FPR="C874011F0AB405110D02105534365D9472D7468F"
HASHICORP_KEY_URL="https://www.hashicorp.com/.well-known/pgp-key.txt"
RELEASES_URL="https://releases.hashicorp.com/sentinel"

version="${SENTINEL_VERSION:-$(tr -d '[:space:]' <"${ROOT}/.sentinel-version")}"
[[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "invalid version '${version}'"

bin_dir="${ROOT}/.tools/bin"
target="${bin_dir}/sentinel"

if [[ -x "${target}" ]] && [[ "$("${target}" --version 2>/dev/null || true)" == "Sentinel v${version}" ]]; then
  echo "sentinel ${version} already installed at ${target}"
  exit 0
fi

command -v gpg >/dev/null 2>&1 || die "gpg is required to verify the download signature"
command -v unzip >/dev/null 2>&1 || die "unzip is required"

case "$(uname -s)" in
  Darwin) os="darwin" ;;
  Linux) os="linux" ;;
  *) die "unsupported OS: $(uname -s)" ;;
esac
case "$(uname -m)" in
  arm64 | aarch64) arch="arm64" ;;
  x86_64 | amd64) arch="amd64" ;;
  *) die "unsupported architecture: $(uname -m)" ;;
esac

zip="sentinel_${version}_${os}_${arch}.zip"
sums="sentinel_${version}_SHA256SUMS"

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

fetch() {
  curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 \
    --max-time 120 --output "${tmp}/$2" "$1"
}

echo "Downloading sentinel ${version} (${os}/${arch})"
fetch "${RELEASES_URL}/${version}/${zip}" "${zip}"
fetch "${RELEASES_URL}/${version}/${sums}" "${sums}"
fetch "${RELEASES_URL}/${version}/${sums}.sig" "${sums}.sig"
fetch "${HASHICORP_KEY_URL}" "hashicorp.asc"

# Verify the signature on the checksum file with a throwaway keyring.
export GNUPGHOME="${tmp}/gnupg"
mkdir -m 700 "${GNUPGHOME}"
gpg --batch --quiet --import "${tmp}/hashicorp.asc"
gpg --batch --with-colons --fingerprint | awk -F: '/^fpr/{print $10}' | grep -qx "${HASHICORP_FPR}" ||
  die "downloaded signing key does not match the pinned HashiCorp fingerprint"

status="$(gpg --batch --status-fd 1 --verify "${tmp}/${sums}.sig" "${tmp}/${sums}" 2>/dev/null)" ||
  die "signature verification failed for ${sums}"
signer="$(printf '%s\n' "${status}" | awk '/VALIDSIG/{print $NF}')"
[[ "${signer}" == "${HASHICORP_FPR}" ]] || die "checksum file was not signed by the pinned HashiCorp key"

# Verify the archive checksum.
if command -v sha256sum >/dev/null 2>&1; then
  sha_cmd=(sha256sum -c -)
else
  sha_cmd=(shasum -a 256 -c -)
fi
(cd "${tmp}" && grep " ${zip}\$" "${sums}" | "${sha_cmd[@]}") || die "checksum mismatch for ${zip}"

unzip -q -o "${tmp}/${zip}" sentinel -d "${tmp}/out"
mkdir -p "${bin_dir}"
install -m 0755 "${tmp}/out/sentinel" "${target}"

echo "Installed $("${target}" --version) at ${target}"
