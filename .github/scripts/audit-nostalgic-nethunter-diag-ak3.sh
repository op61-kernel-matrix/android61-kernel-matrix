#!/usr/bin/env bash
set -euo pipefail
zip_path=${1:?usage: audit-nostalgic-nethunter-diag-ak3.sh ZIP_PATH EXPECTED_MODEL}
expected_model=${2:?usage: audit-nostalgic-nethunter-diag-ak3.sh ZIP_PATH EXPECTED_MODEL}
zip_name=$(basename "$zip_path")
[[ "$zip_name" == NOSTALGIC-AK3_${expected_model}_*_NKSU_33198-6_SuSFS_v2.4.0_NOSTALGIC-NETHUNTER-DIAG.zip ]]
audit_dir=$(mktemp -d); trap 'rm -rf "$audit_dir"' EXIT
unzip -q "$zip_path" -d "$audit_dir"
for required in Image anykernel.sh nethunter-network-diag-profile-v1.json \
  nethunter-enabled-symbols.txt nethunter-added-symbols.txt; do
  [[ -s "$audit_dir/$required" ]] || { echo "::error::Missing diagnostic-pilot payload: $required"; exit 1; }
done
printf '%s\n' CONFIG_PACKET_DIAG=y CONFIG_UNIX_DIAG=y | while read -r symbol; do
  grep -qxF "$symbol" "$audit_dir/nethunter-added-symbols.txt" || { echo "::error::Expected sole diagnostic delta missing: $symbol"; exit 1; }
done
[[ $(wc -l < "$audit_dir/nethunter-added-symbols.txt") -eq 2 ]] || {
  echo '::error::Diagnostic pilot contains changes beyond PACKET_DIAG and UNIX_DIAG'; exit 1;
}
[[ ! -e "$audit_dir/modules/post-fs-data.sh" ]]
grep -Fqx 'do.modules=0' "$audit_dir/anykernel.sh"
echo "NetHunter diagnostic-only audit passed: $zip_name"
