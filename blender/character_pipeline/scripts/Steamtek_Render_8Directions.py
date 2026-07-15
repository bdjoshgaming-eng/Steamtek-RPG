"""Render genuine eight-direction Steamtek animation frames on a fixed canvas."""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import bpy
from bpy_extras.object_utils import world_to_camera_view
from mathutils import Vector


SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))
from Steamtek_Validate_CharacterScene import validate


def arguments():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--character-id", required=True)
    parser.add_argument("--animation", required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--frame-start", type=int)
    parser.add_argument("--frame-end", type=int)
    parser.add_argument("--production", action="store_true")
    return parser.parse_args(argv)


def main() -> None:
    args = arguments()
    manifest = json.loads(args.manifest.resolve().read_text(encoding="utf-8"))
    failures, warnings = validate(manifest, args.production)
    for warning in warnings:
        print(f"WARNING: {warning}")
    if failures:
        raise RuntimeError("STEAMTEK RENDER REFUSED\n" + "\n".join(failures))
    if args.animation not in manifest["animations"]:
        raise RuntimeError(f"Animation is not in the manifest: {args.animation}")

    scene = bpy.context.scene
    contract = manifest["scene_contract"]
    root = bpy.data.objects[contract["direction_root"]]
    armature = bpy.data.objects[contract["armature"]]
    action_name = manifest["animations"][args.animation]["action"]
    action = bpy.data.actions.get(action_name)
    if action is None:
        raise RuntimeError(f"Missing Blender action: {action_name}")
    if armature.animation_data is None:
        armature.animation_data_create()

    start = args.frame_start if args.frame_start is not None else int(action.frame_range[0])
    end = args.frame_end if args.frame_end is not None else int(action.frame_range[1])
    if end < start:
        raise RuntimeError("frame end precedes frame start")

    output_root = args.output.resolve() / args.character_id / args.animation
    contact = world_to_camera_view(scene, scene.camera, Vector(manifest["model"]["ground_contact_world"]))
    contact_pixel = [
        round(contact.x * scene.render.resolution_x),
        round((1.0 - contact.y) * scene.render.resolution_y),
    ]
    original_rotation = root.rotation_euler.copy()
    original_action = armature.animation_data.action
    original_frame = scene.frame_current
    rendered: dict[str, list[str]] = {}
    try:
        armature.animation_data.action = action
        for direction in manifest["directions"]:
            name = direction["name"]
            root.rotation_euler[2] = math.radians(direction["rotation_degrees"])
            direction_dir = output_root / name
            direction_dir.mkdir(parents=True, exist_ok=True)
            rendered[name] = []
            for frame in range(start, end + 1):
                scene.frame_set(frame)
                filename = f"{args.character_id}_{args.animation}_{name}_{frame - start + 1:04d}.png"
                path = direction_dir / filename
                scene.render.filepath = str(path)
                bpy.ops.render.render(write_still=True)
                rendered[name].append(str(path.relative_to(output_root)).replace("\\", "/"))
                print(f"RENDERED {name} frame {frame}")
    finally:
        root.rotation_euler = original_rotation
        armature.animation_data.action = original_action
        scene.frame_set(original_frame)

    render_manifest = {
        "schema_version": "1.0.0",
        "character_id": args.character_id,
        "animation": args.animation,
        "action": action_name,
        "frame_start": start,
        "frame_end": end,
        "frames_per_direction": end - start + 1,
        "frame_size": [scene.render.resolution_x, scene.render.resolution_y],
        "ground_contact_pixel": contact_pixel,
        "directions": [item["name"] for item in manifest["directions"]],
        "files": rendered,
        "fixed_canvas": True,
        "mirrored": False
    }
    output_root.mkdir(parents=True, exist_ok=True)
    (output_root / "render_manifest.json").write_text(json.dumps(render_manifest, indent=2), encoding="utf-8")
    print(f"RENDER_MANIFEST={output_root / 'render_manifest.json'}")


if __name__ == "__main__":
    main()

