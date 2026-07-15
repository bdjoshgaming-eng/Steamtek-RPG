"""Validate a Blender scene against the locked Steamtek character contract."""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


def arguments():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--production", action="store_true")
    return parser.parse_args(argv)


def validate(manifest: dict, production: bool = False) -> tuple[list[str], list[str]]:
    scene = bpy.context.scene
    failures: list[str] = []
    warnings: list[str] = []
    contract = manifest["scene_contract"]
    render = manifest["render"]

    for name in contract["required_collections"]:
        if bpy.data.collections.get(name) is None:
            failures.append(f"missing collection: {name}")
    for key in ("direction_root", "ground_contact_root", "character_facing_root", "armature", "camera"):
        name = contract[key]
        if bpy.data.objects.get(name) is None:
            failures.append(f"missing object: {name}")

    if (scene.render.resolution_x, scene.render.resolution_y) != (render["width"], render["height"]):
        failures.append("render canvas is not 1254 x 1254")
    if scene.render.resolution_percentage != 100:
        failures.append("render resolution percentage is not 100")
    if scene.render.image_settings.file_format != "PNG" or scene.render.image_settings.color_mode != "RGBA":
        failures.append("render output must be PNG RGBA")
    if not scene.render.film_transparent:
        failures.append("transparent film is disabled")

    camera = bpy.data.objects.get(contract["camera"])
    if camera:
        if camera.type != "CAMERA" or camera.data.type != "ORTHO":
            failures.append("Camera_Iso is not orthographic")
        if not math.isclose(camera.data.ortho_scale, manifest["camera"]["ortho_scale"], abs_tol=1e-6):
            failures.append("Camera_Iso orthographic scale drifted")
        target = Vector(manifest["camera"]["target"])
        view = (target - camera.location).normalized()
        elevation = math.degrees(math.asin(-view.z))
        expected = manifest["camera"]["elevation_degrees"]
        if not math.isclose(elevation, expected, abs_tol=1e-5):
            failures.append(f"Camera_Iso elevation drifted: {elevation:.8f} != {expected:.8f}")

    for name in (contract["direction_root"], contract["ground_contact_root"]):
        obj = bpy.data.objects.get(name)
        if obj and obj.location.length > 1e-7:
            failures.append(f"{name} moved away from world origin")
        if obj and any(abs(value - 1.0) > 1e-7 for value in obj.scale):
            failures.append(f"{name} scale is not 1")

    facing_root = bpy.data.objects.get(contract["character_facing_root"])
    if facing_root:
        expected_yaw = math.radians(manifest["model"]["south_facing_yaw_offset_degrees"])
        if facing_root.location.length > 1e-7:
            failures.append("ROOT_CharacterFacing moved away from its parent origin")
        if any(abs(value - 1.0) > 1e-7 for value in facing_root.scale):
            failures.append("ROOT_CharacterFacing scale is not 1")
        if not math.isclose(facing_root.rotation_euler.z, expected_yaw, abs_tol=1e-7):
            failures.append("ROOT_CharacterFacing yaw drifted")

    armature = bpy.data.objects.get(contract["armature"])
    if armature:
        if armature.type != "ARMATURE":
            failures.append("Armature object is not an armature")
        if armature.get("steamtek_placeholder", False):
            message = "Armature is the uncalibrated placeholder; install the approved humanoid rig"
            (failures if production else warnings).append(message)
        if production and armature.type == "ARMATURE" and len(armature.data.bones) == 0:
            failures.append("Armature has no bones; a calibrated production rig is required")
        required_status = contract.get("required_rig_status", "approved")
        actual_status = armature.get("steamtek_rig_status", "unclassified")
        if production and actual_status != required_status:
            failures.append(
                f"Armature status is {actual_status!r}; production requires {required_status!r}"
            )

    return failures, warnings


def main() -> None:
    args = arguments()
    manifest = json.loads(args.manifest.resolve().read_text(encoding="utf-8"))
    failures, warnings = validate(manifest, args.production)
    for warning in warnings:
        print(f"WARNING: {warning}")
    if failures:
        raise RuntimeError("STEAMTEK SCENE VALIDATION FAILED\n" + "\n".join(failures))
    print("STEAMTEK SCENE VALIDATION PASSED")


if __name__ == "__main__":
    main()
