# Android 6.1 Kernel Matrix

Public GitHub Actions matrix for the OnePlus 13R OOS16 Android 14 6.1.141 kernel.

The workflow downloads the OnePlus and SUSFS inputs from their public upstreams. The `nostalgiksu/` directory is the exact kernel/ABI slice from device-verified NostalgiKSU run 55, source commit `4373b04d2171c194d398c7e2ab1bbbdca65e1c40`; it is compiled as version `33174` and presented by the flashing installer as `33174-6` without substituting another KernelSU fork. GitHub-hosted runners are temporary, while the declared compiler caches persist between compatible runs.

The pilot build is deliberately minimal: stock-shaped `6.1.141-android14-8-g88433133-ab68376540` release identity, NostalgiKSU, SUSFS 2.3.0, and the nine required SUSFS capabilities. Optional scheduler, networking, Droidspaces, NoMount, and unrelated tuning patches are disabled until the kernel passes device boot validation.

The OnePlus common kernel, msm-kernel, and modules/device-tree projects are pinned together to the `CPH2645/CPH2647/CPH2691_16.0.5.701(EX01)` source release. The upstream OOS16 branch is moving and currently builds 6.1.157, so following its tip would not reproduce the phone's 6.1.141 kernel.
