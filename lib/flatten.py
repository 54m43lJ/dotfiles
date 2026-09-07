#!/usr/bin/env python3
"""Flatten a module list into executable leaves.

Bundles are pure-data modules: their module.sh only assigns BUNDLE=(...).
Expansion is depth-first in first-occurrence order; the seen-set dedupes
repeats and breaks include cycles. Bundle names themselves never reach
the output list.
"""
import re
import sys
from pathlib import Path

BUNDLE_RE = re.compile(r"^BUNDLE=\(([^)]*)\)", re.MULTILINE)


def warn(msg):
    print(f" !! {msg}", file=sys.stderr)


def members_of(root, mod):
    """BUNDLE members for a bundle, [] for a leaf, None if module missing."""
    try:
        text = (root / mod / "module.sh").read_text()
    except OSError:
        return None
    m = BUNDLE_RE.search(text)
    return m.group(1).split() if m else []


def main():
    if len(sys.argv) < 3:
        warn(f"usage: {sys.argv[0]} <repo-root> <module>...")
        return 1
    root = Path(sys.argv[1])
    flattened = []
    seen = set()

    def visit(mod):
        if not mod or mod in seen:
            return
        seen.add(mod)
        members = members_of(root, mod)
        if members is None:
            warn(f"module '{mod}' not found at {root / mod / 'module.sh'}, skipping")
        elif members:
            for m in members:
                visit(m)
        else:
            flattened.append(mod)

    for mod in sys.argv[2:]:
        visit(mod)
    print("\n".join(flattened))
    return 0


if __name__ == "__main__":
    sys.exit(main())
