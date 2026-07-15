"""Render the active Steamtek character root in eight locked directions."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from steamtek_character_standard import DIRECTIONS, configure_character_stage, direction_radians


def arguments():
    argv = sys.argv
    argv = argv[argv.index("--") + 1 :] if "--" in argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--character-id", default="CDEV_Proxy")
    parser.add_argument("--animation", default="walk")
    parser.add_argument("--output", required=True)
    parser.add_argument("--frame-start", type=int, default=None)
    parser.add_argument("--frame-end", type=int, default=None)
    return parser.parse_args(argv)


def main():
    args = arguments()
    scene = bpy.context.scene
    root = bpy.data.objects.get("STK_CharacterRoot")
    if root is None:
        raise RuntimeError("Missing STK_CharacterRoot. Parent the model/rig to this root before rendering.")

    configure_character_stage(scene)
    start = args.frame_start if args.frame_start is not None else scene.frame_start
    end = args.frame_end if args.frame_end is not None else scene.frame_end
    output_root = Path(args.output).resolve() / args.character_id / args.animation

    # The character root is the authoritative foot contact. Record its exact
    # projected pixel rather than estimating a pivot from changing alpha bounds.
    contact = world_to_camera_view(scene, scene.camera, Vector((0.0, 0.0, 0.0)))
    boot_contact = [
        round(contact.x * scene.render.resolution_x),
        round((1.0 - contact.y) * scene.render.resolution_y),
    ]
    output_root.mkdir(parents=True, exist_ok=True)
    (output_root / "render_manifest.json").write_text(
        json.dumps(
            {
                "character_id": args.character_id,
                "animation": args.animation,
                "frame_size": [scene.render.resolution_x, scene.render.resolution_y],
                "boot_contact": boot_contact,
                "root_world_contact": [0.0, 0.0, 0.0],
            },
            indent=2,
        ),
        encoding="utf-8",
    )

    original_rotation = root.rotation_euler.copy()
    try:
        for direction, _degrees in DIRECTIONS:
            root.rotation_euler[2] = direction_radians(direction)
            direction_dir = output_root / direction
            direction_dir.mkdir(parents=True, exist_ok=True)
            for frame in range(start, end + 1):
                scene.frame_set(frame)
                scene.render.filepath = str(direction_dir / f"{frame - start:03d}.png")
                bpy.ops.render.render(write_still=True)
                print(f"RENDERED {args.character_id} {args.animation} {direction} {frame}")
    finally:
        root.rotation_euler = original_rotation
        scene.frame_set(start)


if __name__ == "__main__":
    main()
