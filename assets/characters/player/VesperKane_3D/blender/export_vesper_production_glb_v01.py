"""Export Vesper Production Mesh v1 and its proven animation library."""

import json
import sys
from pathlib import Path

import bpy


output = Path(sys.argv[-1]).resolve()
output.parent.mkdir(parents=True, exist_ok=True)

for obj in bpy.context.selected_objects:
    obj.select_set(False)

root_names = {"Armature", "ROOT_CharacterFacing", "ROOT_GroundContact", "ROOT_Direction"}
selected = []
for obj in bpy.data.objects:
    if obj.name.startswith("VK_PM01_") or obj.name in root_names:
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

manifest = {
    "source_blend": bpy.data.filepath,
    "output_glb": str(output),
    "character_id": "Steamtek_C001_VesperKane",
    "stage": "production_mesh_v01_geometry_and_weights",
    "mesh_count": len([obj for obj in selected if obj.type == "MESH"]),
    "vertex_count": sum(len(obj.data.vertices) for obj in selected if obj.type == "MESH"),
    "bone_count": len(rig.data.bones),
    "mechanical_arm_side": "physical_left",
    "uv_ready": True,
    "runtime_lighting_only": True,
    "actions": [
        {"name": action.name, "frame_start": action.frame_range[0], "frame_end": action.frame_range[1]}
        for action in bpy.data.actions if action.name in {"STK_IDLE", "STK_WALK"}
    ],
    "export_kwargs": kwargs,
}
with output.with_suffix(".export.json").open("w", encoding="utf-8") as handle:
    json.dump(manifest, handle, indent=2)

print(f"VESPER_PRODUCTION_GLB={output}")
print(f"VESPER_PRODUCTION_MESHES={manifest['mesh_count']}")
print(f"VESPER_PRODUCTION_VERTICES={manifest['vertex_count']}")
print(f"VESPER_PRODUCTION_BONES={manifest['bone_count']}")

