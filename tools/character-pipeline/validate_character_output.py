"""Validate Steamtek character render count, cells, alpha, and metadata."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image


DIRECTIONS = (
    "south", "south_west", "west", "north_west",
    "north", "north_east", "east", "south_east",
)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("renders", type=Path)
    parser.add_argument("metadata", type=Path)
    parser.add_argument("--character-id", required=True)
    parser.add_argument("--animation", default="walk")
    args = parser.parse_args()

    metadata = json.loads(args.metadata.read_text(encoding="utf-8"))
    expected_size = tuple(metadata["cell_size"])
    expected_count = metadata["frames_per_direction"]
    animation_root = args.renders / args.character_id / args.animation
    failures: list[str] = []

    for direction in DIRECTIONS:
        files = sorted((animation_root / direction).glob("*.png"))
        if len(files) != expected_count:
            failures.append(f"{direction}: expected {expected_count} frames, found {len(files)}")
            continue
        for path in files:
            with Image.open(path).convert("RGBA") as frame:
                if frame.size != expected_size:
                    failures.append(f"{path}: expected {expected_size}, found {frame.size}")
                if frame.getchannel("A").getbbox() is None:
                    failures.append(f"{path}: empty alpha")

    if metadata.get("directions") != list(DIRECTIONS):
        failures.append("metadata direction order is not the locked Steamtek order")
    if not metadata.get("boot_contact"):
        failures.append("metadata is missing Blender-projected boot contact")
    if failures:
        raise SystemExit("CHARACTER PIPELINE QA FAILED\n" + "\n".join(failures))
    print(
        f"CHARACTER PIPELINE QA PASSED: {len(DIRECTIONS)} directions, "
        f"{expected_count} frames each, {expected_size[0]}x{expected_size[1]} cells"
    )


if __name__ == "__main__":
    main()
