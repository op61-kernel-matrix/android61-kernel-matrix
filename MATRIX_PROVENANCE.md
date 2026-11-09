# OnePlus Kernel Matrix Provenance

This repository's first full matrix is derived from the last proven Fatal
OnePlus release used as the stable base for the earlier large kernel set:

- Repository: `WildKernels/OnePlus_KernelSU_SUSFS`
- Tag: `v2.2.0-r4`
- Commit: `d44240312aeb978463b66c3a3155c6d99a7c7a3c`
- Release workflow/run: `Build and Release OnePlus Kernels` / `31582235180`
- Original release scope: 158 builds
- Imported phase: Android 14 GKI 6.1 on OOS 15 and OOS 16
- Imported matrix size: 50 targets

The Fatal configurations and manifests are the device/source/toolchain base.
The root stack is deliberately replaced by the proven NostalgiKSU pilot
contract:

- NostalgiKSU `33168`
- Kernel identity `v1.4.5-33168-1389d796@ci`
- Run-33 Manager certificate SHA-256
  `ef8aaae7a7b2f8d662c149d80a8aa7f4151d90b539a5707c9506a76c319fd456`
- SuSFS commit `ee155a1ad4219804a7c54cb39dd4fa1b5c2a3fa4`
- Nine required SuSFS capability markers
- Inline hook mode
- NostalgiKSU-only AnyKernel3 branding and strict installer failure handling

## Authoritative future-build reference

Fatal/WildKernels workflow run `38894819716` is the authoritative source and
configuration reference for all future matrix families:

- Workflow: `Build and Release OnePlus Kernels` run `#1120`
- Commit: `d137109`
- Result: success, 158 of 158 matrix jobs, 158 artifacts
- OP-ACE-2V reference tuple: `dimensity9000`, `wild/mt6983`,
  `oneplus_ace2v_w.xml`, `android12`, `5.10`, `A16`, `KSUN`

Its successful device manifests, source branches, toolchains and build flags
are the baseline. NostalgiKSU overlays must preserve Inline hook mode and
Seccomp `Filter`; Hybrid hooks and disabled Seccomp are forbidden fallbacks.
The Fatal/WildKernels installer presentation is not inherited: final packages
must retain the NOSTALGIC filename, yellow `NostalgiKSU` flashing header,
OKI-supported line and NOSTALGIC footer contract described below.

Every matrix flashable ZIP must preserve the proven run-8 presentation:

- Filename begins `NOSTALGIC-AK3_` and ends `SuSFS_2.3.0.zip`.
- The Manager flashing screen displays the large yellow `NostalgiKSU` header.
- The installer reports `OKI Kernel Supported: true` before the NOSTALGIC
  footer on supported 6.1 kernels.
- The footer uses `NOSTALGIC Kernel Lab`, credits `NOSTALGIC @Reals3s`, reports
  `NostalgiKSU 33168 + NOSTALGIC SuSFS 2.3.0 GKI-2`, and contains no inherited
  ReSukiSU, ReSuSFS, BakaSU, Huangdihd, or NoMount branding.

`configs/oos16/OP13r-6.1.141.json` is retained as the proven run-8 pilot and
replaces the equivalent imported `configs/oos16/OP13r.json` matrix member. The
latter remains in the repository for source comparison but is excluded by the
matrix generator. Therefore the dispatched matrix remains exactly 50 builds.
Its post-build validation requires the `6.1.*-android14` family and the exact
stock suffix `8-g88433133-ab68376540`; the patch-level component is obtained
from the built source rather than incorrectly treating matrix family `6.1` as
the complete release number.

The workflow's optional `target_config` dispatch input runs one reviewed matrix
member for a focused repair. Leaving it empty preserves the complete 50-target
matrix. This allows the pilot validator correction to reuse its cache without
rebuilding the 49 already successful targets.

All matrix builds use `clean: false`, GitHub Actions ccache/LTO caches, and a
portable ccache artifact capped at 2 GiB per successful target. The portable
archive and metadata are intended for later download and extraction into the
local Gitea runner's ccache directory.

## Android 5.10 family pin

The Android 12 GKI 5.10 matrix uses the family-specific SuSFS revision recorded
by the same proven WildKernels `v2.2.0-r4` release:

- Kernel family: `android12-5.10`
- SuSFS commit: `b0e474642cf77ee797004a454fa441362723d0ba`
  (audited Android 12 / 5.10 family pin containing the
  `susfs_set_current_proc_no_su` and `susfs_is_current_proc_no_su` API required
  by final NostalgiKSU SuCompat)
- Required patch: `kernel_patches/50_add_susfs_in_gki-android12-5.10.patch`

The Android 6.1 SuSFS revision must not be reused for 5.10. The build action
now verifies that the selected family patch exists and is non-empty before it
touches the kernel tree, preventing a missing patch from surfacing later as a
misleading inline-hook compilation failure.

That proven family patch predates three direct calls required by the finalized
NostalgiKSU 33168 inline ABI. For Android 12 / 5.10 NostalgiKSU builds, the
action therefore completes `do_execveat_common()` with the current direct
contract after applying the pinned family patch:

- `ksu_handle_post_execveat_sucompat`
- `ksu_setup_preinit_file`
- `ksu_preinit_handle_post_execveat`

This is a real hook-site integration with the upstream preinit retry and
post-exec control flow. The inline checker is not bypassed, and the workflow
does not fall back to Hybrid mode. All reviewed 5.10 targets continue to
require Inline hook mode and seccomp Filter.

## Unified 158-target release workflow

`.github/workflows/oneplus-full-158-matrix.yml` is the canonical full release
entry point. One dispatch validates and builds exactly 158 targets across all
five supported GKI families: 38 Android 12/5.10, 25 Android 13/5.15, 53 Android
14/6.1, 34 Android 15/6.6, and 8 Android 16/6.12.

The proven `configs/oos16/OP13r-6.1.141.json` device is job 1 and replaces the
older `configs/a16/OP13r-6.1.118.json` member. The other 157 jobs are gated on
that pilot succeeding, so an invalid baseline cannot consume the full matrix.
Every family reference is resolved to an immutable Simonpunk commit before the
pilot begins, and preparation fails unless its header reports exactly SuSFS
2.3.0 and its matching family patch exists.

The shared build action remains the sole implementation and release gate. It
must pass all nine SuSFS capability checks, Inline hook verification, Seccomp
Filter verification, NostalgiKSU/installer branding checks and artifact audit
before that target's flashable ZIP is uploaded. The final confirmation job is
green only when the pilot and all remaining 157 targets are green; partial
matrices are never reported as complete releases.
