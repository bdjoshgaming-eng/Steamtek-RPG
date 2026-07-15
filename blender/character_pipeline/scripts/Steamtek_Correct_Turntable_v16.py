"""Lock the Godot screen-direction turntable contract discovered by playable QA."""

from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path

import bpy


def arguments():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args(argv)


def main():
    args = arguments()
    facing_root = bpy.data.objects.get("ROOT_CharacterFacing")
    if facing_root is None:
        raise RuntimeError("Missing ROOT_CharacterFacing")
    facing_root.rotation_euler[2] = math.radians(-45.0)
    facing_root["steamtek_direction_contract"] = "v1.6_godot_clockwise_turntable"
    bpy.context.scene["steamtek_pipeline_version"] = "1.6.0"
    args.output.resolve().parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(args.output.resolve()), check_existing=False)
    print(f"STEAMTEK_TURNTABLE_CORRECTED={args.output.resolve()}")
    print("STEAMTEK_CHARACTER_FACING_YAW=-45.0")


if __name__ == "__main__":
    main()
