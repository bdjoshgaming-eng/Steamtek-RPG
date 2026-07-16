"""Export Vesper Production Mesh v1.1 and the locked Steamtek animation library."""

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
    if obj.name.startswith(("VK_PM01_", "VK_PM11_")) or obj.name in roots:
        obj.hide_set(False)
        obj.hide_render = False
        obj.select_set(True)
        selected.append(obj)

rig = bpy.data.objects["Armature"]
bpy.context.view_layer.objects.active = rig
kwargs = {
    "filepath": str(output), "export_format": "GLB", "use_selection": True,
    "export_animations": True, "export_skins": True, "export_morph": True,
    "export_yup": True, "export_apply": False, "export_animation_mode": "ACTIONS",
}
bpy.ops.export_scene.gltf(**kwargs)

manifest = {
    "source_blend": bpy.data.filepath,
    "output_glb": str(output),
    "character_id": "Steamtek_C001_VesperKane",
    "stage": "production_mesh_v11_silhouette_approval",
    "mesh_count": len([obj for obj in selected if obj.type == "MESH"]),
    "vertex_count": sum(len(obj.data.vertices) for obj in selected if obj.type == "MESH"),
    "bone_count": len(rig.data.bones),
    "mechanical_arm_side": "physical_left",
    "skeleton_changed": False,
    "animation_changed": False,
    "scale_changed": False,
    "uv_ready": True,
    "actions": [
        {"name": action.name, "frame_start": action.frame_range[0], "frame_end": action.frame_range[1]}
        for action in bpy.data.actions if action.name in {"STK_IDLE", "STK_WALK"}
    ],
    "export_kwargs": kwargs,
}
with output.with_suffix(".export.json").open("w", encoding="utf-8") as handle:
    json.dump(manifest, handle, indent=2)

print(f"VESPER_PRODUCTION_V11_GLB={output}")
print(f"VESPER_PRODUCTION_V11_MESHES={manifest['mesh_count']}")
print(f"VESPER_PRODUCTION_V11_VERTICES={manifest['vertex_count']}")
print(f"VESPER_PRODUCTION_V11_BONES={manifest['bone_count']}")

