#!/usr/bin/env bash
set -euo pipefail

zip_path=${1:?usage: audit-nostalgic-ak3.sh ZIP_PATH EXPECTED_MODEL}
expected_model=${2:?usage: audit-nostalgic-ak3.sh ZIP_PATH EXPECTED_MODEL}
zip_name=$(basename "$zip_path")

[[ -s "$zip_path" ]] || { echo "::error::Missing NOSTALGIC-AK3 archive: $zip_path"; exit 1; }
[[ "$zip_name" == NOSTALGIC-AK3_${expected_model}_*_NKSU_33174-6_SuSFS_v2.4.0.zip ]] || {
  echo "::error::Non-canonical kernel archive name: $zip_name"
  exit 1
}

audit_dir=$(mktemp -d)
trap 'rm -rf "$audit_dir"' EXIT
unzip -q "$zip_path" -d "$audit_dir"

for required in Image anykernel.sh banner; do
  [[ -s "$audit_dir/$required" ]] || {
    echo "::error::$zip_name is missing required payload: $required"
    exit 1
  }
done

expected_banner="$GITHUB_WORKSPACE/.github/actions/build-kernel/assets/nostalgiksu-banner"
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
grep -Fq 'Core stack: NostalgiKSU 33174-6 + NOSTALGIC SuSFS 2.4.0 GKI-2' "$installer"
grep -Fq 'Credits: OnePlus OSS, NostalgiKSU contributors and AnyKernel3.' "$installer"

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
