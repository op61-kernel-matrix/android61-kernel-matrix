#!/usr/bin/env bash
set -euo pipefail
zip_path=${1:?usage: audit-nostalgic-nethunter-network-ak3.sh ZIP_PATH EXPECTED_MODEL}
expected_model=${2:?usage: audit-nostalgic-nethunter-network-ak3.sh ZIP_PATH EXPECTED_MODEL}
zip_name=$(basename "$zip_path")
[[ -s "$zip_path" ]]
[[ "$zip_name" == NOSTALGIC-AK3_${expected_model}_*_NKSU_33198-6_SuSFS_v2.4.0_NOSTALGIC-NETHUNTER-NETWORK.zip ]]
audit_dir=$(mktemp -d)
trap 'rm -rf "$audit_dir"' EXIT
unzip -q "$zip_path" -d "$audit_dir"
for required in Image anykernel.sh banner nethunter-network-profile-v1.json \
  nethunter-enabled-symbols.txt; do
  [[ -s "$audit_dir/$required" ]] || { echo "::error::Missing network-pilot payload: $required"; exit 1; }
done
for manifest in nethunter-added-symbols.txt nethunter-unresolved-symbols.txt \
  nethunter-unsupported-symbols.txt nethunter-modules.txt nethunter-modules.sha256; do
  [[ -f "$audit_dir/$manifest" ]] || { echo "::error::Missing pilot manifest: $manifest"; exit 1; }
done
[[ ! -e "$audit_dir/nethunter-profile-v2.json" ]]
[[ ! -e "$audit_dir/modules/post-fs-data.sh" ]]
grep -Fqx 'do.modules=0' "$audit_dir/anykernel.sh"
jq -e '.profile == "NOSTALGIC-NETHUNTER-NETWORK" and .version == 1 and (.capabilities|length) == 6' \
  "$audit_dir/nethunter-network-profile-v1.json" >/dev/null
for required in CONFIG_TUN=y CONFIG_PACKET=y CONFIG_NETFILTER=y CONFIG_NET_NS=y; do
  grep -qxF "$required" "$audit_dir/nethunter-enabled-symbols.txt" || {
    echo "::error::Required network capability missing: $required"; exit 1;
  }
done
if grep -Eq 'CONFIG_(USB|HID|UHID|USB_HID|ATH|RT2|MT7|RTL|RTW|OVERLAY_FS|FUSE_FS|USER_NS|PID_NS)=' \
  "$audit_dir/nethunter-added-symbols.txt"; then
  echo '::error::Network pilot added an excluded USB/HID/adapter/filesystem/non-network-namespace symbol'
  exit 1
fi
echo "NetHunter network-only audit passed: $zip_name"
