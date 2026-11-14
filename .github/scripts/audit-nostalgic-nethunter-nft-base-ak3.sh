#!/usr/bin/env bash
set -euo pipefail
zip_path=${1:?usage: audit-nostalgic-nethunter-nft-base-ak3.sh ZIP_PATH EXPECTED_MODEL}
expected_model=${2:?usage: audit-nostalgic-nethunter-nft-base-ak3.sh ZIP_PATH EXPECTED_MODEL}
zip_name=$(basename "$zip_path")
[[ "$zip_name" == NOSTALGIC-AK3_${expected_model}_*_NKSU_33198-6_SuSFS_v2.4.0_NOSTALGIC-NETHUNTER-NFTBASE.zip ]]
audit_dir=$(mktemp -d); trap 'rm -rf "$audit_dir"' EXIT
unzip -q "$zip_path" -d "$audit_dir"
for required in Image anykernel.sh nethunter-nft-base-profile-v1.json nethunter-added-symbols.txt; do
  [[ -s "$audit_dir/$required" ]] || { echo "::error::Missing nftables-base pilot payload: $required"; exit 1; }
done
expected=$(mktemp)
printf '%s\n' CONFIG_PACKET_DIAG=y CONFIG_UNIX_DIAG=y CONFIG_NF_TABLES=y | sort > "$expected"
sort "$audit_dir/nethunter-added-symbols.txt" | cmp -s - "$expected" || {
  echo '::error::Pilot delta differs from the two proven diagnostics plus NF_TABLES only'; exit 1;
}
[[ ! -e "$audit_dir/modules/post-fs-data.sh" ]]
grep -Fqx 'do.modules=0' "$audit_dir/anykernel.sh"
echo "NetHunter nftables-base audit passed: $zip_name"
