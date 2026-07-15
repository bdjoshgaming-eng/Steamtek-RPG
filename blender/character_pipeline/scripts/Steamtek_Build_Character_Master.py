"""Build the Steamtek reusable character master without inventing a C001 rig."""

from __future__ import annotations

import json
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


SCRIPT_DIR = Path(__file__).resolve().parent


def find_project_root() -> Path | None:
    for candidate in (SCRIPT_DIR, *SCRIPT_DIR.parents):
        if (candidate / "project.godot").exists():
            return candidate
    return None


PROJECT_ROOT = find_project_root()
if PROJECT_ROOT is not None:
    MANIFEST_PATH = PROJECT_ROOT / "tools" / "character-pipeline" / "metadata" / "Steamtek_Character_Manifest.json"
    OUTPUT_PATH = SCRIPT_DIR.parent / "master" / "Steamtek_Character_Master.blend"
else:
    PIPELINE_ROOT = SCRIPT_DIR.parents[1]
    MANIFEST_PATH = PIPELINE_ROOT / "metadata" / "Steamtek_Character_Manifest.json"
    OUTPUT_PATH = PIPELINE_ROOT / "blender" / "Steamtek_Character_Master.blend"


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for collection in list(bpy.data.collections):
        bpy.data.collections.remove(collection)


def collection(name: str) -> bpy.types.Collection:
    value = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(value)
    return value


def link_object(obj: bpy.types.Object, target: bpy.types.Collection) -> None:
    target.objects.link(obj)


def empty(name: str, target: bpy.types.Collection, parent=None) -> bpy.types.Object:
    obj = bpy.data.objects.new(name, None)
    link_object(obj, target)
    obj.empty_display_type = "PLAIN_AXES"
    obj.empty_display_size = 0.2
    obj.parent = parent
    return obj


def point_at(obj: bpy.types.Object, target: Vector) -> None:
    obj.rotation_euler = (target - obj.location).to_track_quat("-Z", "Y").to_euler()


def light(name: str, target_collection, location, energy, size, color, look_at) -> None:
    data = bpy.data.lights.new(name, "AREA")
    data.energy = energy
    data.shape = "DISK"
    data.size = size
    data.color = color
    obj = bpy.data.objects.new(name, data)
    link_object(obj, target_collection)
    obj.location = location
    point_at(obj, look_at)


def main() -> None:
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    clear_scene()
    scene = bpy.context.scene

    characters = collection("COLLECTION_Character")
    render_rig = collection("COLLECTION_RenderRig")
    references = collection("COLLECTION_References")
    export = collection("COLLECTION_Export")

    direction_root = empty("ROOT_Direction", export)
    direction_root["steamtek_rotation_authority"] = True
    ground_root = empty("ROOT_GroundContact", export, direction_root)
    ground_root["steamtek_ground_contact"] = "center_between_boots"
    ground_root["steamtek_world_contact"] = [0.0, 0.0, 0.0]
    facing_root = empty("ROOT_CharacterFacing", export, ground_root)
    facing_root.rotation_euler[2] = math.radians(manifest["model"]["south_facing_yaw_offset_degrees"])
    facing_root["steamtek_facing_adapter"] = "local_-Y_to_screen_south"

    mesh_slot = empty("Character_Mesh_SLOT", characters, facing_root)
    mesh_slot["steamtek_replaceable_slot"] = True
    equipment_slot = empty("Equipment_SLOT", characters, facing_root)
    equipment_slot["steamtek_replaceable_slot"] = True

    armature_data = bpy.data.armatures.new("Armature")
    armature = bpy.data.objects.new("Armature", armature_data)
    link_object(armature, characters)
    armature.parent = facing_root
    armature["steamtek_placeholder"] = True
    armature["steamtek_rig_status"] = "uncalibrated_placeholder"
    armature["steamtek_warning"] = "Replace with the calibrated shared humanoid rig before production."

    reference = empty("C001_ScaleReference", references)
    reference["steamtek_immutable_reference"] = True
    reference["source_canvas"] = [1254, 1254]
    reference["visible_area_approx"] = [443, 1117]
    reference["godot_visual_scale"] = [0.73, 0.73]
    reference.hide_render = True

    camera_spec = manifest["camera"]
    target = Vector(camera_spec["target"])
    distance = float(camera_spec["distance"])
    # Exact 2:1 dimetric: elevation atan(1/sqrt(2)), azimuth 45 degrees.
    elevation = math.atan(1.0 / math.sqrt(2.0))
    horizontal = distance * math.cos(elevation)
    component = horizontal / math.sqrt(2.0)
    location = target + Vector((-component, -component, distance * math.sin(elevation)))
    camera_data = bpy.data.cameras.new("Camera_Iso")
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = float(camera_spec["ortho_scale"])
    camera = bpy.data.objects.new("Camera_Iso", camera_data)
    link_object(camera, render_rig)
    camera.location = location
    point_at(camera, target)
    camera["steamtek_projection"] = "2:1_dimetric"
    camera["steamtek_target"] = list(target)
    scene.camera = camera

    light("Key_Light", render_rig, (4.5, -5.5, 7.5), 900.0, 5.0, (0.64, 0.72, 0.84), target)
    light("Fill_Light", render_rig, (-4.0, -2.0, 4.2), 150.0, 4.0, (0.22, 0.55, 0.70), target)
    light("Rim_Light", render_rig, (-2.5, 3.5, 5.5), 500.0, 3.0, (0.88, 0.30, 0.10), target)

    render = manifest["render"]
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = render["width"]
    scene.render.resolution_y = render["height"]
    scene.render.resolution_percentage = render["resolution_percentage"]
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "8"
    scene.render.film_transparent = True
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene["steamtek_pipeline_version"] = manifest["pipeline_version"]
    scene["steamtek_contract"] = "1254_rgba_fixed_canvas_2to1_8direction"
    scene["steamtek_c001_is_immutable"] = True

    world = bpy.data.worlds.new("Steamtek_Character_World")
    scene.world = world
    world.use_nodes = True
    background = world.node_tree.nodes.get("Background")
    background.inputs["Color"].default_value = (0.004, 0.008, 0.014, 1.0)
    background.inputs["Strength"].default_value = 0.12

    note = bpy.data.texts.new("STEAMTEK_MASTER_README")
    note.write(
        "C001 is an immutable golden reference. This master contains no guessed C001 rig.\n"
        "Replace the placeholder Armature and set steamtek_placeholder=false only after calibration.\n"
        "Never move Camera_Iso, ROOT_Direction, or ROOT_GroundContact.\n"
    )
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT_PATH))
    print(f"STEAMTEK_MASTER={OUTPUT_PATH}")


if __name__ == "__main__":
    main()
