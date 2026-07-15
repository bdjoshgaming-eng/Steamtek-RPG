"""Verify that the discovered C001 golden-reference files remain unchanged."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path


def digest(path: Path) -> str:
    value = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            value.update(chunk)
    return value.hexdigest().upper()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("c001_root", type=Path)
    parser.add_argument("manifest", type=Path)
    args = parser.parse_args()
    data = json.loads(args.manifest.read_text(encoding="utf-8"))
    failures: list[str] = []
    for item in data["discovered_files"]:
        path = args.c001_root / item["relative_path"]
        if not path.exists():
            failures.append(f"missing: {path}")
        elif digest(path) != item["sha256"]:
            failures.append(f"hash changed: {path}")
    if failures:
        raise SystemExit("C001 GOLDEN REFERENCE CHECK FAILED\n" + "\n".join(failures))
    print("C001 GOLDEN REFERENCE VERIFIED: no discovered reference file changed")


if __name__ == "__main__":
    main()

