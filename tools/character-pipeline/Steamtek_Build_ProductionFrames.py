"""Downscale fixed 1254 Steamtek renders to fixed 256 Godot production frames."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("raw_animation_root", type=Path)
    parser.add_argument("production_animation_root", type=Path)
    parser.add_argument("--size", type=int, default=256)
    args = parser.parse_args()
    raw_manifest = json.loads((args.raw_animation_root / "render_manifest.json").read_text(encoding="utf-8"))
    args.production_animation_root.mkdir(parents=True, exist_ok=True)
    produced: dict[str, list[str]] = {}
    for direction in raw_manifest["directions"]:
        destination = args.production_animation_root / direction
        destination.mkdir(parents=True, exist_ok=True)
        produced[direction] = []
        for relative in raw_manifest["files"][direction]:
            source_path = args.raw_animation_root / relative
            output_path = destination / source_path.name
            with Image.open(source_path).convert("RGBA") as image:
                resized = image.resize((args.size, args.size), Image.Resampling.LANCZOS)
                resized.save(output_path, optimize=True)
            produced[direction].append(str(output_path.relative_to(args.production_animation_root)).replace("\\", "/"))

    source_width, source_height = raw_manifest["frame_size"]
    contact_x, contact_y = raw_manifest["ground_contact_pixel"]
    manifest = {
        **raw_manifest,
        "source_frame_size": raw_manifest["frame_size"],
        "frame_size": [args.size, args.size],
        "ground_contact_pixel": [
            round(contact_x * args.size / source_width),
            round(contact_y * args.size / source_height),
        ],
        "files": produced,
        "production_resize": "fixed_canvas_lanczos_no_crop",
    }
    output_manifest = args.production_animation_root / "production_manifest.json"
    output_manifest.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"PRODUCTION_MANIFEST={output_manifest}")


if __name__ == "__main__":
    main()

