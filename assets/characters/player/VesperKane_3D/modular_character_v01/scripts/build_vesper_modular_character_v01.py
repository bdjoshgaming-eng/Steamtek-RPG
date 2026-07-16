"""Build Vesper's modular base body and convert the approved v1.1 outfit to slots."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import bpy
from mathutils import Vector


ARGV = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
PARSER = argparse.ArgumentParser()
PARSER.add_argument("--output", type=Path, required=True)
ARGS = PARSER.parse_args(ARGV)

SOURCE_HELPERS = Path(bpy.data.filepath).parent
if str(SOURCE_HELPERS) not in sys.path:
    sys.path.insert(0, str(SOURCE_HELPERS))

from build_vesper_production_mesh_v01 import (  # noqa: E402
    ensure_material,
    finalize_mesh,
    loft,
    tube,
    chain,
    shaped_ellipsoid,
    boot_mesh,
)


CHARACTER_ID = "Steamtek_C001_VesperKane"
CONTRACT = "vesper_modular_character_v01"
BASE_COLLECTION = "COLLECTION_VesperKane_ModularBase_v01"
OUTFIT_COLLECTION = "COLLECTION_VesperKane_DefaultOutfit_v01"


SLOT_RULES = {
    "headgear": (
        "HatBrim", "HatCrown", "HatBand", "Respirator", "Monocle", "ChinGuard"
    ),
    "outer_torso": (
        "CoatTorso", "CoatLapel", "CoatFront", "CoatBack", "HighCollar", "HumanSleeve"
    ),
    "shoulders": ("ShoulderCap_R",),
    "gloves": ("Glove_R", "GloveCuff_R", "GloveThumb_R"),
    "legs": ("UndersuitPelvis", "Trouser_"),
    "boots": ("Boot_", "AnkleSeal_"),
    "waist": ("WaistBelt", "BeltBuckle"),
    "hip_right": ("HipRig_R",),
}

PERMANENT_LEFT_ARM_TOKENS = (
    "MechanicalArm_L", "MechShoulderRing_L", "MechElbowRing_L", "MechWristRing_L",
    "PressureGauge_L", "PressureGaugeStatus_L", "ShoulderCap_L",
)


def new_collection(name):
    old = bpy.data.collections.get(name)
    if old:
        bpy.data.collections.remove(old)
    collection = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(collection)
    return collection


def move_to_collection(obj, collection):
    if collection.objects.get(obj.name) is None:
        collection.objects.link(obj)
    for owner in list(obj.users_collection):
        if owner != collection:
            owner.objects.unlink(obj)


def mark_base(obj, region):
    obj["steamtek_character_id"] = CHARACTER_ID
    obj["steamtek_modular_contract"] = CONTRACT
    obj["steamtek_body_region"] = region
    obj["steamtek_default_visible"] = True


def slot_for(name):
    for slot, tokens in SLOT_RULES.items():
        if any(token in name for token in tokens):
            return slot
    return None


def convert_existing_meshes(base_collection, outfit_collection):
    for obj in list(bpy.data.objects):
        if obj.type != "MESH" or not obj.name.startswith(("VK_PM01_", "VK_PM11_")):
            continue
        original = obj.name
        if original.endswith("Head"):
            obj.name = "VK_MB01_Head"
            mark_base(obj, "head")
            move_to_collection(obj, base_collection)
            continue
        if any(token in original for token in PERMANENT_LEFT_ARM_TOKENS):
            clean = original.replace("VK_PM01_", "").replace("VK_PM11_", "")
            obj.name = f"VK_MB01_{clean}"
            mark_base(obj, "mechanical_arm_l")
            move_to_collection(obj, base_collection)
            continue
        slot = slot_for(original)
        if slot is None:
            slot = "outer_torso"
        clean = original.replace("VK_PM01_", "").replace("VK_PM11_", "")
        obj.name = f"VK_SLOT_{slot.upper()}_{clean}"
        obj["steamtek_character_id"] = CHARACTER_ID
        obj["steamtek_modular_contract"] = CONTRACT
        obj["steamtek_equipment_slot"] = slot
        obj["steamtek_outfit_id"] = "vesper_default_outfit_v01"
        move_to_collection(obj, outfit_collection)


def build_base_body(rig, root, collection):
    undersuit = ensure_material("VK_MB01_Undersuit", (0.055, 0.064, 0.072), 0.04, 0.72)
    undersuit_dark = ensure_material("VK_MB01_UndersuitDark", (0.022, 0.027, 0.032), 0.02, 0.78)
    seal = ensure_material("VK_MB01_SealRubber", (0.012, 0.016, 0.019), 0.0, 0.84)
    skin = bpy.data.materials.get("VK_PM01_Skin") or ensure_material("VK_MB01_Skin", (0.30, 0.135, 0.072), 0.0, 0.58)

    parts = []

    # Seamless fitted torso. Its restrained volume is designed to sit beneath garments.
    obj, weights = loft("VK_MB01_Torso", [
        (0.98, 0.145, 0.086, 0.020, {"DEF-spine": 0.8, "DEF-spine.001": 0.2}),
        (1.13, 0.166, 0.096, 0.015, {"DEF-spine.001": 0.8, "DEF-spine.002": 0.2}),
        (1.34, 0.194, 0.105, 0.008, {"DEF-spine.002": 0.65, "DEF-spine.003": 0.35}),
        (1.53, 0.213, 0.112, 0.002, {"DEF-spine.003": 0.60, "DEF-spine.004": 0.40}),
        (1.65, 0.142, 0.090, -0.004, {"DEF-spine.004": 0.55, "DEF-spine.005": 0.45}),
    ], segments=24)
    finalize_mesh(obj, rig, root, collection, undersuit, weights, bevel=0.003, subdiv=1)
    mark_base(obj, "torso"); parts.append(obj)

    obj, weights = loft("VK_MB01_Pelvis", [
        (0.88, 0.145, 0.090, 0.025, {"DEF-pelvis.L": 0.45, "DEF-pelvis.R": 0.45, "DEF-spine": 0.10}),
        (1.00, 0.165, 0.098, 0.022, {"DEF-spine": 0.70, "DEF-pelvis.L": 0.15, "DEF-pelvis.R": 0.15}),
        (1.10, 0.158, 0.094, 0.018, {"DEF-spine.001": 1.0}),
    ], segments=22)
    finalize_mesh(obj, rig, root, collection, undersuit_dark, weights, bevel=0.003, subdiv=1)
    mark_base(obj, "pelvis"); parts.append(obj)

    # Neck seal bridges the head and torso without a visible seam.
    neck_center = (rig.data.bones["DEF-spine.005"].tail_local + rig.data.bones["DEF-spine.006"].head_local) * 0.5
    obj, weights = shaped_ellipsoid("VK_MB01_Neck", neck_center, (0.082, 0.072, 0.110), "DEF-spine.005")
    finalize_mesh(obj, rig, root, collection, skin, weights, bevel=0.001, subdiv=1)
    mark_base(obj, "neck"); parts.append(obj)

    # Physical-right human arm, split into maskable garment regions.
    arm_specs = [
        ("UpperArm_R", ["DEF-upper_arm.R", "DEF-upper_arm.R.001"], [(0.079, 0.073), (0.075, 0.069), (0.064, 0.059)], "upper_arm_r"),
        ("Forearm_R", ["DEF-forearm.R", "DEF-forearm.R.001"], [(0.064, 0.059), (0.058, 0.053), (0.050, 0.046)], "forearm_r"),
    ]
    for label, bones, radii, region in arm_specs:
        points, maps = chain(rig, bones)
        obj, weights = tube(f"VK_MB01_{label}", points, radii, maps, segments=16)
        finalize_mesh(obj, rig, root, collection, undersuit, weights, bevel=0.002, subdiv=1)
        mark_base(obj, region); parts.append(obj)
    hand_center = (rig.data.bones["DEF-hand.R"].head_local + rig.data.bones["DEF-hand.R"].tail_local) * 0.5
    obj, weights = shaped_ellipsoid("VK_MB01_Hand_R", hand_center + Vector((0, -0.010, -0.008)), (0.058, 0.045, 0.074), "DEF-hand.R", front_taper=0.14)
    finalize_mesh(obj, rig, root, collection, skin, weights, bevel=0.001, subdiv=1)
    mark_base(obj, "hand_r"); parts.append(obj)

    # Legs are separate hideable regions, with overlapping seals to eliminate gaps in motion.
    for side in ("L", "R"):
        for label, bones, radii, region in (
            ("Thigh", [f"DEF-thigh.{side}", f"DEF-thigh.{side}.001"], [(0.081, 0.073), (0.084, 0.075), (0.067, 0.061)], f"thigh_{side.lower()}"),
            ("Shin", [f"DEF-shin.{side}", f"DEF-shin.{side}.001"], [(0.067, 0.061), (0.060, 0.055), (0.050, 0.046)], f"shin_{side.lower()}"),
        ):
            points, maps = chain(rig, bones)
            obj, weights = tube(f"VK_MB01_{label}_{side}", points, radii, maps, segments=16)
            finalize_mesh(obj, rig, root, collection, undersuit, weights, bevel=0.002, subdiv=1)
            mark_base(obj, region); parts.append(obj)
        x = 0.098 if side == "L" else -0.098
        obj, weights = boot_mesh(f"VK_MB01_Foot_{side}", x, f"DEF-foot.{side}")
        # Base foot is a slim neutral liner rather than finished footwear.
        for vertex in obj.data.vertices:
            vertex.co.x = x + (vertex.co.x - x) * 0.72
            vertex.co.y *= 0.78
            vertex.co.z *= 0.70
        finalize_mesh(obj, rig, root, collection, seal, weights, bevel=0.010, subdiv=1)
        mark_base(obj, f"foot_{side.lower()}"); parts.append(obj)

    return parts


def main():
    rig = bpy.data.objects.get("Armature")
    root = bpy.data.objects.get("ROOT_CharacterFacing")
    if not rig or not root:
        raise RuntimeError("Locked Vesper rig roots were not found")

    base_collection = new_collection(BASE_COLLECTION)
    outfit_collection = new_collection(OUTFIT_COLLECTION)
    convert_existing_meshes(base_collection, outfit_collection)
    body_parts = build_base_body(rig, root, base_collection)

    base_collection["steamtek_modular_contract"] = CONTRACT
    base_collection["steamtek_skeleton_changed"] = False
    base_collection["steamtek_animation_changed"] = False
    base_collection["steamtek_scale_changed"] = False
    base_collection["steamtek_runtime_lighting_only"] = True
    outfit_collection["steamtek_equipment_set"] = "vesper_default_outfit_v01"
    outfit_collection["steamtek_modular_contract"] = CONTRACT
    bpy.context.scene["steamtek_character_status"] = "modular_body_and_default_outfit_v01"
    bpy.context.scene.frame_set(1)

    ARGS.output.resolve().parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(ARGS.output.resolve()), check_existing=False)
    print(f"VESPER_MODULAR_BLEND={ARGS.output.resolve()}")
    print(f"VESPER_MODULAR_BODY_PARTS={len(body_parts)}")
    print(f"VESPER_MODULAR_OUTFIT_PARTS={len(outfit_collection.objects)}")
    print(f"VESPER_MODULAR_BONES={len(rig.data.bones)}")


if __name__ == "__main__":
    main()

