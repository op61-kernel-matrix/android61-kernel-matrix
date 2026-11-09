#!/usr/bin/env python3
"""Apply narrowly scoped OnePlus compatibility fixes used with SuSFS 2.4.0."""

from __future__ import annotations

import re
import sys
from pathlib import Path


def main() -> int:
    if len(sys.argv) != 3:
        raise SystemExit("usage: apply-susfs-240-oneplus-compat.py COMMON_DIR KERNEL_VERSION")

    common = Path(sys.argv[1]).resolve()
    kernel_version = sys.argv[2]
    if not common.is_dir():
        raise SystemExit(f"kernel common directory does not exist: {common}")

    changed: list[Path] = []
    # Recent OnePlus 6.1 trees may export this vendor scheduler helper. Fatal's
    # 2.4.0 release notes identify that export as a 6.1.141+ boot-loop trigger.
    export = re.compile(
        r"^[ \t]*EXPORT_SYMBOL(?:_GPL)?\([ \t]*test_task_ux[ \t]*\);[ \t]*\n?",
        re.MULTILINE,
    )
    if kernel_version.startswith("6.1."):
        sublevel = int(kernel_version.split(".", 2)[2].split("-", 1)[0])
        if sublevel >= 141:
            for path in common.rglob("*.[ch]"):
                try:
                    text = path.read_text()
                except (OSError, UnicodeDecodeError):
                    continue
                updated, count = export.subn("", text)
                if count:
                    path.write_text(updated)
                    changed.append(path.relative_to(common))

    if changed:
        print("Removed unsafe test_task_ux export from:")
        for path in changed:
            print(f"  {path}")
    else:
        print("No unsafe test_task_ux export was present")

    # Fail closed: this helper must never remove the function implementation.
    implementations = 0
    for path in common.rglob("*.[ch]"):
        try:
            implementations += path.read_text().count("test_task_ux(")
        except (OSError, UnicodeDecodeError):
            pass
    if changed and implementations == 0:
        raise SystemExit("test_task_ux implementation disappeared while removing its export")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
