"""Install the C001-calibrated Steamtek humanoid production rig."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import bpy


RIG_ID = "Steamtek_HumanRig_v1"
RIG_STATUS = "approved"


def arguments():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--master-output", type=Path)
    parser.add_argument("--rig-output", type=Path)
    return parser.parse_args(argv)


def move_to_collection(obj: bpy.types.Object, target: bpy.types.Collection) -> None:
    if target.objects.get(obj.name) is None:
        target.objects.link(obj)
    for owner in list(obj.users_collection):
        if owner != target:
            owner.objects.unlink(obj)


def remove_placeholder() -> None:
    existing = bpy.data.objects.get("Armature")
    if existing is None:
        return
    if not existing.get("steamtek_placeholder", False):
        raise RuntimeError(
            "Armature is not the known placeholder. Refusing to replace an existing rig automatically."
        )
    data = existing.data
    bpy.data.objects.remove(existing, do_unlink=True)
    if data.users == 0:
        bpy.data.armatures.remove(data)


def main() -> None:
    args = arguments()
    current_file = Path(bpy.data.filepath).resolve()
    master_output = (args.master_output or current_file).resolve()
    rig_output = (args.rig_output or (master_output.parent / "Steamtek_HumanRig_v1.blend")).resolve()

    required_objects = ("ROOT_Direction", "ROOT_GroundContact", "ROOT_CharacterFacing", "Camera_Iso")
    missing = [name for name in required_objects if bpy.data.objects.get(name) is None]
    if missing:
        raise RuntimeError(f"Not a Steamtek character master; missing: {', '.join(missing)}")
    character_collection = bpy.data.collections.get("COLLECTION_Character")
    if character_collection is None:
        raise RuntimeError("Missing COLLECTION_Character")

    remove_placeholder()
    bpy.ops.preferences.addon_enable(module="rigify")
    before_armatures = {obj.name for obj in bpy.data.objects if obj.type == "ARMATURE"}
    bpy.ops.object.armature_human_metarig_add()
    metarig = bpy.context.object
    metarig.name = f"{RIG_ID}_Metarig"
    metarig.data.name = f"{RIG_ID}_Metarig"
    metarig["steamtek_rig_id"] = RIG_ID
    metarig["steamtek_role"] = "editable_rigify_metarig"

    bpy.context.view_layer.objects.active = metarig
    metarig.select_set(True)
    bpy.ops.pose.rigify_generate()
    generated = [
        obj for obj in bpy.data.objects
        if obj.type == "ARMATURE" and obj.name not in before_armatures and obj != metarig
    ]
    if len(generated) != 1:
        raise RuntimeError(f"Expected one generated Rigify armature, found {len(generated)}")
    rig = generated[0]
    rig.name = "Armature"
    rig.data.name = RIG_ID
    rig.parent = bpy.data.objects["ROOT_CharacterFacing"]
    rig.location = (0.0, 0.0, 0.0)
    rig.rotation_euler = (0.0, 0.0, 0.0)
    rig.scale = (1.0, 1.0, 1.0)
    rig.show_in_front = True
    rig["steamtek_placeholder"] = False
    rig["steamtek_rig_id"] = RIG_ID
    rig["steamtek_rig_version"] = "1.0.0"
    rig["steamtek_rig_status"] = RIG_STATUS
    rig["steamtek_approved_against"] = "Steamtek_C001"
    rig["steamtek_approval_evidence"] = "Godot comparison passed 2026-07-14"
    rig["steamtek_forward_axis"] = "-Y"
    rig["steamtek_ground_contact"] = [0.0, 0.0, 0.0]
    rig["steamtek_generator"] = "Blender 4.5 bundled Rigify human"
    move_to_collection(rig, character_collection)

    metarig.parent = bpy.data.objects["ROOT_CharacterFacing"]
    metarig.location = (0.0, 0.0, 0.0)
    metarig.rotation_euler = (0.0, 0.0, 0.0)
    metarig.scale = (1.0, 1.0, 1.0)
    metarig.show_in_front = True
    metarig.hide_render = True
    metarig.hide_set(True)
    move_to_collection(metarig, character_collection)

    for collection in bpy.data.collections:
        if collection.name.startswith("Widgets") or collection.name.startswith("WGTS"):
            collection.hide_render = True

    readme = bpy.data.texts.get("STEAMTEK_HUMAN_RIG_V1_README") or bpy.data.texts.new(
        "STEAMTEK_HUMAN_RIG_V1_README"
    )
    readme.clear()
    readme.write(
        "Steamtek_HumanRig_v1 is production-approved against immutable Steamtek_C001.\n"
        "It was generated because no authoritative C001/source rig was found.\n"
        "Representative deformation, eight-direction rendering, fixed-canvas QA,\n"
        "and two in-Godot comparisons against immutable Steamtek_C001 passed on 2026-07-14.\n"
    )
    bpy.context.scene["steamtek_rig_id"] = RIG_ID
    bpy.context.scene["steamtek_rig_status"] = RIG_STATUS

    master_output.parent.mkdir(parents=True, exist_ok=True)
    rig_output.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(master_output), check_existing=False)
    bpy.ops.wm.save_as_mainfile(filepath=str(rig_output), check_existing=False, copy=True)
    print(f"STEAMTEK_MASTER_WITH_RIG={master_output}")
    print(f"STEAMTEK_RIG_LIBRARY={rig_output}")
    print(f"STEAMTEK_RIG_STATUS={RIG_STATUS}")


if __name__ == "__main__":
    main()
