"""Create a Godot 4 SpriteFrames resource from a Steamtek character atlas."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


def q(value: str) -> str:
    return value.replace("\\", "/").replace('"', '\\"')


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("metadata", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--texture-res-path", required=True)
    parser.add_argument("--fps", type=float, default=10.0)
    args = parser.parse_args()

    data = json.loads(args.metadata.read_text(encoding="utf-8"))
    cell_w, cell_h = data["cell_size"]
    frame_count = data["frames_per_direction"]
    directions = data["directions"]
    subresources: list[str] = []
    animations: list[str] = []

    for row, direction in enumerate(directions):
        frame_entries: list[str] = []
        for column in range(frame_count):
            resource_id = f"Atlas_{direction}_{column:02d}"
            subresources.extend(
                [
                    f'[sub_resource type="AtlasTexture" id="{resource_id}"]',
                    'atlas = ExtResource("1_texture")',
                    f"region = Rect2({column * cell_w}, {row * cell_h}, {cell_w}, {cell_h})",
                    "",
                ]
            )
            frame_entries.append(
                '{\n"duration": 1.0,\n"texture": SubResource("' + resource_id + '")\n}'
            )
        animation_name = f'{data["animation"]}_{direction}'
        animations.append(
            '{\n"frames": ['
            + ", ".join(frame_entries)
            + f'],\n"loop": true,\n"name": &"{animation_name}",\n"speed": {args.fps}\n}}'
        )

    lines = [
        f'[gd_resource type="SpriteFrames" load_steps={1 + frame_count * len(directions)} format=3]',
        "",
        f'[ext_resource type="Texture2D" path="{q(args.texture_res_path)}" id="1_texture"]',
        "",
        *subresources,
        "[resource]",
        "animations = [" + ", ".join(animations) + "]",
        "",
    ]
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text("\n".join(lines), encoding="utf-8")
    print(f"SPRITEFRAMES={args.output}")


if __name__ == "__main__":
    main()
