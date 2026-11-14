#!/usr/bin/env bash
set -euo pipefail
kernel_zip=${1:?usage: audit-nostalgic-nethunter-rtw88-ak3.sh KERNEL_ZIP WIRELESS_ZIP EXPECTED_MODEL}
wireless_zip=${2:?usage: audit-nostalgic-nethunter-rtw88-ak3.sh KERNEL_ZIP WIRELESS_ZIP EXPECTED_MODEL}
expected_model=${3:?usage: audit-nostalgic-nethunter-rtw88-ak3.sh KERNEL_ZIP WIRELESS_ZIP EXPECTED_MODEL}
[[ $(basename "$kernel_zip") == NOSTALGIC-AK3_${expected_model}_*_NOSTALGIC-NETHUNTER-RTW88.zip ]]
[[ $(basename "$wireless_zip") == WirelessKSU_${expected_model}_*_RTW88-ALL.zip ]]
audit_dir=$(mktemp -d); trap 'rm -rf "$audit_dir"' EXIT
unzip -q "$kernel_zip" -d "$audit_dir/kernel"
unzip -q "$wireless_zip" -d "$audit_dir/wireless"
grep -Fqx 'do.modules=0' "$audit_dir/kernel/anykernel.sh"
! grep -Eq '^CONFIG_(NF_TABLES|NFT_)' "$audit_dir/kernel/nethunter-enabled-symbols.txt"
for required in rfkill cfg80211 mac80211 rtw_core rtw_usb rtw_8812au rtw_8814au rtw_8821au rtw_8821cu rtw_8822bu rtw_8822cu; do
  [[ -s "$audit_dir/wireless/lkm/${required}.ko" ]] || { echo "::error::Missing RTW88 module: $required"; exit 1; }
done
[[ -s "$audit_dir/wireless/system/etc/firmware/rtw88/rtw8812a_fw.bin" ]]
[[ -s "$audit_dir/wireless/post-fs-data.sh" ]]
echo 'NOSTALGIC RTW88 kernel and WirelessKSU package audit passed'
