"""Build the rigged Steamtek_C002 production blockout from the approved master."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import bpy
from mathutils import Vector


CHARACTER_ID = "Steamtek_C002"


def arguments():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--concept", type=Path, required=True)
    parser.add_argument("--pipeline-scripts", type=Path, required=True)
    return parser.parse_args(argv)


def bone_center(rig, name):
    bone = rig.data.bones[name]
    return (bone.head_local + bone.tail_local) * 0.5


def main():
    args = arguments()
    scripts = args.pipeline_scripts.resolve()
    if str(scripts) not in sys.path:
        sys.path.insert(0, str(scripts))
    from Steamtek_Build_CalibrationDummy import (
        bind_object,
        create_idle,
        create_walk,
        cylinder_for_bone,
        cube_part,
        material,
        sphere_part,
    )

    rig = bpy.data.objects.get("Armature")
    facing_root = bpy.data.objects.get("ROOT_CharacterFacing")
    if rig is None or facing_root is None:
        raise RuntimeError("Open the approved Steamtek_Character_Master.blend first")
    if rig.get("steamtek_rig_status") != "approved":
        raise RuntimeError("Steamtek_C002 requires the approved Steamtek_HumanRig_v1")

    old = bpy.data.collections.get("COLLECTION_Steamtek_C002")
    if old:
        for obj in list(old.objects):
            bpy.data.objects.remove(obj, do_unlink=True)
        bpy.data.collections.remove(old)
    collection = bpy.data.collections.new("COLLECTION_Steamtek_C002")
    bpy.context.scene.collection.children.link(collection)

    suit = material("C002_TechnicalFabric", (0.032, 0.052, 0.070, 1.0), 0.08, 0.66)
    jacket = material("C002_ArmoredJacket", (0.075, 0.105, 0.125, 1.0), 0.28, 0.46)
    steel = material("C002_WornSteel", (0.13, 0.15, 0.17, 1.0), 0.78, 0.30)
    copper = material("C002_AgedCopper", (0.40, 0.12, 0.035, 1.0), 0.74, 0.28)
    rubber = material("C002_Rubber", (0.012, 0.016, 0.018, 1.0), 0.02, 0.82)
    orange = material("C002_SafetyOrange", (0.55, 0.16, 0.025, 1.0), 0.35, 0.38)
    cyan = material("C002_CyanDiagnostic", (0.015, 0.55, 0.78, 1.0), 0.42, 0.20)

    # Riggable base silhouette: fitted coveralls, reinforced boots, jacket sleeves.
    parts = [
        ("DEF-spine", 0.155, suit),
        ("DEF-spine.001", 0.18, suit),
        ("DEF-spine.002", 0.205, jacket),
        ("DEF-spine.003", 0.215, jacket),
        ("DEF-spine.004", 0.19, jacket),
        ("DEF-pelvis.L", 0.125, suit), ("DEF-pelvis.R", 0.125, suit),
        ("DEF-thigh.L", 0.10, suit), ("DEF-thigh.L.001", 0.095, suit),
        ("DEF-thigh.R", 0.10, suit), ("DEF-thigh.R.001", 0.095, suit),
        ("DEF-shin.L", 0.082, suit), ("DEF-shin.L.001", 0.078, suit),
        ("DEF-shin.R", 0.082, suit), ("DEF-shin.R.001", 0.078, suit),
        ("DEF-foot.L", 0.105, steel), ("DEF-toe.L", 0.11, steel),
        ("DEF-foot.R", 0.105, steel), ("DEF-toe.R", 0.11, steel),
        ("DEF-shoulder.L", 0.105, steel), ("DEF-shoulder.R", 0.105, steel),
        ("DEF-upper_arm.L", 0.086, jacket), ("DEF-upper_arm.L.001", 0.08, jacket),
        ("DEF-upper_arm.R", 0.086, jacket), ("DEF-upper_arm.R.001", 0.08, jacket),
        ("DEF-forearm.L", 0.09, copper), ("DEF-forearm.L.001", 0.086, copper),
        ("DEF-forearm.R", 0.066, suit), ("DEF-forearm.R.001", 0.062, suit),
        ("DEF-hand.L", 0.07, copper), ("DEF-hand.R", 0.067, rubber),
    ]
    for bone_name, radius, mat in parts:
        obj = cylinder_for_bone(rig, bone_name, radius, facing_root, collection, mat)
        obj.name = f"C002_{bone_name.replace('.', '_')}"
        obj["steamtek_character_id"] = CHARACTER_ID

    chest = bone_center(rig, "DEF-spine.003")
    abdomen = bone_center(rig, "DEF-spine.001")
    head = bone_center(rig, "DEF-spine.006") + Vector((0.0, -0.01, 0.035))
    forearm_l = bone_center(rig, "DEF-forearm.L")

    # Cropped jacket shell and visible safety closure.
    sphere_part("C002_JacketShell", rig, "DEF-spine.003", chest + Vector((0, 0.005, -0.015)),
                (0.255, 0.145, 0.215), facing_root, collection, jacket)
    cube_part("C002_ChestPlate", rig, "DEF-spine.003", chest + Vector((0, -0.145, 0.015)),
              (0.17, 0.022, 0.12), facing_root, collection, steel)
    cube_part("C002_SafetyClosure", rig, "DEF-spine.003", chest + Vector((0.0, -0.173, 0.005)),
              (0.018, 0.008, 0.105), facing_root, collection, orange)
    cube_part("C002_UtilityBelt", rig, "DEF-spine.001", abdomen + Vector((0, 0, -0.07)),
              (0.255, 0.14, 0.035), facing_root, collection, rubber)

    # Compact hard cap and respirator; face remains fully enclosed.
    sphere_part("C002_HeadShell", rig, "DEF-spine.006", head,
                (0.15, 0.135, 0.17), facing_root, collection, rubber)
    sphere_part("C002_HardCap", rig, "DEF-spine.006", head + Vector((0, -0.005, 0.105)),
                (0.158, 0.143, 0.105), facing_root, collection, steel)
    cube_part("C002_CapBrim", rig, "DEF-spine.006", head + Vector((0, -0.145, 0.095)),
              (0.13, 0.055, 0.018), facing_root, collection, steel)
    cube_part("C002_Respirator", rig, "DEF-spine.006", head + Vector((0, -0.135, -0.015)),
              (0.115, 0.035, 0.075), facing_root, collection, rubber)
    sphere_part("C002_Filter_L", rig, "DEF-spine.006", head + Vector((0.115, -0.145, -0.025)),
                (0.05, 0.035, 0.05), facing_root, collection, copper)
    sphere_part("C002_Filter_R", rig, "DEF-spine.006", head + Vector((-0.115, -0.145, -0.025)),
                (0.05, 0.035, 0.05), facing_root, collection, copper)
    cube_part("C002_Visor", rig, "DEF-spine.006", head + Vector((0, -0.14, 0.065)),
              (0.105, 0.018, 0.028), facing_root, collection, cyan)

    # Locked asymmetry: copper pressure gauntlet stays on physical left.
    cube_part("C002_GauntletHousing_L", rig, "DEF-forearm.L", forearm_l + Vector((0, -0.075, 0.01)),
              (0.095, 0.065, 0.145), facing_root, collection, copper)
    sphere_part("C002_GauntletGauge_L", rig, "DEF-forearm.L", forearm_l + Vector((0.0, -0.145, 0.04)),
                (0.06, 0.025, 0.06), facing_root, collection, steel)
    cube_part("C002_GaugeLight_L", rig, "DEF-forearm.L", forearm_l + Vector((0.0, -0.174, 0.04)),
              (0.028, 0.008, 0.014), facing_root, collection, cyan)

    # Right-hip diagnostic pack and wrench holster.
    cube_part("C002_DiagnosticUnit_R", rig, "DEF-spine.001", abdomen + Vector((-0.27, -0.04, -0.12)),
              (0.065, 0.04, 0.105), facing_root, collection, steel)
    for offset in (-0.04, 0.0, 0.04):
        cube_part(f"C002_DiagnosticLight_R_{offset:+.2f}", rig, "DEF-spine.001",
                  abdomen + Vector((-0.27, -0.085, -0.12 + offset)),
                  (0.018, 0.008, 0.012), facing_root, collection, cyan)
    cube_part("C002_WrenchHolster_R", rig, "DEF-spine.001", abdomen + Vector((-0.34, 0.015, -0.16)),
              (0.025, 0.035, 0.15), facing_root, collection, copper)

    # Back regulator pack, rigidly mounted to the torso.
    cube_part("C002_RegulatorPack", rig, "DEF-spine.003", chest + Vector((0, 0.205, 0.015)),
              (0.18, 0.075, 0.18), facing_root, collection, steel)
    for x in (-0.095, 0.095):
        sphere_part(f"C002_RegulatorTank_{x:+.2f}", rig, "DEF-spine.003", chest + Vector((x, 0.285, 0.025)),
                    (0.055, 0.055, 0.14), facing_root, collection, copper)
    cube_part("C002_BackWarning", rig, "DEF-spine.003", chest + Vector((0, 0.285, 0.01)),
              (0.035, 0.01, 0.08), facing_root, collection, orange)

    # Knee armor and boot diagnostics reinforce the work silhouette.
    for side, xsign in (("L", 1.0), ("R", -1.0)):
        knee = bone_center(rig, f"DEF-shin.{side}") + Vector((0, -0.085, 0.06))
        cube_part(f"C002_KneePad_{side}", rig, f"DEF-shin.{side}", knee,
                  (0.095, 0.035, 0.075), facing_root, collection, steel)
        foot = bone_center(rig, f"DEF-foot.{side}")
        cube_part(f"C002_BootLight_{side}", rig, f"DEF-foot.{side}", foot + Vector((0, -0.11, -0.02)),
                  (0.03, 0.012, 0.012), facing_root, collection, cyan)

    for obj in collection.objects:
        obj["steamtek_character_id"] = CHARACTER_ID
        obj["steamtek_production_stage"] = "rigged_blockout_v1"
        obj.hide_render = False
    collection["steamtek_character_id"] = CHARACTER_ID
    collection["steamtek_visual_contract"] = "Steamtek_C002_CharacterSpec.json"

    concept = args.concept.resolve()
    reference = bpy.data.objects.get("C002_ConceptReference")
    if reference is None:
        reference = bpy.data.objects.new("C002_ConceptReference", None)
        bpy.data.collections["COLLECTION_References"].objects.link(reference)
    reference["steamtek_concept_path"] = str(concept)
    reference["steamtek_concept_approved"] = True
    reference.hide_render = True

    create_idle(rig)
    walk = create_walk(rig)
    rig.animation_data.action = walk
    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = 8
    bpy.context.scene.frame_set(1)
    bpy.context.scene["steamtek_character_id"] = CHARACTER_ID
    bpy.context.scene["steamtek_character_status"] = "rigged_blockout_ready_for_direction_review"
    bpy.context.scene["steamtek_concept"] = str(concept)
    args.output.resolve().parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(args.output.resolve()), check_existing=False)
    print(f"STEAMTEK_C002_BLOCKOUT={args.output.resolve()}")
    print(f"STEAMTEK_C002_PARTS={len(collection.objects)}")
    print("STEAMTEK_C002_ACTIONS=STK_IDLE,STK_WALK")


if __name__ == "__main__":
    main()
