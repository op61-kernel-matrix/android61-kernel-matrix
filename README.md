# Android 6.1 Kernel Matrix

Public GitHub Actions matrix for the OnePlus 13R OOS16 Android 14 6.1.141 kernel.

The workflow downloads its manifest and kernel inputs from public upstream sources. It uses GitHub Actions caches for compiler output and defaults to `clean_build: false` so later runs can reuse compatible cached objects. GitHub-hosted runners themselves are temporary; only the declared caches persist between runs.

No local runner, Gitea endpoint, local filesystem path, manager source, or NoMount integration is used.
