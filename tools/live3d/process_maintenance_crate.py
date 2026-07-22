"""Normalize the Maintenance Supply Crate without changing its topology.

Run with Blender in background mode. The script preserves the imported mesh,
UVs, material graph, and texture payload; only dimensions, origin, names, and
the requested forward orientation are baked into the exported production GLB.
"""

from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Matrix, Vector


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--textures", required=True)
    parser.add_argument("--previews", required=True)
    parser.add_argument("--audit", required=True)
    parser.add_argument("--asset-name", required=True)
    parser.add_argument("--target-width", type=float, required=True)
    parser.add_argument("--target-depth", type=float, required=True)
    parser.add_argument("--target-height", type=float, required=True)
    parser.add_argument("--yaw-degrees", type=float, default=0.0)
    return parser.parse_args(argv)


def reset() -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version = 0


def mesh_triangles(obj: bpy.types.Object) -> int:
    obj.data.calc_loop_triangles()
    return len(obj.data.loop_triangles)


def world_bounds(objects: list[bpy.types.Object]) -> tuple[Vector, Vector]:
    corners = [obj.matrix_world @ Vector(corner) for obj in objects for corner in obj.bound_box]
    if not corners:
        raise RuntimeError("No mesh bounds were available")
    minimum = Vector(tuple(min(point[i] for point in corners) for i in range(3)))
    maximum = Vector(tuple(max(point[i] for point in corners) for i in range(3)))
    return minimum, maximum


def vec(value: Vector) -> list[float]:
    return [round(float(component), 6) for component in value]


def dimensions(objects: list[bpy.types.Object]) -> Vector:
    minimum, maximum = world_bounds(objects)
    return maximum - minimum


def select_only(objects: list[bpy.types.Object]) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]


def detach_and_apply_import_transforms(objects: list[bpy.types.Object]) -> None:
    for obj in objects:
        world = obj.matrix_world.copy()
        obj.parent = None
        obj.matrix_world = world
    select_only(objects)
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)


def bake_yaw(objects: list[bpy.types.Object], yaw_degrees: float) -> None:
    if abs(yaw_degrees) <= 1.0e-8:
        return
    rotation = Matrix.Rotation(math.radians(yaw_degrees), 4, "Z")
    for obj in objects:
        obj.data.transform(rotation)
        obj.data.update()


def scale_exactly(objects: list[bpy.types.Object], target: Vector) -> tuple[Vector, Vector]:
    source = dimensions(objects)
    if min(source) <= 0.0:
        raise RuntimeError(f"Invalid source dimensions: {vec(source)}")
    factors = Vector((target.x / source.x, target.y / source.y, target.z / source.z))
    scale_matrix = Matrix.Diagonal((factors.x, factors.y, factors.z, 1.0))
    for obj in objects:
        obj.data.transform(scale_matrix)
        obj.data.update()
    bpy.context.view_layer.update()
    return source, factors


def set_bottom_center_origin(objects: list[bpy.types.Object]) -> tuple[Vector, Vector, Vector]:
    bpy.context.view_layer.update()
    minimum, maximum = world_bounds(objects)
    bottom_center = Vector(
        ((minimum.x + maximum.x) / 2.0, (minimum.y + maximum.y) / 2.0, minimum.z)
    )
    translation = Matrix.Translation(-bottom_center)
    for obj in objects:
        obj.data.transform(translation)
        obj.location = (0.0, 0.0, 0.0)
        obj.rotation_euler = (0.0, 0.0, 0.0)
        obj.scale = (1.0, 1.0, 1.0)
        obj.data.update()
    bpy.context.view_layer.update()
    final_minimum, final_maximum = world_bounds(objects)
    return bottom_center, final_minimum, final_maximum


def remove_nonproduction_objects(meshes: list[bpy.types.Object]) -> dict[str, list[str]]:
    removed: dict[str, list[str]] = {"cameras": [], "lights": [], "helpers": []}
    mesh_set = set(meshes)
    for obj in list(bpy.data.objects):
        if obj in mesh_set:
            continue
        if obj.type == "CAMERA":
            removed["cameras"].append(obj.name)
        elif obj.type == "LIGHT":
            removed["lights"].append(obj.name)
        else:
            removed["helpers"].append(obj.name)
        bpy.data.objects.remove(obj, do_unlink=True)
    for obj in meshes:
        obj.animation_data_clear()
    for action in list(bpy.data.actions):
        bpy.data.actions.remove(action)
    return removed


def clean_names(meshes: list[bpy.types.Object], asset_name: str) -> dict[str, list[str]]:
    object_names: list[str] = []
    mesh_names: list[str] = []
    if len(meshes) == 1:
        meshes[0].name = "CrateBodyAndLid"
        meshes[0].data.name = f"{asset_name}_Mesh"
    else:
        for index, obj in enumerate(meshes, 1):
            obj.name = f"CratePart_{index:02d}"
            obj.data.name = f"{asset_name}_Mesh_{index:02d}"
    for obj in meshes:
        object_names.append(obj.name)
        mesh_names.append(obj.data.name)

    material_names: list[str] = []
    for index, material in enumerate(bpy.data.materials, 1):
        material.name = "MAT_MaintenanceCrate_Source" if len(bpy.data.materials) == 1 else f"MAT_MaintenanceCrate_{index:02d}"
        material_names.append(material.name)
    return {"objects": object_names, "meshes": mesh_names, "materials": material_names}


def texture_role(image: bpy.types.Image) -> str | None:
    lower = image.name.lower()
    if "basecolor" in lower or "base_color" in lower:
        return "Baked_BaseColor"
    if "metallicroughness" in lower or "metallic_roughness" in lower:
        return "Baked_MetallicRoughness"
    if "emit" in lower or "emissive" in lower:
        return "Baked_Emit"
    return None


def extract_and_rename_textures(
    output_dir: Path, asset_name: str
) -> tuple[list[dict[str, object]], dict[str, float] | None]:
    output_dir.mkdir(parents=True, exist_ok=True)
    texture_info: list[dict[str, object]] = []
    roughness: dict[str, float] | None = None
    for image in list(bpy.data.images):
        role = texture_role(image)
        if not role or image.size[0] == 0 or image.size[1] == 0:
            continue
        filename = f"{asset_name}_Production_{role}.png"
        # Keep the embedded GLB image label short. Godot prefixes it with the
        # production GLB stem when extracting textures during import.
        image.name = role
        image.file_format = "PNG"
        image.filepath_raw = str(output_dir / filename)
        image.save()
        texture_info.append(
            {
                "role": role,
                "path": str((output_dir / filename).resolve()),
                "size": [int(image.size[0]), int(image.size[1])],
                "colorspace": image.colorspace_settings.name,
            }
        )
    return texture_info, roughness


def export_glb(meshes: list[bpy.types.Object], output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    select_only(meshes)
    bpy.ops.export_scene.gltf(
        filepath=str(output),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_texcoords=True,
        export_normals=True,
        export_tangents=False,
        export_materials="EXPORT",
        export_animations=False,
        export_skins=False,
        export_morph=False,
        export_yup=True,
    )


def look_at(obj: bpy.types.Object, target: Vector) -> None:
    obj.rotation_euler = (target - obj.location).to_track_quat("-Z", "Y").to_euler()


def add_area(name: str, location: tuple[float, float, float], energy: float, size: float, color: tuple[float, float, float]) -> None:
    bpy.ops.object.light_add(type="AREA", location=location)
    light = bpy.context.object
    light.name = name
    light.data.energy = energy
    light.data.shape = "DISK"
    light.data.size = size
    light.data.color = color
    look_at(light, Vector((0.0, 0.0, 0.32)))


def render_previews(preview_dir: Path) -> list[str]:
    preview_dir.mkdir(parents=True, exist_ok=True)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.film_transparent = False
    scene.render.resolution_percentage = 100
    scene.render.image_settings.color_depth = "8"
    scene.view_settings.look = "AgX - Medium High Contrast"

    world = bpy.data.worlds.new("Steamtek_Crate_QA_World")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.025, 0.03, 0.038, 1.0)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.28
    scene.world = world

    floor_material = bpy.data.materials.new("QA_Floor_Matte")
    floor_material.diffuse_color = (0.07, 0.075, 0.085, 1.0)
    floor_material.roughness = 0.9
    bpy.ops.mesh.primitive_plane_add(size=5.0, location=(0.0, 0.0, -0.002))
    floor = bpy.context.object
    floor.data.materials.append(floor_material)

    add_area("Warm_Key", (2.0, -2.5, 2.6), 650.0, 2.4, (1.0, 0.72, 0.54))
    add_area("Cool_Fill", (-2.2, -1.2, 1.7), 440.0, 2.0, (0.42, 0.72, 1.0))
    add_area("Rear_Rim", (0.0, 2.2, 1.8), 420.0, 1.8, (0.32, 0.62, 0.90))

    bpy.ops.object.camera_add()
    camera = bpy.context.object
    camera.name = "QA_Camera"
    scene.camera = camera
    rendered: list[str] = []
    views = {
        "Front": ((0.0, -2.3, 0.42), (0.0, 0.0, 0.32), 1.25),
        "Back": ((0.0, 2.3, 0.42), (0.0, 0.0, 0.32), 1.25),
        "Left": ((-2.3, 0.0, 0.42), (0.0, 0.0, 0.32), 0.90),
        "Right": ((2.3, 0.0, 0.42), (0.0, 0.0, 0.32), 0.90),
        "Top": ((0.0, 0.0, 2.5), (0.0, 0.0, 0.25), 1.25),
    }
    for name, (location, target, ortho_scale) in views.items():
        camera.data.type = "ORTHO"
        camera.data.ortho_scale = ortho_scale
        camera.location = location
        look_at(camera, Vector(target))
        scene.render.resolution_x = 640
        scene.render.resolution_y = 500
        path = preview_dir / f"STK_PROP_CONTAINER_Maintenance_Crate_01_QA_{name}.png"
        scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        rendered.append(str(path.resolve()))

    camera.data.type = "PERSP"
    camera.data.lens = 58
    camera.location = (1.65, -2.0, 1.35)
    look_at(camera, Vector((0.0, 0.0, 0.32)))
    scene.render.resolution_x = 640
    scene.render.resolution_y = 640
    path = preview_dir / "STK_PROP_CONTAINER_Maintenance_Crate_01_QA_ThreeQuarter.png"
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    rendered.append(str(path.resolve()))
    return rendered


def main() -> None:
    args = parse_args()
    source = Path(args.input).resolve()
    output = Path(args.output).resolve()
    texture_dir = Path(args.textures).resolve()
    preview_dir = Path(args.previews).resolve()
    audit_path = Path(args.audit).resolve()
    target = Vector((args.target_width, args.target_depth, args.target_height))

    if not source.is_file():
        raise FileNotFoundError(source)

    reset()
    bpy.ops.import_scene.gltf(filepath=str(source))
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if not meshes:
        raise RuntimeError("Source GLB contains no mesh objects")

    source_info = {
        "mesh_objects": len(meshes),
        "vertices": sum(len(obj.data.vertices) for obj in meshes),
        "triangles": sum(mesh_triangles(obj) for obj in meshes),
        "dimensions_blender_xyz": vec(dimensions(meshes)),
        "materials": [material.name for material in bpy.data.materials],
        "images": [image.name for image in bpy.data.images if image.size[0] > 0],
        "uv_layers": sum(len(obj.data.uv_layers) for obj in meshes),
    }
    topology_signature = [
        (len(obj.data.vertices), len(obj.data.edges), len(obj.data.polygons), mesh_triangles(obj))
        for obj in meshes
    ]

    removed = remove_nonproduction_objects(meshes)
    detach_and_apply_import_transforms(meshes)
    bake_yaw(meshes, args.yaw_degrees)
    pre_scale_dimensions, scale_factors = scale_exactly(meshes, target)
    original_bottom_center, final_minimum, final_maximum = set_bottom_center_origin(meshes)
    names = clean_names(meshes, args.asset_name)

    for obj in meshes:
        obj["steamtek_asset_id"] = args.asset_name
        obj["asset_type"] = "static_environment_prop_container"
        obj["unit_contract"] = "1_godot_unit_equals_1_meter"
        obj["contact_pivot"] = "bottom_center"
        obj["front_axis"] = "+Y_in_blender_maps_to_+Z_in_godot"
        obj["lid_separation"] = "combined_source_mesh"

    # Export before assigning external texture filepaths so the GLB retains the
    # approved short embedded labels (Baked_BaseColor, Baked_Emit, and
    # Baked_MetallicRoughness). Godot uses those labels for clean extraction.
    export_glb(meshes, output)
    textures, roughness = extract_and_rename_textures(texture_dir, args.asset_name)
    post_signature = [
        (len(obj.data.vertices), len(obj.data.edges), len(obj.data.polygons), mesh_triangles(obj))
        for obj in meshes
    ]
    previews = render_previews(preview_dir)

    audit = {
        "asset_name": args.asset_name,
        "source": str(source),
        "output": str(output),
        "source_info": source_info,
        "target_dimensions_blender_xyz": vec(target),
        "pre_scale_dimensions_blender_xyz": vec(pre_scale_dimensions),
        "scale_factors_xyz": vec(scale_factors),
        "original_bottom_center": vec(original_bottom_center),
        "final_minimum_blender_xyz": vec(final_minimum),
        "final_maximum_blender_xyz": vec(final_maximum),
        "yaw_degrees": args.yaw_degrees,
        "topology_signature_before": topology_signature,
        "topology_signature_after": post_signature,
        "topology_unchanged": topology_signature == post_signature,
        "removed_nonproduction_objects": removed,
        "clean_names": names,
        "textures": textures,
        "roughness_green_channel_sample": roughness,
        "material_modified": False,
        "lid_is_separate_object": len(meshes) > 1,
        "previews": previews,
    }
    audit_path.parent.mkdir(parents=True, exist_ok=True)
    audit_path.write_text(json.dumps(audit, indent=2, sort_keys=True), encoding="utf-8", newline="\n")
    print(json.dumps(audit, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
