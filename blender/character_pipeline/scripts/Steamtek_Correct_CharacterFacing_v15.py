"""Correct the locked Steamtek character-facing adapter after in-game motion QA."""

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
    facing_root.rotation_euler[2] = math.radians(135.0)
    facing_root["steamtek_direction_contract"] = "v1.5_godot_movement_aligned"
    bpy.context.scene["steamtek_pipeline_version"] = "1.5.0"
    args.output.resolve().parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(args.output.resolve()), check_existing=False)
    print(f"STEAMTEK_DIRECTION_CORRECTED={args.output.resolve()}")
    print("STEAMTEK_CHARACTER_FACING_YAW=135.0")


if __name__ == "__main__":
    main()
