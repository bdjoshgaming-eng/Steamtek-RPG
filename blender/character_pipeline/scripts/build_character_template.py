"""Build a portable Steamtek character render template with a proxy walk cycle."""

from __future__ import annotations

import sys
from pathlib import Path

import bpy

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from steamtek_character_standard import configure_character_stage


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        for block in list(datablocks):
            if block.users == 0:
                datablocks.remove(block)


def mat(name, color, metallic=0.0, roughness=0.5):
    material = bpy.data.materials.new(name)
    material.diffuse_color = color
    material.use_nodes = True
    bsdf = material.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return material


def cube(name, location, scale, material, parent):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    obj.parent = parent
    return obj


def sphere(name, location, scale, material, parent):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=32, ring_count=16, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    obj.parent = parent
    return obj


def create_proxy(root):
    coat = mat("STK_Proxy_Coat", (0.050, 0.080, 0.115, 1.0), 0.25, 0.42)
    leather = mat("STK_Proxy_Leather", (0.10, 0.035, 0.018, 1.0), 0.12, 0.58)
    metal = mat("STK_Proxy_Metal", (0.035, 0.050, 0.070, 1.0), 0.82, 0.25)
    copper = mat("STK_Proxy_Copper", (0.30, 0.075, 0.018, 1.0), 0.78, 0.28)
    skin = mat("STK_Proxy_Skin", (0.35, 0.17, 0.10, 1.0), 0.0, 0.62)

    pelvis = cube("STK_Pelvis", (0, 0, 0.88), (0.20, 0.13, 0.12), leather, root)
    cube("STK_Torso", (0, 0, 1.22), (0.27, 0.16, 0.32), coat, root)
    sphere("STK_Head", (0, 0, 1.68), (0.18, 0.16, 0.20), skin, root)
    cube("STK_Hat", (0, 0, 1.88), (0.24, 0.20, 0.07), leather, root)
    cube("STK_HatBand", (0, -0.01, 1.84), (0.25, 0.21, 0.025), copper, root)

    left_leg = cube("STK_Leg_L", (-0.11, 0, 0.48), (0.09, 0.10, 0.32), leather, root)
    right_leg = cube("STK_Leg_R", (0.11, 0, 0.48), (0.09, 0.10, 0.32), leather, root)
    left_boot = cube("STK_Boot_L", (-0.11, -0.04, 0.13), (0.11, 0.17, 0.10), metal, root)
    right_boot = cube("STK_Boot_R", (0.11, -0.04, 0.13), (0.11, 0.17, 0.10), metal, root)
    left_arm = cube("STK_Arm_L", (-0.36, 0, 1.22), (0.08, 0.09, 0.30), coat, root)
    right_arm = cube("STK_Arm_R", (0.36, 0, 1.22), (0.08, 0.09, 0.30), coat, root)
    sphere("STK_Gauge", (0.25, -0.18, 1.23), (0.08, 0.035, 0.08), copper, root)

    animated = (left_leg, right_leg, left_boot, right_boot, left_arm, right_arm)
    base = {obj.name: obj.location.copy() for obj in animated}
    for frame in range(1, 9):
        phase = (frame - 1) % 8
        wave = (0.0, 0.10, 0.14, 0.10, 0.0, -0.10, -0.14, -0.10)[phase]
        for obj in animated:
            obj.location = base[obj.name].copy()
        left_leg.location.y += wave
        left_boot.location.y += wave
        right_leg.location.y -= wave
        right_boot.location.y -= wave
        left_arm.location.y -= wave
        right_arm.location.y += wave
        for obj in animated:
            obj.keyframe_insert(data_path="location", frame=frame)
    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = 8
    pelvis["steamtek_proxy"] = True


def main():
    clear_scene()
    scene = bpy.context.scene
    root = bpy.data.objects.new("STK_CharacterRoot", None)
    bpy.context.collection.objects.link(root)
    root.empty_display_type = "PLAIN_AXES"
    root.empty_display_size = 0.25
    root["steamtek_forward_axis"] = "-Y"
    root["steamtek_boot_contact"] = "0,0,0"
    create_proxy(root)
    configure_character_stage(scene)
    output = SCRIPT_DIR.parent / "master" / "Steamtek_CharacterTemplate.blend"
    output.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(output))
    print(f"STEAMTEK_CHARACTER_TEMPLATE={output}")


if __name__ == "__main__":
    main()

