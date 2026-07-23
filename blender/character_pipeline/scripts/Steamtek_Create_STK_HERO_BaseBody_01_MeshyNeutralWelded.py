"""Create a welded, uniformly textured Meshy auto-rigging diagnostic GLB."""

from __future__ import annotations

import hashlib
from pathlib import Path

import bmesh
import bpy


ROOT = Path(__file__).resolve().parents[3]
SOURCE = (
    ROOT
    / "output"
    / "meshy_rig_input"
    / "STK_HERO_BaseBody_01_MeshyRigInput_Neutral.glb"
)
OUTPUT = (
    ROOT
    / "output"
    / "meshy_rig_input"
    / "STK_HERO_BaseBody_01_MeshyRigInput_NeutralWeldedTextured.glb"
)
EXPECTED_TRIANGLES = 31_138
EXPECTED_WELDED_VERTICES = 15_569
WELD_DISTANCE = 1.0e-6


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def mesh_stats(obj: bpy.types.Object) -> dict[str, int | float]:
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    stats: dict[str, int | float] = {
        "vertices": len(bm.verts),
        "edges": len(bm.edges),
        "triangles": len(bm.faces),
        "boundary_edges": sum(1 for edge in bm.edges if len(edge.link_faces) == 1),
        "overfull_edges": sum(1 for edge in bm.edges if len(edge.link_faces) > 2),
        "wire_edges": sum(1 for edge in bm.edges if len(edge.link_faces) == 0),
        "degenerate_faces": sum(
            1 for face in bm.faces if face.calc_area() <= 1.0e-12
        ),
        "non_triangles": sum(1 for face in bm.faces if len(face.verts) != 3),
        "signed_volume": bm.calc_volume(signed=True),
    }
    bm.free()
    return stats


def require_clean(stats: dict[str, int | float], stage: str) -> None:
    if stats["vertices"] != EXPECTED_WELDED_VERTICES:
        raise RuntimeError(
            f"{stage}: expected {EXPECTED_WELDED_VERTICES} vertices, "
            f"found {stats['vertices']}"
        )
    if stats["triangles"] != EXPECTED_TRIANGLES:
        raise RuntimeError(
            f"{stage}: expected {EXPECTED_TRIANGLES} triangles, "
            f"found {stats['triangles']}"
        )
    for key in (
        "boundary_edges",
        "overfull_edges",
        "wire_edges",
        "degenerate_faces",
        "non_triangles",
    ):
        if stats[key] != 0:
            raise RuntimeError(f"{stage}: {key}={stats[key]}")
    if stats["signed_volume"] >= 0:
        raise RuntimeError(
            f"{stage}: expected outward negative signed volume, "
            f"found {stats['signed_volume']}"
        )


def build() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(SOURCE))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if len(meshes) != 1:
        raise RuntimeError(f"Expected one input mesh, found {len(meshes)}")
    body = meshes[0]

    bm = bmesh.new()
    bm.from_mesh(body.data)
    bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=WELD_DISTANCE)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    if bm.calc_volume(signed=True) > 0:
        bmesh.ops.reverse_faces(bm, faces=list(bm.faces))
    bm.to_mesh(body.data)
    bm.free()
    body.data.update()

    # All corners share one UV coordinate, so glTF can retain a single welded
    # vertex for every geometric position while still carrying a real texture.
    while body.data.uv_layers:
        body.data.uv_layers.remove(body.data.uv_layers[0])
    uv_layer = body.data.uv_layers.new(name="UVMap")
    for uv_loop in uv_layer.data:
        uv_loop.uv = (0.5, 0.5)
    while body.data.color_attributes:
        body.data.color_attributes.remove(body.data.color_attributes[0])
    for attribute_name in ("custom_normal", "sharp_face"):
        attribute = body.data.attributes.get(attribute_name)
        if attribute is not None:
            body.data.attributes.remove(attribute)
    for polygon in body.data.polygons:
        polygon.use_smooth = True

    body.name = "STK_HERO_BaseBody_01_MeshyRigInput_NeutralWeldedTextured"
    body.data.name = f"{body.name}_Mesh"
    body.data.materials.clear()
    material = bpy.data.materials.new(
        "STK_MAT_HERO_MeshyRigNeutralWeldedTextured"
    )
    material.use_nodes = True
    material.use_backface_culling = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    principled = material.node_tree.nodes.get("Principled BSDF")
    principled.inputs["Metallic"].default_value = 0.0
    principled.inputs["Roughness"].default_value = 0.8
    principled.inputs["Alpha"].default_value = 1.0
    image = bpy.data.images.new(
        "STK_HERO_MeshyRigNeutral_UniformGray",
        width=256,
        height=256,
        alpha=True,
    )
    image.generated_color = (0.6, 0.6, 0.6, 1.0)
    image.pack()
    texture = nodes.new("ShaderNodeTexImage")
    texture.name = "STK_HERO_UniformGray"
    texture.image = image
    links.new(texture.outputs["Color"], principled.inputs["Base Color"])
    body.data.materials.append(material)
    for polygon in body.data.polygons:
        polygon.material_index = 0

    body["steamtek_purpose"] = (
        "Seam-welded uniformly textured Meshy rig diagnostic"
    )
    body["steamtek_source"] = SOURCE.name
    body["steamtek_source_sha256"] = file_sha256(SOURCE)
    body["steamtek_weld_distance"] = WELD_DISTANCE

    require_clean(mesh_stats(body), "Pre-export")

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
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
        export_normals=True,
        export_tangents=False,
        export_texcoords=True,
    )


def validate() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(OUTPUT))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if len(meshes) != 1:
        raise RuntimeError(f"Reimport found {len(meshes)} meshes")
    body = meshes[0]
    stats = mesh_stats(body)
    require_clean(stats, "Reimport")

    materials = [item for item in body.data.materials if item is not None]
    if len(materials) != 1:
        raise RuntimeError(f"Reimport found {len(materials)} materials")
    if len(body.data.uv_layers) != 1:
        raise RuntimeError(
            f"Reimport found {len(body.data.uv_layers)} UV layers"
        )
    images = [image for image in bpy.data.images if image.size[0] > 0]
    if len(images) != 1 or tuple(images[0].size) != (256, 256):
        raise RuntimeError(
            "Reimport did not recover exactly one embedded 256 texture"
        )
    if bpy.data.actions:
        raise RuntimeError(f"Reimport found {len(bpy.data.actions)} animations")
    if any(obj.type == "ARMATURE" for obj in bpy.context.scene.objects):
        raise RuntimeError("Reimport found an armature")
    if tuple(round(value, 6) for value in body.scale) != (1.0, 1.0, 1.0):
        raise RuntimeError(f"Unexpected root scale: {tuple(body.scale)}")

    print(f"OUTPUT={OUTPUT}")
    print(f"OUTPUT_SHA256={file_sha256(OUTPUT)}")
    for key, value in stats.items():
        print(f"{key.upper()}={value}")
    print(f"MATERIAL={materials[0].name}")
    print(f"IMAGE={images[0].name}")
    print(f"IMAGE_SIZE={tuple(images[0].size)}")
    print("UV_LAYERS=1")
    print("ARMATURES=0")
    print("ANIMATIONS=0")
    print("STATUS=PASSED")


build()
validate()
