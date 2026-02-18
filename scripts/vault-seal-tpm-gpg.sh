#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  vault-seal-tpm-gpg.sh --tpm-share PATH --gpg-share PATH --gpg-recipient KEYID

Options:
  --tpm-handle HEX        TPM handle to evict into (default: 0x81000001)
  --pcrs LIST             PCR list for policy (default: 0,2,7)
  --gpg-out PATH          Output path for encrypted share (default: /var/lib/vault/unseal_share_gpg.gpg)
  --force-handle          Evict existing object at handle if present
  -h, --help              Show this help

Notes:
  - Run as root (TPM and /var/lib/vault access).
  - Expects plaintext unseal shares produced by "vault operator rekey".
EOF
}

tpm_share=""
gpg_share=""
gpg_recipient=""
tpm_handle="0x81000001"
pcrs="0,2,7"
gpg_out="/var/lib/vault/unseal_share_gpg.gpg"
force_handle="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tpm-share) tpm_share="$2"; shift 2 ;;
    --gpg-share) gpg_share="$2"; shift 2 ;;
    --gpg-recipient) gpg_recipient="$2"; shift 2 ;;
    --tpm-handle) tpm_handle="$2"; shift 2 ;;
    --pcrs) pcrs="$2"; shift 2 ;;
    --gpg-out) gpg_out="$2"; shift 2 ;;
    --force-handle) force_handle="true"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ -z "$tpm_share" || -z "$gpg_share" || -z "$gpg_recipient" ]]; then
  echo "Missing required arguments." >&2
  usage
  exit 1
fi

if [[ $EUID -ne 0 ]]; then
  echo "This script must run as root." >&2
  exit 1
fi

for cmd in tpm2_createpolicy tpm2_createprimary tpm2_create tpm2_load tpm2_evictcontrol tpm2_readpublic gpg; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Missing command: $cmd" >&2; exit 1; }
done

for f in "$tpm_share" "$gpg_share"; do
  [[ -f "$f" ]] || { echo "Missing file: $f" >&2; exit 1; }
done

if ! gpg --list-keys "$gpg_recipient" >/dev/null 2>&1; then
  echo "GPG recipient not found in keyring: $gpg_recipient" >&2
  exit 1
fi

mkdir -p /var/lib/vault
umask 0077

if tpm2_readpublic -c "$tpm_handle" >/dev/null 2>&1; then
  if [[ "$force_handle" == "true" ]]; then
    tpm2_evictcontrol -C o -c "$tpm_handle"
  else
    echo "TPM handle $tpm_handle already in use. Use --force-handle or pick another handle." >&2
    exit 1
  fi
fi

tpm2_createpolicy --policy-pcr -l "sha256:${pcrs}" -L /var/lib/vault/pcr.policy
tpm2_createprimary -C o -c /var/lib/vault/tpm.primary

tpm2_create -C /var/lib/vault/tpm.primary \
  -u /var/lib/vault/unseal1.pub -r /var/lib/vault/unseal1.priv \
  -L /var/lib/vault/pcr.policy -i "$tpm_share"

tpm2_load -C /var/lib/vault/tpm.primary \
  -u /var/lib/vault/unseal1.pub -r /var/lib/vault/unseal1.priv \
  -c /var/lib/vault/unseal1.ctx

tpm2_evictcontrol -C o -c /var/lib/vault/unseal1.ctx "$tpm_handle"

gpg --encrypt --recipient "$gpg_recipient" --output "$gpg_out" "$gpg_share"

shred -u "$tpm_share" "$gpg_share"

echo "Done."
echo "TPM handle: $tpm_handle"
echo "GPG share: $gpg_out"
