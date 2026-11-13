#!/usr/bin/env bash
set -euo pipefail

zip_path=${1:?usage: audit-nostalgic-nethunter-ak3.sh ZIP_PATH EXPECTED_MODEL}
expected_model=${2:?usage: audit-nostalgic-nethunter-ak3.sh ZIP_PATH EXPECTED_MODEL}
zip_name=$(basename "$zip_path")

[[ -s "$zip_path" ]] || { echo "::error::Missing NOSTALGIC-AK3 archive: $zip_path"; exit 1; }
[[ "$zip_name" == NOSTALGIC-AK3_${expected_model}_*_NKSU_33198-6_SuSFS_v2.4.0_NOSTALGIC-NETHUNTER.zip ]] || {
  echo "::error::Non-canonical kernel archive name: $zip_name"
  exit 1
}

audit_dir=$(mktemp -d)
trap 'rm -rf "$audit_dir"' EXIT
unzip -q "$zip_path" -d "$audit_dir"

for required in Image anykernel.sh banner nethunter-profile-v2.json \
  nethunter-enabled-symbols.txt nethunter-unresolved-symbols.txt \
  nethunter-unsupported-symbols.txt modules/post-fs-data.sh; do
  [[ -s "$audit_dir/$required" ]] || {
    echo "::error::$zip_name is missing required payload: $required"
    exit 1
  }
done
for manifest in nethunter-modules.txt nethunter-modules.sha256; do
  [[ -f "$audit_dir/$manifest" ]] || {
    echo "::error::$zip_name is missing required payload: $manifest"
    exit 1
  }
done

grep -Fqx 'do.modules=1' "$audit_dir/anykernel.sh"
grep -Fqx 'do.systemless=1' "$audit_dir/anykernel.sh"
module_count=$(find "$audit_dir/modules/system/lib/modules" -type f -name '*.ko' | wc -l)
requested_module_count=$(grep -c '=m$' "$audit_dir/nethunter-enabled-symbols.txt" || true)
if [[ "$requested_module_count" -gt 0 && "$module_count" -eq 0 ]]; then
  echo "::error::$zip_name requests modular NetHunter adapters but contains no .ko payloads"
  exit 1
fi
if [[ "$requested_module_count" -gt 0 ]]; then
  [[ -s "$audit_dir/nethunter-modules.txt" && -s "$audit_dir/nethunter-modules.sha256" ]] || {
    echo "::error::$zip_name has modular adapters without non-empty module manifests"
    exit 1
  }
fi
while IFS= read -r enabled; do
  [[ "$enabled" == CONFIG_*=m ]] || continue
  symbol=${enabled#CONFIG_}
  symbol=${symbol%=m}
  case "$symbol" in
    ATH10K) expected='ath10k_core' ;;
    ATH6KL) expected='ath6kl_core' ;;
    RT2X00) expected='rt2x00lib' ;;
    MT76_USB) expected='mt76_usb' ;;
    RTL8812AU) expected='8812au' ;;
    RTL8814AU) expected='8814au' ;;
    RTL88XXAU) expected='88xxau' ;;
    RTW88) expected='rtw_core' ;;
    RTW88_USB) expected='rtw_usb' ;;
    USB_SERIAL) expected='usbserial' ;;
    *) expected=$(tr '[:upper:]-' '[:lower:]_' <<<"$symbol") ;;
  esac
  if ! tr '[:upper:]-' '[:lower:]_' < "$audit_dir/nethunter-modules.txt" | grep -qxF "$expected"; then
    echo "::error::$zip_name enables $enabled but does not package module $expected"
    exit 1
  fi
done < "$audit_dir/nethunter-enabled-symbols.txt"
(
  cd "$audit_dir"
  sha256sum --check --strict nethunter-modules.sha256
)

jq -e '.profile == "NOSTALGIC-NETHUNTER" and .version == 2 and .revision == 2 and
  .policy.gaming_tuning == false and .policy.rekernel == false and
  .policy.force_ntsync == false and .policy.force_bbr == false and
  .policy.override_lto == false and
  (.deferred_until_physical_pilot_boots | length) == 5' \
  "$audit_dir/nethunter-profile-v2.json" >/dev/null

expected_banner="$GITHUB_WORKSPACE/.github/actions/build-nethunter-kernel/assets/nostalgiksu-banner"
cmp -s "$audit_dir/banner" "$expected_banner" || {
  echo "::error::$zip_name does not contain the canonical NostalgiKSU flashing banner"
  exit 1
}

installer="$audit_dir/anykernel.sh"
grep -Fq 'kernel.string=NOSTALGIC Kernel Lab' "$installer"
grep -Fq 'ui_print "NostalgiKSU"' "$installer"
grep -Fq 'ui_print "NOSTALGIC Kernel Lab"' "$installer"
grep -Fq 'OKI Kernel Supported:' "$installer"
grep -Fq 'Built with love by NOSTALGIC @Reals3s' "$installer"
grep -Fq 'Core stack: NostalgiKSU 33198-6 + NOSTALGIC SuSFS 2.4.0 GKI-2' "$installer"
grep -Fq 'Credits: OnePlus OSS, NostalgiKSU contributors and AnyKernel3.' "$installer"
if find "$audit_dir" -type f -name module.prop -print -quit | grep -q .; then
  echo "::error::$zip_name contains module.prop and will be rejected as a module ZIP"
  exit 1
fi

# Audit only installer-visible text. Upstream branch names and implementation
# sources remain legitimate build inputs and are deliberately not rewritten.
visible_files=("$installer" "$audit_dir/banner")
while IFS= read -r -d '' file; do visible_files+=("$file"); done < <(
  find "$audit_dir" -maxdepth 1 -type f -name '*.txt' -print0
)
for file in \
  "$audit_dir/META-INF/com/google/android/update-binary" \
  "$audit_dir/META-INF/com/google/android/updater-script"; do
  [[ -f "$file" ]] && visible_files+=("$file")
done

if grep -IinE 'wild[[:space:]_-]*kernels?|wildkernels|fatalcoder|huangdihd|finasu|bakasu|resusfs|resuki' "${visible_files[@]}"; then
  echo "::error::Foreign project branding survived in installer-visible files of $zip_name"
  exit 1
fi

echo "NOSTALGIC-AK3 branding audit passed: $zip_name"
