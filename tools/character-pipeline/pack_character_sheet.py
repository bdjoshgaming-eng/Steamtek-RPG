"""Pack fixed Steamtek character renders into a Godot-friendly 8-row atlas."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image


DIRECTIONS = (
    "south",
    "south_west",
    "west",
    "north_west",
    "north",
    "north_east",
    "east",
    "south_east",
)


def alpha_bounds(image: Image.Image):
    return image.getchannel("A").getbbox()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--character-id", required=True)
    parser.add_argument("--animation", default="walk")
    parser.add_argument("--target-world-height", type=float, default=100.0)
    args = parser.parse_args()

    rows = []
    animation_root = args.input / args.character_id / args.animation
    for direction in DIRECTIONS:
        files = sorted((animation_root / direction).glob("*.png"))
        if not files:
            raise SystemExit(f"No frames found for {direction}")
        rows.append(files)

    frame_count = len(rows[0])
    if any(len(row) != frame_count for row in rows):
        raise SystemExit("Every direction must contain the same number of frames")

    first = Image.open(rows[0][0]).convert("RGBA")
    cell_w, cell_h = first.size
    sheet = Image.new("RGBA", (cell_w * frame_count, cell_h * len(DIRECTIONS)), (0, 0, 0, 0))
    max_alpha_height = 0

    for row_index, files in enumerate(rows):
        for column_index, path in enumerate(files):
            frame = Image.open(path).convert("RGBA")
            if frame.size != (cell_w, cell_h):
                raise SystemExit(f"Frame size mismatch: {path}")
            bounds = alpha_bounds(frame)
            if bounds:
                max_alpha_height = max(max_alpha_height, bounds[3] - bounds[1])
            sheet.alpha_composite(frame, (column_index * cell_w, row_index * cell_h))

    args.output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(args.output, optimize=True)
    suggested_scale = args.target_world_height / max_alpha_height if max_alpha_height else 1.0
    render_manifest_path = animation_root / "render_manifest.json"
    render_manifest = (
        json.loads(render_manifest_path.read_text(encoding="utf-8"))
        if render_manifest_path.exists()
        else {}
    )
    boot_contact = render_manifest.get("boot_contact", [cell_w // 2, int(cell_h * 0.88)])
    metadata = {
        "character_id": args.character_id,
        "animation": args.animation,
        "directions": list(DIRECTIONS),
        "frames_per_direction": frame_count,
        "cell_size": [cell_w, cell_h],
        "sheet_size": list(sheet.size),
        "row_order": {name: index for index, name in enumerate(DIRECTIONS)},
        "boot_contact": boot_contact,
        "max_visible_alpha_height": max_alpha_height,
        "target_world_height": args.target_world_height,
        "suggested_godot_visual_scale": round(suggested_scale, 6),
    }
    metadata_path = args.output.with_suffix(".json")
    metadata_path.write_text(json.dumps(metadata, indent=2), encoding="utf-8")
    print(f"SHEET={args.output}")
    print(f"METADATA={metadata_path}")


if __name__ == "__main__":
    main()
