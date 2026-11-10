# NostalgiKSU OnePlus kernel matrix

This repository builds the reviewed 169-target OnePlus catalog with
NostalgiKSU 33182-6 and SuSFS 2.4.0. Its target filenames exactly match the
WildKernels v2.4.0-r1 catalog, while the build, installer and release identity
remain strictly NOSTALGIC.

The single pilot is `configs/a16/OP13r-6.1.141.json`. No other build starts
until that target passes. The ordinary 168-target matrix then begins with the
rolling OnePlus 13R configuration, currently producing kernel 6.1.157, followed
by the other 167 targets. The 6.1.157 build is prioritized for testing but is
not a second pilot or a separate acceptance gate.

The matrix contains 38 Android 12/5.10, 29 Android 13/5.15, 59 Android
14/6.1, 35 Android 15/6.6 and 8 Android 16/6.12 targets. Every family is locked
to an immutable Simonpunk SuSFS commit whose header must report exactly 2.4.0.
All builds must pass Inline hook, seccomp, image identity, installer identity
and required SuSFS capability audits.

Every successful kernel has the canonical filename:

`NOSTALGIC-AK3_<model>_<OS>_<kernel>_NKSU_33182-6_SuSFS_v2.4.0.zip`

The audit rejects a generic `AK3`, FinaSU/KSUN/KSU filename, foreign installer
branding, an incorrect NostalgiKSU version, or any other SuSFS version. The
flashing UI uses the canonical NostalgiKSU banner; the filename intentionally
uses the shorter `NOSTALGIC-AK3` and `NKSU` identities.

Run `Launch-Full-169-Matrix.cmd` to dispatch a validation matrix without
publishing a release. Release publication is a separate explicit workflow
input and succeeds only after all 169 artifacts pass.
