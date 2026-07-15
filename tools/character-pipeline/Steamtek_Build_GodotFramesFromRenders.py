"""Build a Godot 4 SpriteFrames resource from one or more production manifests."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def q(value: str) -> str:
    return value.replace("\\", "/").replace('"', '\\"')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("output", type=Path)
    parser.add_argument("--manifest", type=Path, action="append", required=True)
    parser.add_argument("--res-root", required=True, help="res:// path containing animation folders")
    parser.add_argument("--fps", type=float, default=8.0)
    args = parser.parse_args()

    resources: list[tuple[str, str]] = []
    animations: list[str] = []
    resource_number = 1
    for manifest_path in args.manifest:
        data = json.loads(manifest_path.read_text(encoding="utf-8"))
        animation = data["animation"]
        for direction in data["directions"]:
            frames: list[str] = []
            for relative_path in data["files"][direction]:
                resource_id = f"Texture_{resource_number}"
                resource_number += 1
                texture_path = f"{args.res_root.rstrip('/')}/{animation}/{relative_path}"
                resources.append((resource_id, texture_path))
                frames.append('{\n"duration": 1.0,\n"texture": ExtResource("' + resource_id + '")\n}')
            animations.append(
                '{\n"frames": [' + ", ".join(frames) + '],\n'
                f'"loop": true,\n"name": &"{animation}_{direction}",\n"speed": {args.fps}\n}}'
            )

    lines = [f'[gd_resource type="SpriteFrames" load_steps={len(resources) + 1} format=3]', ""]
    for resource_id, path in resources:
        lines.append(f'[ext_resource type="Texture2D" path="{q(path)}" id="{resource_id}"]')
    lines.extend(["", "[resource]", "animations = [" + ", ".join(animations) + "]", ""])
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("\n".join(lines), encoding="utf-8")
    print(f"GODOT_SPRITEFRAMES={args.output}")


if __name__ == "__main__":
    main()

