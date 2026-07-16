"""Export the versioned Vesper modular body/default outfit GLB and manifest."""

import json
import sys
from pathlib import Path

import bpy


output = Path(sys.argv[-1]).resolve()
output.parent.mkdir(parents=True, exist_ok=True)
for obj in bpy.context.selected_objects:
    obj.select_set(False)

roots = {"Armature", "ROOT_CharacterFacing", "ROOT_GroundContact", "ROOT_Direction"}
selected = []
for obj in bpy.data.objects:
    if obj.name.startswith(("VK_MB01_", "VK_SLOT_")) or obj.name in roots:
        obj.hide_set(False)
        obj.hide_render = False
        obj.select_set(True)
        selected.append(obj)

rig = bpy.data.objects["Armature"]
bpy.context.view_layer.objects.active = rig
kwargs = {
    "filepath": str(output),
    "export_format": "GLB",
    "use_selection": True,
    "export_animations": True,
    "export_skins": True,
    "export_morph": True,
    "export_yup": True,
    "export_apply": False,
    "export_animation_mode": "ACTIONS",
}
bpy.ops.export_scene.gltf(**kwargs)

body = [obj for obj in selected if obj.type == "MESH" and obj.name.startswith("VK_MB01_")]
outfit = [obj for obj in selected if obj.type == "MESH" and obj.name.startswith("VK_SLOT_")]
manifest = {
    "character_id": "Steamtek_C001_VesperKane",
    "contract": "vesper_modular_character_v01",
    "source_blend": Path(bpy.data.filepath).name,
    "output_glb": output.name,
    "bone_count": len(rig.data.bones),
    "body_mesh_count": len(body),
    "outfit_mesh_count": len(outfit),
    "body_regions": sorted({obj.get("steamtek_body_region", "") for obj in body}),
    "equipment_slots": sorted({obj.get("steamtek_equipment_slot", "") for obj in outfit}),
    "mechanical_arm_side": "physical_left",
    "skeleton_changed": False,
    "animation_changed": False,
    "scale_changed": False,
    "runtime_lighting_only": True,
    "actions": [
        {"name": action.name, "frame_start": action.frame_range[0], "frame_end": action.frame_range[1]}
        for action in bpy.data.actions if action.name in {"STK_IDLE", "STK_WALK"}
    ],
}
with output.with_suffix(".export.json").open("w", encoding="utf-8") as handle:
    json.dump(manifest, handle, indent=2)

print(f"VESPER_MODULAR_GLB={output}")
print(f"VESPER_MODULAR_BODY_MESHES={len(body)}")
print(f"VESPER_MODULAR_OUTFIT_MESHES={len(outfit)}")
print(f"VESPER_MODULAR_BONES={len(rig.data.bones)}")
