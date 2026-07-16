"""Export Vesper Production Appearance v1 with embedded PBR textures."""

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

pbr_images = sorted(image.name for image in bpy.data.images if image.name.startswith("VK_") and image.get("steamtek_pbr_map"))
manifest = {
    "source_blend": bpy.data.filepath,
    "output_glb": str(output),
    "character_id": "Steamtek_C001_VesperKane",
    "stage": "production_appearance_v01_pbr_review",
    "mesh_count": len([obj for obj in selected if obj.type == "MESH"]),
    "vertex_count": sum(len(obj.data.vertices) for obj in selected if obj.type == "MESH"),
    "bone_count": len(rig.data.bones),
    "pbr_texture_count": len(pbr_images),
    "pbr_textures": pbr_images,
    "mechanical_arm_side": "physical_left",
    "baked_environment_color": False,
    "skeleton_changed": False,
    "animation_changed": False,
    "scale_changed": False,
    "actions": [
        {"name": action.name, "frame_start": action.frame_range[0], "frame_end": action.frame_range[1]}
        for action in bpy.data.actions if action.name in {"STK_IDLE", "STK_WALK"}
    ],
    "export_kwargs": kwargs,
}
with output.with_suffix(".export.json").open("w", encoding="utf-8") as handle:
    json.dump(manifest, handle, indent=2)

print(f"VESPER_APPEARANCE_GLB={output}")
print(f"VESPER_APPEARANCE_MESHES={manifest['mesh_count']}")
print(f"VESPER_APPEARANCE_TEXTURES={manifest['pbr_texture_count']}")
print(f"VESPER_APPEARANCE_BONES={manifest['bone_count']}")

