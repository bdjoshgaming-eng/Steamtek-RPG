"""Export a one-material STK_HERO_BaseBody_01 GLB for Meshy rigging.

The Godot production master keeps a dedicated matte-black hair material.
Meshy's Keep Original Texture and UV path expects one merged material and
one UV map, so this derivative assigns all faces back to the baked body
material without changing geometry, UVs, scale, or pose.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

import bpy


ASSET_ID = "STK_HERO_BaseBody_01"
PROJECT_ROOT = Path(__file__).resolve().parents[3]
OUTPUT = (
    PROJECT_ROOT
    / "output"
    / "meshy_upload"
    / f"{ASSET_ID}_MeshyUpload.glb"
)
REPORT = OUTPUT.with_suffix(".json")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
if len(meshes) != 1:
    raise RuntimeError(f"Expected one hero mesh; found {len(meshes)}")
body = meshes[0]
if len(body.data.uv_layers) != 1:
    raise RuntimeError(f"Expected one UV map; found {len(body.data.uv_layers)}")
if len(body.data.materials) < 1 or body.data.materials[0] is None:
    raise RuntimeError("Hero body material is missing")

for polygon in body.data.polygons:
    polygon.material_index = 0
while len(body.data.materials) > 1:
    body.data.materials.pop(index=1)
body.data.materials[0].name = "STK_MAT_HERO_BaseBody_01_MeshyUpload"
body.data.update()

roots = [obj for obj in bpy.context.scene.objects if obj.parent is None]
hero_root = next((obj for obj in roots if obj.name == ASSET_ID), None)
if hero_root is None:
    raise RuntimeError(f"Could not find root {ASSET_ID}")

OUTPUT.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action="DESELECT")
hero_root.select_set(True)
body.select_set(True)
bpy.context.view_layer.objects.active = body
bpy.ops.export_scene.gltf(
    filepath=str(OUTPUT),
    export_format="GLB",
    use_selection=True,
    export_animations=False,
    export_skins=False,
    export_morph=False,
    export_yup=True,
    export_apply=False,
    export_extras=True,
)

body.data.calc_loop_triangles()
report = {
    "asset_id": ASSET_ID,
    "purpose": "Meshy rigging upload with Keep Original Texture and UV",
    "output": str(OUTPUT),
    "bytes": OUTPUT.stat().st_size,
    "sha256": sha256(OUTPUT),
    "mesh_objects": 1,
    "materials": len(body.data.materials),
    "uv_layers": len(body.data.uv_layers),
    "triangles": len(body.data.loop_triangles),
    "geometry_changed": False,
    "production_master_changed": False,
}
REPORT.write_text(json.dumps(report, indent=2), encoding="utf-8")
print("STEAMTEK_MESHY_UPLOAD=" + json.dumps(report))
