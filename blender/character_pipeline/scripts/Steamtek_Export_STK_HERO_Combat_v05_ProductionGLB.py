"""Export the visually reviewed Steamtek hero combat v05 rig as one GLB."""

import hashlib
import json
from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parents[3]
OUTPUT_DIR = (
    ROOT
    / "assets"
    / "characters"
    / "humanoid"
    / "base"
    / "STK_HERO_BaseBody_01"
    / "v01"
    / "rigged"
)
OUTPUT_GLB = OUTPUT_DIR / "STK_HERO_BaseBody_01_Rigged_Combat_v05.glb"
OUTPUT_REPORT = OUTPUT_GLB.with_suffix(".export.json")

ARMATURE_NAME = "STK_HERO_BaseBody_01_Armature"
BODY_NAME = "STK_HERO_BaseBody_01_RiggedBody"
ACTION_NAMES = {
    "STK_DEATH_FORWARD",
    "STK_HIT_REACT_STRONG",
    "STK_RIFLE_BUTTSTROKE",
    "STK_RIFLE_CROUCH_STRAFE_LEFT",
    "STK_RIFLE_CROUCH_STRAFE_RIGHT",
    "STK_RIFLE_FIRE",
    "STK_RIFLE_IDLE",
    "STK_RIFLE_RELOAD",
    "STK_RIFLE_TURN_LEFT",
    "STK_RIFLE_TURN_RIGHT",
    "STK_RUN",
    "STK_WALK",
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

armature = bpy.data.objects[ARMATURE_NAME]
body = bpy.data.objects[BODY_NAME]

for obj in list(bpy.data.objects):
    if obj not in (armature, body):
        bpy.data.objects.remove(obj, do_unlink=True)

for action in list(bpy.data.actions):
    if action.name not in ACTION_NAMES:
        bpy.data.actions.remove(action, do_unlink=True)

missing_actions = ACTION_NAMES.difference(bpy.data.actions.keys())
if missing_actions:
    raise RuntimeError(f"Missing target actions: {sorted(missing_actions)}")

if set(bpy.data.actions.keys()) != ACTION_NAMES:
    raise RuntimeError(
        f"Unexpected actions remain: {sorted(bpy.data.actions.keys())}"
    )

for action_name in ACTION_NAMES:
    bpy.data.actions[action_name].use_fake_user = True

idle = bpy.data.actions["STK_RIFLE_IDLE"]
armature.animation_data_create()
armature.animation_data.action = idle
armature.animation_data.action_slot = idle.slots[0]
armature.data.pose_position = "POSE"

armature.hide_set(False)
armature.hide_viewport = False
armature.hide_render = False
body.hide_set(False)
body.hide_viewport = False
body.hide_render = False

bpy.ops.object.select_all(action="DESELECT")
body.select_set(True)
armature.select_set(True)
bpy.context.view_layer.objects.active = armature

requested_options = {
    "filepath": str(OUTPUT_GLB),
    "export_format": "GLB",
    "use_selection": True,
    "export_apply": False,
    "export_yup": True,
    "export_materials": "EXPORT",
    "export_image_format": "AUTO",
    "export_cameras": False,
    "export_lights": False,
    "export_animations": True,
    "export_animation_mode": "ACTIONS",
    "export_anim_single_armature": True,
    "export_force_sampling": True,
    "export_frame_step": 1,
    "export_skins": True,
    "export_all_influences": False,
    "export_morph": False,
    "export_attributes": False,
    "export_extras": True,
}
supported = {
    prop.identifier for prop in bpy.ops.export_scene.gltf.get_rna_type().properties
}
export_options = {
    key: value for key, value in requested_options.items() if key in supported
}
bpy.ops.export_scene.gltf(**export_options)

if not OUTPUT_GLB.is_file():
    raise RuntimeError(f"GLB export was not created: {OUTPUT_GLB}")

report = {
    "schema": "SteamtekHeroCombatGLBExport-1",
    "status": "pass",
    "source_blend": bpy.data.filepath,
    "output_glb": str(OUTPUT_GLB),
    "sha256": sha256(OUTPUT_GLB),
    "bytes": OUTPUT_GLB.stat().st_size,
    "mesh": BODY_NAME,
    "armature": ARMATURE_NAME,
    "bones": len(armature.data.bones),
    "actions": sorted(ACTION_NAMES),
    "triangles": sum(
        max(0, len(polygon.vertices) - 2) for polygon in body.data.polygons
    ),
    "materials": [
        material.name for material in body.data.materials if material is not None
    ],
    "export_options": export_options,
}
OUTPUT_REPORT.write_text(json.dumps(report, indent=2), encoding="utf-8")

print(f"OUTPUT_GLB={OUTPUT_GLB}")
print(f"OUTPUT_REPORT={OUTPUT_REPORT}")
print(f"SHA256={report['sha256']}")
print(f"BYTES={report['bytes']}")
print(f"BONES={report['bones']}")
print(f"TRIANGLES={report['triangles']}")
print("ACTIONS=" + ",".join(report["actions"]))
