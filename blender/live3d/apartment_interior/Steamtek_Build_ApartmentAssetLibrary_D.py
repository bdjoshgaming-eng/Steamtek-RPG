"""Build the Steamtek apartment architecture and prop library.

Each catalog entry is exported as its own GLB with real geometry.  The master
Blend is a reproducible review catalog; Godot wrappers provide pivots,
collision, and snap sockets.
"""

from __future__ import annotations

import json
import math
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[3]
MODEL_DIR = ROOT / "assets/environment/live3d/models/apartment_interior/library_d"
TEXTURE_DIR = ROOT / "assets/environment/live3d/textures/apartment_interior"
MASTER = ROOT / "blender/live3d/apartment_interior/APT_ApartmentAssetLibrary_D.blend"
MANIFEST = ROOT / "assets/environment/live3d/models/apartment_interior/library_d/manifest.json"
REVIEW_DIR = ROOT / "docs/reviews/apartment_library_d"

ACTIVE = []
ASSETS = []
MATERIALS = {}


def reset_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def mat(name, color, metallic, roughness, *, texture=None, emission=None, strength=0.0):
    material = bpy.data.materials.new(name)
    material.use_nodes = True
    nodes = material.node_tree.nodes
    links = material.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if texture:
        image = bpy.data.images.load(str(texture), check_existing=True)
        tex = nodes.new("ShaderNodeTexImage")
        tex.image = image
        tex.interpolation = "Linear"
        links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    if emission:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = strength
    return material


def make_materials():
    MATERIALS.update({
        "steel": mat("STK_PaintedSteel", (0.13, 0.18, 0.21), 0.48, 0.62, texture=TEXTURE_DIR / "APT_Workbench_HandPaintedSteel_C.png"),
        "steel_dark": mat("STK_DeepSteel", (0.018, 0.027, 0.034), 0.42, 0.72),
        "trim": mat("STK_SelectEdge", (0.14, 0.17, 0.18), 0.64, 0.48),
        "copper": mat("STK_Copper", (0.42, 0.17, 0.055), 0.72, 0.38),
        "rust": mat("STK_RustLeather", (0.45, 0.12, 0.07), 0.02, 0.82, texture=TEXTURE_DIR / "APT_Upholstery_RustLeather_A.png"),
        "teal": mat("STK_TealFabric", (0.03, 0.20, 0.21), 0.0, 0.92, texture=TEXTURE_DIR / "APT_Upholstery_TealFabric_A.png"),
        "plum": mat("STK_PlumTextile", (0.12, 0.055, 0.18), 0.0, 0.94, texture=TEXTURE_DIR / "APT_Bedding_PlumNavy_A.png"),
        "ochre": mat("STK_OchreTextile", (0.46, 0.26, 0.055), 0.0, 0.90),
        "cyan": mat("STK_CyanSource", (0.0, 0.13, 0.16), 0.08, 0.24, emission=(0.0, 0.58, 0.72), strength=1.45),
        "magenta": mat("STK_MagentaSource", (0.18, 0.006, 0.06), 0.06, 0.25, emission=(0.86, 0.012, 0.26), strength=1.55),
        "glass": mat("STK_WindowGlass", (0.015, 0.16, 0.18), 0.10, 0.18, emission=(0.015, 0.25, 0.29), strength=0.38),
        "wood": mat("STK_DarkCompositeWood", (0.15, 0.065, 0.035), 0.10, 0.78),
        "leaf": mat("STK_PlantLeaf", (0.045, 0.16, 0.09), 0.0, 0.90),
        "soil": mat("STK_PlantSoil", (0.035, 0.018, 0.012), 0.0, 1.0),
    })


def finish(obj, bevel=0.018, uv=False):
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        modifier = obj.modifiers.new("PaintedEdge", "BEVEL")
        modifier.width = bevel
        modifier.segments = 3
        modifier.limit_method = "ANGLE"
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    if uv:
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.smart_project(angle_limit=math.radians(65), island_margin=0.025)
        bpy.ops.object.mode_set(mode="OBJECT")
    obj.select_set(False)
    ACTIVE.append(obj)
    return obj


def box(name, center, size, material, bevel=0.018, uv=False, rotation=(0.0, 0.0, 0.0)):
    bpy.ops.mesh.primitive_cube_add(location=center, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = size
    obj.data.materials.append(material)
    return finish(obj, bevel, uv)


def cylinder(name, center, radius, depth, material, rotation=(math.pi / 2, 0.0, 0.0), vertices=20):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=center, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(material)
    return finish(obj, radius * 0.12)


def pipe(name, p0, p1, radius, material, vertices=16):
    a, b = Vector(p0), Vector(p1)
    delta = b - a
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=delta.length, location=(a + b) * 0.5)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = delta.to_track_quat("Z", "Y")
    obj.data.materials.append(material)
    return finish(obj, radius * 0.12)


def sphere(name, center, radius, material, scale=None):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=18, ring_count=10, radius=radius, location=center)
    obj = bpy.context.object
    obj.name = name
    if scale:
        obj.scale = scale
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(material)
    ACTIVE.append(obj)
    return obj


def vent(name, x, y, z, width, height, frame_material, recess_material, slat_material, slat_count=5):
    """Build a recessed, readable service vent from real geometry."""
    box(f"{name}_Recess", (x, y, z), (width, 0.045, height), recess_material, 0.012)
    rail = 0.045
    box(f"{name}_Top", (x, y - 0.032, z + height * 0.5 - rail * 0.5), (width, 0.055, rail), frame_material, 0.012)
    box(f"{name}_Bottom", (x, y - 0.032, z - height * 0.5 + rail * 0.5), (width, 0.055, rail), frame_material, 0.012)
    box(f"{name}_Left", (x - width * 0.5 + rail * 0.5, y - 0.032, z), (rail, 0.055, height), frame_material, 0.012)
    box(f"{name}_Right", (x + width * 0.5 - rail * 0.5, y - 0.032, z), (rail, 0.055, height), frame_material, 0.012)
    usable_height = height - rail * 2.5
    for index in range(slat_count):
        slat_z = z - usable_height * 0.5 + usable_height * (index + 0.5) / slat_count
        box(f"{name}_Slat_{index:02d}", (x, y - 0.065, slat_z), (width - rail * 2.2, 0.035, 0.022), slat_material, 0.007)


def begin():
    ACTIVE.clear()


def export_asset(asset_id, category, dimensions, sockets=None):
    MODEL_DIR.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    for obj in ACTIVE:
        obj.select_set(True)
        obj["steamtek_asset_id"] = asset_id
    bpy.context.view_layer.objects.active = ACTIVE[0]
    path = MODEL_DIR / f"{asset_id}.glb"
    bpy.ops.export_scene.gltf(
        filepath=str(path), export_format="GLB", use_selection=True,
        export_apply=True, export_texcoords=True, export_normals=True,
        export_materials="EXPORT",
    )
    record = {
        "id": asset_id,
        "category": category,
        "dimensions": dimensions,
        "model": f"res://assets/environment/live3d/models/apartment_interior/library_d/{asset_id}.glb",
        "sockets": sockets or [],
        "objects": list(ACTIVE),
    }
    ASSETS.append(record)
    return record


def build_door():
    begin()
    s, d, t, c, cy, mg = (MATERIALS[k] for k in ("steel", "steel_dark", "trim", "copper", "cyan", "magenta"))
    # Closed leaf is strongly separated from wall by depth, frame, threshold, and shadow gap.
    box("DoorWall_LeftPier", (-1.0, 0.0, 1.35), (1.0, 0.18, 2.7), s, 0.028, True)
    box("DoorWall_RightPier", (1.0, 0.0, 1.35), (1.0, 0.18, 2.7), s, 0.028, True)
    box("DoorWall_Header", (0.0, 0.0, 2.47), (1.0, 0.18, 0.46), s, 0.028, True)
    box("Door_ShadowGap", (0.0, -0.105, 1.18), (1.14, 0.055, 2.30), d, 0.016)
    box("Door_Leaf", (0.0, -0.15, 1.18), (1.0, 0.13, 2.20), s, 0.035, True)
    for z in (0.48, 1.18, 1.88):
        box(f"Door_Inset_{z}", (0.0, -0.225, z), (0.72, 0.045, 0.42), d, 0.025)
        box(f"Door_InsetHighlight_{z}", (0.0, -0.253, z + 0.19), (0.76, 0.025, 0.035), t, 0.008)
    for x in (-0.56, 0.56):
        box(f"Door_Frame_{x}", (x, -0.14, 1.18), (0.12, 0.18, 2.36), t, 0.025)
    box("Door_FrameTop", (0.0, -0.14, 2.36), (1.24, 0.18, 0.12), t, 0.025)
    box("Door_Threshold", (0.0, -0.18, 0.08), (1.18, 0.34, 0.13), t, 0.025)
    box("Door_AccessHousing", (0.68, -0.18, 1.18), (0.25, 0.16, 0.46), d, 0.025)
    box("Door_AccessScreen", (0.68, -0.27, 1.26), (0.16, 0.025, 0.20), cy, 0.018)
    cylinder("Door_HandleBoss", (0.34, -0.29, 1.05), 0.06, 0.05, c)
    box("Door_Handle", (0.48, -0.32, 1.05), (0.30, 0.055, 0.055), c, 0.018)
    box("Door_StatusStrip", (0.0, -0.245, 2.10), (0.55, 0.025, 0.055), mg, 0.015)
    export_asset("APT_Wall_Door_300x270_Service", "architecture", [3.0, 2.7, 0.34], [{"name":"DoorInteraction","position":[0,1.1,0.22],"role":"closed_door_interaction_future"}])


def build_window(asset_id, slot=False):
    begin()
    s, d, t, c, g, cy = (MATERIALS[k] for k in ("steel", "steel_dark", "trim", "copper", "glass", "cyan"))
    opening_w = 0.78 if slot else 1.85
    sill_z = 1.0 if slot else 0.72
    opening_h = 1.25 if slot else 1.35
    side_w = (3.0 - opening_w) * 0.5
    box(asset_id + "_LeftPier", (-1.5 + side_w * 0.5, 0.0, 1.35), (side_w, 0.18, 2.7), s, 0.028, True)
    box(asset_id + "_RightPier", (1.5 - side_w * 0.5, 0.0, 1.35), (side_w, 0.18, 2.7), s, 0.028, True)
    box(asset_id + "_LowerWall", (0.0, 0.0, sill_z * 0.5), (opening_w, 0.18, sill_z), s, 0.028, True)
    header_h = 2.7 - sill_z - opening_h
    box(asset_id + "_Header", (0.0, 0.0, sill_z + opening_h + header_h * 0.5), (opening_w, 0.18, header_h), s, 0.028, True)
    z = sill_z + opening_h * 0.5
    box(asset_id + "_Glass", (0.0, -0.08, z), (opening_w - 0.14, 0.035, opening_h - 0.14), g, 0.025)
    for x in (-opening_w * 0.5, opening_w * 0.5):
        box(asset_id + f"_FrameSide_{x}", (x, -0.12, z), (0.10, 0.16, opening_h + 0.14), t, 0.025)
    for zz in (sill_z, sill_z + opening_h):
        box(asset_id + f"_FrameRail_{zz}", (0.0, -0.12, zz), (opening_w + 0.14, 0.16, 0.10), t, 0.025)
    box(asset_id + "_Sill", (0.0, -0.19, sill_z - 0.02), (opening_w + 0.28, 0.36, 0.12), t, 0.025)
    if slot:
        for i in range(3):
            box(asset_id + f"_Guard_{i}", (-0.22 + i * 0.22, -0.19, z), (0.035, 0.05, opening_h - 0.18), c, 0.01)
        box(asset_id + "_Status", (0.55, -0.19, 1.92), (0.10, 0.05, 0.30), cy, 0.018)
    else:
        box(asset_id + "_Mullion", (0.0, -0.18, z), (0.065, 0.05, opening_h - 0.12), c, 0.014)
        pipe(asset_id + "_Conduit", (1.12, -0.15, 0.28), (1.12, -0.15, 1.98), 0.026, c)
    export_asset(asset_id, "architecture", [3.0, 2.7, 0.36], [{"name":"WindowSillProp","position":[0,sill_z+0.08,0.22],"role":"prop_surface"}])


def build_couch(asset_id, upholstery):
    begin()
    s, t, u, d = MATERIALS["steel"], MATERIALS["trim"], MATERIALS[upholstery], MATERIALS["steel_dark"]
    box(asset_id + "_Frame", (0, 0, 0.22), (2.15, 0.82, 0.30), s, 0.045, True)
    box(asset_id + "_Seat", (0, -0.05, 0.49), (1.75, 0.67, 0.26), u, 0.09, True)
    for i, x in enumerate((-0.57, 0.0, 0.57)):
        box(asset_id + f"_BackCushion_{i}", (x, 0.30, 0.78), (0.54, 0.20, 0.56), u, 0.085, True, rotation=(math.radians(-8),0,0))
        box(asset_id + f"_SeatSeam_{i}", (x + 0.285, -0.36, 0.51), (0.025, 0.04, 0.20), d, 0.006)
    for x in (-1.0, 1.0):
        box(asset_id + f"_Arm_{x}", (x, -0.02, 0.60), (0.22, 0.78, 0.50), u, 0.07, True)
        box(asset_id + f"_Foot_{x}", (x * 0.88, -0.28, 0.07), (0.12, 0.12, 0.14), t, 0.018)
        box(asset_id + f"_BackFoot_{x}", (x * 0.88, 0.28, 0.07), (0.12, 0.12, 0.14), t, 0.018)
    export_asset(asset_id, "seating", [2.2,0.9,1.05], [
        {"name":"SeatLeft","position":[-0.48,0.67,0.05],"role":"prop_surface"},
        {"name":"SeatRight","position":[0.48,0.67,0.05],"role":"prop_surface"},
        {"name":"LeftFurniture","position":[-1.1,0,0],"role":"furniture_chain"},
        {"name":"RightFurniture","position":[1.1,0,0],"role":"furniture_chain"},
    ])


def build_lounge_chair(asset_id, upholstery):
    begin()
    s, t, u = MATERIALS["steel"], MATERIALS["trim"], MATERIALS[upholstery]
    box(asset_id + "_Base", (0,0,0.20), (0.84,0.82,0.28), s, 0.045, True)
    box(asset_id + "_Seat", (0,-0.04,0.47), (0.65,0.65,0.24), u, 0.09, True)
    box(asset_id + "_Back", (0,0.29,0.80), (0.67,0.20,0.65), u, 0.09, True, rotation=(math.radians(-9),0,0))
    for x in (-0.39,0.39):
        box(asset_id + f"_Arm_{x}", (x,-0.01,0.60), (0.16,0.72,0.46), u, 0.06, True)
    for x in (-0.32,0.32):
        for y in (-0.28,0.28):
            box(asset_id + f"_Foot_{x}_{y}", (x,y,0.07), (0.10,0.10,0.14), t, 0.016)
    export_asset(asset_id, "seating", [0.94,0.9,1.12], [{"name":"Seat","position":[0,0.65,0],"role":"prop_surface"}])


def build_bed(asset_id, textile):
    begin()
    s, t, u, d = MATERIALS["steel"], MATERIALS["trim"], MATERIALS[textile], MATERIALS["steel_dark"]
    box(asset_id + "_Frame", (0,0,0.22), (1.62,2.12,0.34), s, 0.045, True)
    box(asset_id + "_Mattress", (0,-0.03,0.50), (1.52,1.98,0.28), u, 0.09, True)
    box(asset_id + "_Blanket", (0,-0.24,0.67), (1.48,1.32,0.13), u, 0.07, True)
    box(asset_id + "_Headboard", (0,0.99,0.82), (1.62,0.15,1.05), s, 0.04, True)
    for x in (-0.68,0.68):
        box(asset_id + f"_HeadTrim_{x}", (x,0.90,0.82), (0.09,0.10,0.92), t, 0.018)
        box(asset_id + f"_Foot_{x}", (x,-0.94,0.08), (0.12,0.12,0.16), d, 0.018)
    box(asset_id + "_HeadLight", (0,0.88,1.02), (0.42,0.035,0.055), MATERIALS["cyan"], 0.014)
    export_asset(asset_id, "sleep", [1.7,2.2,1.35], [
        {"name":"PillowLeft","position":[-0.38,0.68,0.72],"role":"prop_surface"},
        {"name":"PillowRight","position":[0.38,0.68,0.72],"role":"prop_surface"},
        {"name":"BedsideLeft","position":[-0.95,0,0],"role":"furniture_chain"},
        {"name":"BedsideRight","position":[0.95,0,0],"role":"furniture_chain"},
    ])


def build_pillow(asset_id, textile):
    begin()
    u, d = MATERIALS[textile], MATERIALS["steel_dark"]
    box(asset_id + "_Cushion", (0,0,0.18), (0.50,0.20,0.34), u, 0.10, True)
    for x in (-0.245,0.245):
        box(asset_id + f"_Seam_{x}", (x,-0.105,0.18), (0.018,0.025,0.28), d, 0.004)
    export_asset(asset_id, "small_prop", [0.52,0.22,0.36])


def build_trash_round():
    begin()
    s, d, t = MATERIALS["steel"], MATERIALS["steel_dark"], MATERIALS["trim"]
    cylinder("TrashRound_Body", (0,0,0.34), 0.25, 0.66, s, rotation=(0,0,0), vertices=28)
    cylinder("TrashRound_Lip", (0,0,0.67), 0.28, 0.08, t, rotation=(0,0,0), vertices=28)
    cylinder("TrashRound_Opening", (0,0,0.715), 0.20, 0.025, d, rotation=(0,0,0), vertices=28)
    for i in range(8):
        angle=2*math.pi*i/8
        box(f"TrashRound_Rib_{i}",(math.cos(angle)*0.235,math.sin(angle)*0.235,0.35),(0.025,0.025,0.46),t,0.005,rotation=(0,0,angle))
    export_asset("APT_TrashCan_Round_Steel", "utility", [0.58,0.58,0.74])


def build_trash_smart():
    begin()
    s,d,t,cy=MATERIALS["steel"],MATERIALS["steel_dark"],MATERIALS["trim"],MATERIALS["cyan"]
    box("TrashSmart_Body",(0,0,0.40),(0.48,0.42,0.78),s,0.06,True)
    box("TrashSmart_Lid",(0,-0.02,0.82),(0.50,0.44,0.10),t,0.035)
    box("TrashSmart_Opening",(0,-0.235,0.62),(0.28,0.035,0.20),d,0.025)
    box("TrashSmart_Status",(0,-0.26,0.34),(0.20,0.025,0.07),cy,0.014)
    export_asset("APT_TrashCan_Smart_Teal", "utility", [0.52,0.46,0.88])


def cabinet_face(prefix, x, z, width, height):
    s,d,t=MATERIALS["steel"],MATERIALS["steel_dark"],MATERIALS["trim"]
    box(prefix+"_Face",(x,-0.31,z),(width,0.05,height),s,0.018,True)
    box(prefix+"_Inset",(x,-0.345,z),(width-0.10,0.028,height-0.10),d,0.016)
    box(prefix+"_Handle",(x,-0.375,z),(width*0.38,0.035,0.045),t,0.012)


def build_cabinet(asset_id, kind):
    begin()
    s,t,c,cy,mg=MATERIALS["steel"],MATERIALS["trim"],MATERIALS["copper"],MATERIALS["cyan"],MATERIALS["magenta"]
    if kind == "low":
        dims=(1.6,0.62,0.92)
        box(asset_id+"_Body",(0,0,0.45),(1.56,0.58,0.86),s,0.045,True)
        for i,x in enumerate((-0.52,0,0.52)): cabinet_face(asset_id+f"_Door_{i}",x,0.45,0.47,0.72)
        box(asset_id+"_Top",(0,0,0.91),(1.64,0.64,0.10),t,0.03)
        box(asset_id+"_Status",(0.60,-0.34,0.78),(0.18,0.025,0.06),cy,0.012)
    elif kind == "tall":
        dims=(1.05,0.62,2.2)
        box(asset_id+"_Body",(0,0,1.08),(1.0,0.58,2.12),s,0.045,True)
        cabinet_face(asset_id+"_Upper",0,1.55,0.82,0.75)
        cabinet_face(asset_id+"_Lower",0,0.68,0.82,0.75)
        vent(asset_id+"_Vent",0,-0.34,1.08,0.46,0.25,s,t,MATERIALS["steel_dark"],5)
        pipe(asset_id+"_Pipe",(0.43,-0.34,0.2),(0.43,-0.34,1.92),0.023,c)
        box(asset_id+"_Status",(-0.34,-0.35,1.92),(0.10,0.025,0.30),mg,0.015)
    elif kind == "wall":
        dims=(1.6,0.46,0.85)
        box(asset_id+"_Body",(0,0,0.42),(1.56,0.42,0.80),s,0.04,True)
        cabinet_face(asset_id+"_Left",-0.39,0.42,0.68,0.65)
        cabinet_face(asset_id+"_Right",0.39,0.42,0.68,0.65)
        box(asset_id+"_Undersource",(0,-0.24,0.08),(0.58,0.035,0.055),cy,0.014)
    else:
        dims=(1.8,0.66,0.96)
        box(asset_id+"_Body",(0,0,0.47),(1.76,0.62,0.90),s,0.045,True)
        for i,x in enumerate((-0.58,0,0.58)): cabinet_face(asset_id+f"_Front_{i}",x,0.47,0.50,0.72)
        box(asset_id+"_Counter",(0,0,0.96),(1.84,0.70,0.10),t,0.03)
        cylinder(asset_id+"_Sink",(0.42,-0.08,1.02),0.25,0.04,MATERIALS["steel_dark"],rotation=(0,0,0),vertices=28)
        pipe(asset_id+"_Faucet",(0.42,0.12,1.02),(0.42,0.12,1.32),0.025,c)
    export_asset(asset_id,"storage",list(dims),[{"name":"TopSurface","position":[0,dims[2]+0.04,0],"role":"prop_surface"}])


def build_table(asset_id, kind):
    begin()
    s,t,w,c=MATERIALS["steel"],MATERIALS["trim"],MATERIALS["wood"],MATERIALS["copper"]
    if kind == "dining": dims=(1.8,0.9,0.78); top=(1.8,0.9,0.12)
    elif kind == "coffee": dims=(1.35,0.7,0.48); top=(1.35,0.7,0.11)
    else: dims=(0.58,0.58,0.62); top=(0.58,0.58,0.10)
    box(asset_id+"_Top",(0,0,dims[2]-top[2]*0.5),top,w,0.035)
    box(asset_id+"_Edge",(0,-top[1]*0.52,dims[2]-top[2]*0.5),(top[0]+0.05,0.055,top[2]),t,0.014)
    for x in (-top[0]*0.42,top[0]*0.42):
        for y in (-top[1]*0.38,top[1]*0.38):
            box(asset_id+f"_Leg_{x}_{y}",(x,y,(dims[2]-top[2])*0.5),(0.11,0.11,dims[2]-top[2]),s,0.018,True)
    pipe(asset_id+"_Brace",(-top[0]*0.35,0,dims[2]*0.35),(top[0]*0.35,0,dims[2]*0.35),0.025,c)
    export_asset(asset_id,"table",list(dims),[{"name":"Surface","position":[0,dims[2]+0.03,0],"role":"prop_surface"}])


def build_dining_chair(asset_id, textile):
    begin()
    s,t,u=MATERIALS["steel"],MATERIALS["trim"],MATERIALS[textile]
    box(asset_id+"_Seat",(0,0,0.50),(0.48,0.48,0.14),u,0.06,True)
    box(asset_id+"_Back",(0,0.20,0.86),(0.46,0.12,0.62),u,0.06,True,rotation=(math.radians(-5),0,0))
    for x in (-0.19,0.19):
        for y in (-0.18,0.18):
            box(asset_id+f"_Leg_{x}_{y}",(x,y,0.25),(0.07,0.07,0.50),s,0.012)
    box(asset_id+"_BackRail",(0,0.24,1.14),(0.52,0.09,0.08),t,0.018)
    export_asset(asset_id,"seating",[0.58,0.58,1.2])


def build_stool(asset_id, textile):
    begin()
    s,t,u=MATERIALS["steel"],MATERIALS["trim"],MATERIALS[textile]
    cylinder(asset_id+"_Seat",(0,0,0.72),0.24,0.14,u,rotation=(0,0,0),vertices=28)
    pipe(asset_id+"_Post",(0,0,0.14),(0,0,0.66),0.055,s)
    for i in range(4):
        a=math.pi*0.5*i
        pipe(asset_id+f"_Leg_{i}",(0,0,0.18),(math.cos(a)*0.28,math.sin(a)*0.28,0.02),0.027,t)
    export_asset(asset_id,"seating",[0.62,0.62,0.82])


def build_shelf():
    begin()
    s,t,c=MATERIALS["steel"],MATERIALS["trim"],MATERIALS["copper"]
    for x in (-0.58,0.58): box(f"Shelf_Post_{x}",(x,0,1.0),(0.10,0.42,2.0),s,0.018,True)
    for i,z in enumerate((0.14,0.60,1.06,1.52,1.96)):
        box(f"Shelf_Board_{i}",(0,0,z),(1.26,0.46,0.10),t,0.018)
    pipe("Shelf_ServiceRail",(-0.50,-0.25,1.75),(0.50,-0.25,1.75),0.024,c)
    export_asset("APT_Shelf_Open_Service","storage",[1.3,0.5,2.05],[{"name":"Shelf1","position":[0,0.66,0],"role":"prop_surface"},{"name":"Shelf2","position":[0,1.12,0],"role":"prop_surface"},{"name":"Shelf3","position":[0,1.58,0],"role":"prop_surface"}])


def build_floor_lamp():
    begin()
    c,t,mg=MATERIALS["copper"],MATERIALS["trim"],MATERIALS["magenta"]
    cylinder("FloorLamp_Base",(0,0,0.06),0.22,0.12,t,rotation=(0,0,0),vertices=28)
    pipe("FloorLamp_Stem",(0,0,0.12),(0,0,1.55),0.035,c)
    box("FloorLamp_Source",(0,0,1.62),(0.18,0.18,0.42),mg,0.06)
    box("FloorLamp_CageTop",(0,0,1.86),(0.30,0.30,0.06),t,0.018)
    box("FloorLamp_CageBottom",(0,0,1.38),(0.30,0.30,0.06),t,0.018)
    export_asset("APT_Lamp_Floor_Copper","utility",[0.5,0.5,1.9])


def build_planter():
    begin()
    s,c,l,soil=MATERIALS["steel"],MATERIALS["copper"],MATERIALS["leaf"],MATERIALS["soil"]
    box("Planter_Pot",(0,0,0.28),(0.52,0.52,0.56),s,0.06,True)
    cylinder("Planter_Soil",(0,0,0.56),0.22,0.04,soil,rotation=(0,0,0),vertices=28)
    pipe("Planter_SensorStem",(0.18,0.18,0.52),(0.18,0.18,0.88),0.018,c)
    for i in range(10):
        angle=2*math.pi*i/10
        tip=(math.cos(angle)*0.38,math.sin(angle)*0.38,0.88+0.16*(i%3))
        pipe(f"Planter_Stem_{i}",(0,0,0.58),tip,0.022,l,12)
        sphere(f"Planter_Leaf_{i}",tip,0.12,l,scale=(1.6,0.45,0.55))
    export_asset("APT_Prop_Planter_Teal","small_prop",[0.9,0.9,1.2])


def arrange_and_render():
    # Move exported assets into review rows only after GLB export.
    groups={}
    for asset in ASSETS: groups.setdefault(asset["category"],[]).append(asset)
    y_cursor=0.0
    for category, assets in groups.items():
        for i,asset in enumerate(assets):
            col=i%6; row=i//6
            offset=Vector((col*3.3,y_cursor+row*3.0,0))
            for obj in asset["objects"]: obj.location += offset
        y_cursor += (math.ceil(len(assets)/6)*3.0)+1.0

    scene=bpy.context.scene
    bpy.ops.object.camera_add(location=(8,-14,12))
    camera=bpy.context.object; camera.name="ReviewCamera"; camera.data.type="ORTHO"; scene.camera=camera
    review_lights=[]
    for name,loc,energy,size,color in (
        ("ReviewKey",(-5,-8,14),1500,8,(0.72,0.84,0.95)),
        ("ReviewWarm",(15,-2,8),900,6,(1.0,0.40,0.18)),
        ("ReviewRim",(8,20,10),1100,7,(0.04,0.62,0.74)),
    ):
        bpy.ops.object.light_add(type="AREA",location=loc)
        light=bpy.context.object; light.name=name; light.data.energy=energy; light.data.size=size; light.data.color=color
        review_lights.append(light)
    scene.render.engine="BLENDER_EEVEE_NEXT"; scene.render.film_transparent=True
    scene.render.image_settings.file_format="PNG"; scene.view_settings.look="AgX - Medium High Contrast"; scene.view_settings.exposure=0.55
    REVIEW_DIR.mkdir(parents=True,exist_ok=True)
    for category,assets in groups.items():
        visible=set(obj for asset in assets for obj in asset["objects"])
        for asset in ASSETS:
            for obj in asset["objects"]: obj.hide_render=obj not in visible
        points=[]
        for obj in visible:
            if obj.type=="MESH": points.extend([obj.matrix_world @ Vector(corner) for corner in obj.bound_box])
        low=Vector((min(p.x for p in points),min(p.y for p in points),min(p.z for p in points)))
        high=Vector((max(p.x for p in points),max(p.y for p in points),max(p.z for p in points)))
        center=(low+high)*0.5
        review_lights[0].location=center+Vector((-5,-8,14))
        review_lights[1].location=center+Vector((12,-3,8))
        review_lights[2].location=center+Vector((7,14,10))
        camera.location=center+Vector((8,-11,9))
        camera.rotation_euler=(center-camera.location).to_track_quat("-Z","Y").to_euler()
        camera.data.ortho_scale=max(high.x-low.x,high.y-low.y)*0.72+2.5
        scene.render.resolution_x=1800; scene.render.resolution_y=1100; scene.render.resolution_percentage=100
        scene.render.filepath=str(REVIEW_DIR/f"APT_Library_D_{category}.png")
        bpy.ops.render.render(write_still=True)


def main():
    for path in (MODEL_DIR,REVIEW_DIR,MASTER.parent): path.mkdir(parents=True,exist_ok=True)
    reset_scene(); make_materials()
    build_door(); build_window("APT_Wall_Window_Wide_300x270",False); build_window("APT_Wall_Window_Slot_300x270",True)
    for suffix,mat_name in (("Rust","rust"),("Teal","teal"),("Plum","plum")):
        build_couch(f"APT_Couch_2Seat_{suffix}",mat_name)
        build_lounge_chair(f"APT_Chair_Lounge_{suffix}",mat_name)
        build_bed(f"APT_Bed_Full_{suffix}",mat_name)
    for suffix,mat_name in (("Rust","rust"),("Teal","teal"),("Plum","plum"),("Ochre","ochre")):
        build_pillow(f"APT_Prop_Pillow_{suffix}",mat_name)
    build_trash_round(); build_trash_smart()
    build_cabinet("APT_Cabinet_Low_Service","low")
    build_cabinet("APT_Cabinet_Tall_Wardrobe","tall")
    build_cabinet("APT_Cabinet_Wall_Kitchen","wall")
    build_cabinet("APT_Cabinet_Base_Kitchen","base")
    build_shelf()
    build_table("APT_Table_Dining_Service","dining")
    build_table("APT_Table_Coffee_Service","coffee")
    build_table("APT_Table_Side_Service","side")
    build_dining_chair("APT_Chair_Dining_Rust","rust")
    build_dining_chair("APT_Chair_Dining_Teal","teal")
    build_stool("APT_Stool_Bar_Rust","rust")
    build_stool("APT_Stool_Bar_Teal","teal")
    build_floor_lamp(); build_planter()

    serializable=[]
    for asset in ASSETS:
        serializable.append({k:v for k,v in asset.items() if k!="objects"})
    MANIFEST.write_text(json.dumps({"contract":"live3d_meter_v1","assets":serializable},indent=2),encoding="utf-8")
    arrange_and_render()
    bpy.ops.wm.save_as_mainfile(filepath=str(MASTER))
    print(f"LIBRARY_ASSETS={len(ASSETS)}")
    print(f"LIBRARY_MANIFEST={MANIFEST}")
    print(f"LIBRARY_MASTER={MASTER}")


if __name__ == "__main__": main()
