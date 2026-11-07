# OnePlus Android 5.10 Matrix Provenance

This matrix imports the Android 5.10 entries from the same proven Fatal base
used by the Android 6.1 matrix:

- Repository: `WildKernels/OnePlus_KernelSU_SUSFS`
- Tag: `v2.2.0-r4`
- Commit: `d44240312aeb978463b66c3a3155c6d99a7c7a3c`
- Imported scope: Android 12 GKI 5.10 for A14, A15, and A16
- Reviewed matrix size: 38 targets (9 A14, 23 A15, 6 A16)

The imported Fatal configuration schema identifies the userspace generation as
`A14`, `A15`, or `A16`. These values are preserved verbatim because they select
the matching manifest directory and version-specific patch assets; the shared
action validates them alongside its existing `OOS##` schema.

The device manifests, branches, toolchains, and model settings remain those of
the proven Fatal release. The root stack and packaging contract use the shared
NostalgiKSU matrix action:

- NostalgiKSU `33168`
- Kernel identity `v1.4.5-33168-1389d796@ci`
- SuSFS commit `ee155a1ad4219804a7c54cb39dd4fa1b5c2a3fa4`
- Nine required SuSFS capability markers
- `CONFIG_KSU_HOOK_TRACEPOINT=n`
- `CONFIG_KSU_HOOK_SUSFS_INLINE=y`
- `CONFIG_SECCOMP=y`
- `CONFIG_SECCOMP_FILTER=y`
- NOSTALGIC AnyKernel3 branding and strict installer failure handling

Every build uses `clean: false`, GitHub Actions ccache/LTO caches, and uploads a
portable compiler-cache artifact for later import into the local Gitea runner.
The optional `target_config` input runs one reviewed member; leaving it empty
builds all 38 targets.
