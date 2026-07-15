import bpy
import json
import math
import os
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view

PROJECT = r"C:\My Game\Steamtek-RPG"
OUT_ROOT = os.path.join(PROJECT, "assets", "modular_v2", "apartment_exterior_v3")
PRODUCTION = os.path.join(OUT_ROOT, "production")
CALIBRATION = os.path.join(OUT_ROOT, "calibration")
BLEND_OUT = os.path.join(PROJECT, "blender", "modular_v2", "apartment_exterior_v3", "Steamtek_ApartmentExterior_WestEast_Master.blend")
MANIFEST_OUT = os.path.join(OUT_ROOT, "Steamtek_ApartmentExterior_WestEast_Manifest.json")
os.makedirs(PRODUCTION, exist_ok=True)
os.makedirs(CALIBRATION, exist_ok=True)
os.makedirs(os.path.dirname(BLEND_OUT), exist_ok=True)

PPV = 181.01933598375618  # gives a 256x128 projected step for a 2 BU bay at 30-degree elevation
AZIMUTH_CURRENT = "south_west_to_north_east"
AZIMUTH_WEST_EAST = "south_east_to_north_west"
CAMERA_VECTOR_CURRENT = Vector((-8.0, -8.0, math.sqrt(128.0) * math.tan(math.radians(30.0))))
CAMERA_VECTOR_WEST_EAST = Vector((8.0, -8.0, math.sqrt(128.0) * math.tan(math.radians(30.0))))


def reset_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.meshes, bpy.data.curves, bpy.data.materials, bpy.data.cameras, bpy.data.lights):
        pass
    for collection in list(bpy.data.collections):
        if collection.name != "Collection":
            bpy.data.collections.remove(collection)
    root = bpy.context.scene.collection
    base = bpy.data.collections.get("Collection")
    if base:
        base.name = "COLLECTION_Infrastructure"
    return base


def make_collection(name):
    col = bpy.data.collections.new(name)
    bpy.context.scene.collection.children.link(col)
    return col


def move_to_collection(obj, col):
    for old in list(obj.users_collection):
        old.objects.unlink(obj)
    col.objects.link(obj)


def mat_principled(name, base, metallic=0.0, roughness=0.45, emission=None, strength=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*base, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if emission:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = strength
    return mat


def mat_noise(name, dark, light, metallic=0.0, roughness=0.45, scale=6.0, detail=5.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    tex = nodes.new("ShaderNodeTexNoise")
    tex.inputs["Scale"].default_value = scale
    tex.inputs["Detail"].default_value = detail
    tex.inputs["Roughness"].default_value = 0.7
    ramp = nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.elements[0].color = (*dark, 1.0)
    ramp.color_ramp.elements[1].color = (*light, 1.0)
    links.new(tex.outputs["Fac"], ramp.inputs["Fac"])
    links.new(ramp.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    return mat


MAT = {}


def build_materials():
    MAT["brick"] = mat_noise("M_Brick_Graphite", (0.018, 0.024, 0.032), (0.07, 0.085, 0.105), 0.05, 0.48, 8.0, 7.0)
    MAT["brick_alt"] = mat_noise("M_Brick_Alternate", (0.025, 0.024, 0.028), (0.095, 0.07, 0.065), 0.05, 0.52, 7.0, 6.0)
    MAT["mortar"] = mat_principled("M_Mortar", (0.008, 0.011, 0.015), 0.0, 0.72)
    MAT["black_metal"] = mat_noise("M_Blackened_Metal", (0.008, 0.013, 0.02), (0.035, 0.055, 0.075), 0.82, 0.28, 5.0, 5.0)
    MAT["steel"] = mat_principled("M_Edge_Steel", (0.055, 0.075, 0.09), 0.9, 0.22)
    MAT["copper"] = mat_noise("M_Aged_Copper", (0.09, 0.025, 0.012), (0.35, 0.12, 0.035), 0.78, 0.32, 4.0, 5.0)
    MAT["glass"] = mat_noise("M_Rain_Glass", (0.002, 0.018, 0.035), (0.008, 0.08, 0.13), 0.2, 0.14, 10.0, 6.0)
    MAT["cyan"] = mat_principled("M_Cyan_Emission", (0.0, 0.055, 0.085), 0.15, 0.25, (0.0, 0.55, 0.9), 4.5)
    MAT["magenta"] = mat_principled("M_Magenta_Emission", (0.075, 0.0, 0.04), 0.1, 0.25, (0.85, 0.0, 0.38), 4.5)
    MAT["amber"] = mat_principled("M_Amber_Emission", (0.09, 0.032, 0.002), 0.1, 0.3, (0.95, 0.24, 0.018), 3.5)
    MAT["wet"] = mat_noise("M_Wet_Roof_Concrete", (0.008, 0.012, 0.018), (0.035, 0.045, 0.055), 0.12, 0.18, 4.0, 8.0)
    MAT["sidewalk"] = mat_noise("M_Rain_Wet_Sidewalk", (0.02, 0.025, 0.03), (0.11, 0.095, 0.085), 0.08, 0.25, 4.0, 7.0)
    MAT["water"] = mat_principled("M_Pooled_Water", (0.002, 0.018, 0.025), 0.55, 0.05)
    MAT["dark"] = mat_principled("M_Deep_Recess", (0.0015, 0.002, 0.004), 0.15, 0.7)


def add_box(name, loc, dims, material, col, bevel=0.0):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dims
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if material:
        obj.data.materials.append(material)
    if bevel > 0.0:
        mod = obj.modifiers.new("Edge_Bevel", "BEVEL")
        mod.width = bevel
        mod.segments = 2
    move_to_collection(obj, col)
    return obj


def add_flat_polygon(name, points, z, material, col):
    verts = [(x, y, z) for x, y in points]
    mesh = bpy.data.meshes.new(name + "_Mesh")
    mesh.from_pydata(verts, [], [list(range(len(verts)))])
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    if material:
        obj.data.materials.append(material)
    col.objects.link(obj)
    return obj


def add_cylinder(name, loc, radius, depth, material, col, rotation=(0, 0, 0), vertices=24):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    if material:
        obj.data.materials.append(material)
    move_to_collection(obj, col)
    return obj


def add_pipe_front(name, x1, x2, y, z, radius, col, material=None):
    return add_cylinder(name, ((x1+x2)/2, y, z), radius, abs(x2-x1), material or MAT["copper"], col, rotation=(0, math.radians(90), 0))


def add_pipe_vertical(name, x, y, z1, z2, radius, col, material=None):
    return add_cylinder(name, (x, y, (z1+z2)/2), radius, abs(z2-z1), material or MAT["copper"], col)


def add_light(name, loc, color, energy, radius, col):
    data = bpy.data.lights.new(name + "_Data", type="POINT")
    data.color = color
    data.energy = energy
    data.shadow_soft_size = radius
    obj = bpy.data.objects.new(name, data)
    obj.location = loc
    col.objects.link(obj)
    return obj


def add_area(name, loc, color, energy, size, col, target):
    data = bpy.data.lights.new(name + "_Data", type="AREA")
    data.color = color
    data.energy = energy
    data.shape = "DISK"
    data.size = size
    obj = bpy.data.objects.new(name, data)
    obj.location = loc
    direction = Vector(target) - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
    col.objects.link(obj)
    return obj


def add_brick_front(col, x0, width, z0, height, y=-0.09, prefix="BrickFront"):
    bw, bh = 0.46, 0.205
    rows = int(height / bh) + 1
    for row in range(rows):
        z = z0 + row * bh + bh * 0.45
        if z > z0 + height:
            continue
        offset = -bw * 0.5 if row % 2 else 0.0
        count = int(width / bw) + 3
        for c in range(count):
            x = x0 + offset + c * bw + bw * 0.5
            if x < x0 - 0.05 or x > x0 + width + 0.05:
                continue
            mat = MAT["brick_alt"] if (row + c) % 7 == 0 else MAT["brick"]
            add_box(f"{prefix}_{row:02d}_{c:02d}", (x, y, z), (bw-0.018, 0.15, bh-0.018), mat, col, 0.018)


def add_brick_side(col, y0, depth, z0, height, x=8.09, prefix="BrickSide"):
    bw, bh = 0.46, 0.205
    rows = int(height / bh) + 1
    for row in range(rows):
        z = z0 + row * bh + bh * 0.45
        if z > z0 + height:
            continue
        offset = -bw * 0.5 if row % 2 else 0.0
        count = int(depth / bw) + 3
        for c in range(count):
            y = y0 + offset + c * bw + bw * 0.5
            if y < y0 - 0.05 or y > y0 + depth + 0.05:
                continue
            mat = MAT["brick_alt"] if (row + c) % 7 == 0 else MAT["brick"]
            add_box(f"{prefix}_{row:02d}_{c:02d}", (x, y, z), (0.15, bw-0.018, bh-0.018), mat, col, 0.018)


def front_window(col, cx, base_z, width=1.45, height=0.88, neon="cyan", prefix="Window"):
    y = -0.205
    add_box(prefix+"_Glass", (cx, y-0.015, base_z+height/2), (width, 0.09, height), MAT["glass"], col, 0.025)
    frame = 0.075
    add_box(prefix+"_Top", (cx, y-0.08, base_z+height+frame/2), (width+0.24, 0.11, frame), MAT["black_metal"], col, 0.025)
    add_box(prefix+"_Bottom", (cx, y-0.08, base_z-frame/2), (width+0.24, 0.11, frame), MAT["black_metal"], col, 0.025)
    add_box(prefix+"_Left", (cx-width/2-frame/2, y-0.08, base_z+height/2), (frame, 0.11, height+0.15), MAT["black_metal"], col, 0.025)
    add_box(prefix+"_Right", (cx+width/2+frame/2, y-0.08, base_z+height/2), (frame, 0.11, height+0.15), MAT["black_metal"], col, 0.025)
    add_box(prefix+"_Center", (cx, y-0.1, base_z+height/2), (0.055, 0.13, height), MAT["steel"], col, 0.015)
    add_box(prefix+"_Neon", (cx, y-0.18, base_z+height+0.145), (width*0.8, 0.055, 0.055), MAT[neon], col, 0.022)


def side_window(col, cy, base_z, width=1.45, height=0.88, neon="cyan", prefix="SideWindow"):
    x = 8.205
    add_box(prefix+"_Glass", (x+0.015, cy, base_z+height/2), (0.09, width, height), MAT["glass"], col, 0.025)
    frame = 0.075
    add_box(prefix+"_Top", (x+0.08, cy, base_z+height+frame/2), (0.11, width+0.24, frame), MAT["black_metal"], col, 0.025)
    add_box(prefix+"_Bottom", (x+0.08, cy, base_z-frame/2), (0.11, width+0.24, frame), MAT["black_metal"], col, 0.025)
    add_box(prefix+"_Near", (x+0.08, cy-width/2-frame/2, base_z+height/2), (0.11, frame, height+0.15), MAT["black_metal"], col, 0.025)
    add_box(prefix+"_Far", (x+0.08, cy+width/2+frame/2, base_z+height/2), (0.11, frame, height+0.15), MAT["black_metal"], col, 0.025)
    add_box(prefix+"_Center", (x+0.1, cy, base_z+height/2), (0.13, 0.055, height), MAT["steel"], col, 0.015)
    add_box(prefix+"_Neon", (x+0.18, cy, base_z+height+0.145), (0.055, width*0.8, 0.055), MAT[neon], col, 0.022)


def front_door(col, cx, prefix="Door"):
    y = -0.25
    add_box(prefix+"_Recess", (cx, y+0.06, 0.62), (0.9, 0.11, 1.24), MAT["dark"], col, 0.02)
    add_box(prefix+"_Slab", (cx, y-0.03, 0.62), (0.72, 0.12, 1.16), MAT["black_metal"], col, 0.04)
    add_box(prefix+"_FrameL", (cx-0.46, y-0.04, 0.63), (0.11, 0.14, 1.36), MAT["steel"], col, 0.025)
    add_box(prefix+"_FrameR", (cx+0.46, y-0.04, 0.63), (0.11, 0.14, 1.36), MAT["steel"], col, 0.025)
    add_box(prefix+"_FrameT", (cx, y-0.04, 1.31), (1.02, 0.14, 0.11), MAT["steel"], col, 0.025)
    add_box(prefix+"_Slot", (cx, y-0.11, 0.78), (0.12, 0.05, 0.31), MAT["amber"], col, 0.025)
    add_box(prefix+"_Keypad", (cx+0.56, y-0.12, 0.58), (0.15, 0.07, 0.31), MAT["black_metal"], col, 0.025)
    add_box(prefix+"_KeypadLight", (cx+0.56, y-0.17, 0.66), (0.075, 0.03, 0.075), MAT["cyan"], col, 0.02)


def utility_front(col, cx, prefix="Utility"):
    y = -0.26
    add_box(prefix+"_Box", (cx, y, 0.55), (0.58, 0.24, 0.88), MAT["black_metal"], col, 0.035)
    add_box(prefix+"_Panel", (cx, y-0.14, 0.58), (0.42, 0.055, 0.54), MAT["steel"], col, 0.018)
    add_box(prefix+"_Warning", (cx, y-0.18, 0.66), (0.18, 0.025, 0.16), MAT["amber"], col, 0.018)
    add_box(prefix+"_Neon", (cx, y-0.16, 1.17), (0.82, 0.045, 0.055), MAT["magenta"], col, 0.02)


def build_front_module(kind, col):
    add_box(kind+"_Backing", (1.0, 0.0, 0.7), (2.0, 0.18, 1.4), MAT["mortar"], col)
    add_brick_front(col, 0.0, 2.0, 0.0, 1.4, prefix=kind+"_Brick")
    add_box(kind+"_Base", (1.0, -0.15, 0.09), (2.05, 0.2, 0.18), MAT["black_metal"], col, 0.025)
    add_box(kind+"_Cornice", (1.0, -0.15, 1.35), (2.05, 0.2, 0.13), MAT["steel"], col, 0.025)
    if kind == "FrontWindow":
        front_window(col, 1.0, 0.31, prefix=kind)
    elif kind == "FrontDoor":
        front_door(col, 1.0, prefix=kind)
    elif kind == "FrontUtility":
        utility_front(col, 1.0, prefix=kind)
        add_pipe_front(kind+"_Pipe", 0.08, 1.72, -0.27, 0.28, 0.035, col)
    else:
        add_pipe_front(kind+"_PipeA", 0.1, 1.9, -0.24, 0.46, 0.028, col, MAT["steel"])
        add_pipe_front(kind+"_PipeB", 0.1, 1.9, -0.24, 0.33, 0.025, col, MAT["copper"])


def build_side_module(kind, col):
    add_box(kind+"_Backing", (0.0, 1.0, 0.7), (0.18, 2.0, 1.4), MAT["mortar"], col)
    # Local side module uses x=0 surface; temporarily build hand-laid panels.
    bw, bh = 0.46, 0.205
    for row in range(7):
        offset = -bw * 0.5 if row % 2 else 0.0
        for c in range(6):
            y = offset + c*bw + bw/2
            if -0.05 <= y <= 2.05:
                mat = MAT["brick_alt"] if (row+c)%7==0 else MAT["brick"]
                add_box(f"{kind}_Brick_{row}_{c}", (-0.09, y, row*bh+bh*0.45), (0.15, bw-0.018, bh-0.018), mat, col, 0.018)
    add_box(kind+"_Base", (-0.15, 1.0, 0.09), (0.2, 2.05, 0.18), MAT["black_metal"], col, 0.025)
    add_box(kind+"_Cornice", (-0.15, 1.0, 1.35), (0.2, 2.05, 0.13), MAT["steel"], col, 0.025)
    if kind == "SideWindow":
        # Equivalent to side_window, but local surface at x=0.
        x = -0.205
        cy, base_z, width, height = 1.0, 0.31, 1.45, 0.88
        add_box(kind+"_Glass", (x-0.015, cy, base_z+height/2), (0.09, width, height), MAT["glass"], col, 0.025)
        add_box(kind+"_Top", (x-0.08, cy, base_z+height+0.0375), (0.11, width+0.24, 0.075), MAT["black_metal"], col, 0.025)
        add_box(kind+"_Bottom", (x-0.08, cy, base_z-0.0375), (0.11, width+0.24, 0.075), MAT["black_metal"], col, 0.025)
        add_box(kind+"_Near", (x-0.08, cy-width/2-0.0375, base_z+height/2), (0.11, 0.075, height+0.15), MAT["black_metal"], col, 0.025)
        add_box(kind+"_Far", (x-0.08, cy+width/2+0.0375, base_z+height/2), (0.11, 0.075, height+0.15), MAT["black_metal"], col, 0.025)
        add_box(kind+"_Center", (x-0.1, cy, base_z+height/2), (0.13, 0.055, height), MAT["steel"], col, 0.015)
        add_box(kind+"_Neon", (x-0.18, cy, base_z+height+0.145), (0.055, width*0.8, 0.055), MAT["cyan"], col, 0.022)
    else:
        add_cylinder(kind+"_Pipe", (-0.24, 1.0, 0.43), 0.03, 1.8, MAT["copper"], col, rotation=(math.radians(90),0,0))


def build_roof_macro(col):
    add_box("RoofMacro_Base", (4.0, 3.0, 0.03), (8.0, 6.0, 0.16), MAT["wet"], col, 0.04)
    # One restrained drainage run; no checkerboard or large cross pattern.
    add_box("RoofMacro_DrainRun", (5.55, 3.0, 0.125), (0.018, 5.4, 0.012), MAT["dark"], col, 0.004)
    # continuous parapet blocks
    add_box("RoofMacro_ParapetFront", (4.0, -0.02, 0.24), (8.25, 0.28, 0.48), MAT["brick"], col, 0.045)
    add_box("RoofMacro_ParapetBack", (4.0, 6.02, 0.24), (8.25, 0.28, 0.48), MAT["brick"], col, 0.045)
    add_box("RoofMacro_ParapetLeft", (-0.02, 3.0, 0.24), (0.28, 6.25, 0.48), MAT["brick"], col, 0.045)
    add_box("RoofMacro_ParapetRight", (8.02, 3.0, 0.24), (0.28, 6.25, 0.48), MAT["brick"], col, 0.045)
    add_box("RoofMacro_VentBase", (1.55, 4.4, 0.23), (1.35, 0.85, 0.42), MAT["black_metal"], col, 0.05)
    add_box("RoofMacro_VentTop", (1.55, 4.4, 0.48), (1.5, 1.0, 0.12), MAT["steel"], col, 0.04)


def build_foundation_macro(col):
    add_box("FoundationMacro_Slab", (4.0, 3.0, 0.0), (9.2, 7.2, 0.22), MAT["sidewalk"], col, 0.055)
    # perimeter curb strips only; no four-panel repetition
    add_box("FoundationMacro_CurbFront", (4.0, -0.62, 0.1), (9.35, 0.28, 0.34), MAT["steel"], col, 0.04)
    add_box("FoundationMacro_CurbRight", (8.62, 3.0, 0.1), (0.28, 7.35, 0.34), MAT["steel"], col, 0.04)


def build_full_assembly(col):
    # Sidewalk / wet apron
    add_box("Golden_Sidewalk", (4.0, 1.8, 0.0), (9.4, 8.2, 0.2), MAT["sidewalk"], col, 0.055)
    add_box("Golden_RoadLip", (4.0, -2.32, -0.02), (9.55, 0.28, 0.31), MAT["steel"], col, 0.045)
    # puddles and reflected pools, each supported by nearby light fixtures
    add_flat_polygon("Golden_Puddle_Cyan", [(3.55,-1.72),(4.2,-1.91),(5.12,-1.83),(5.92,-1.5),(5.7,-1.2),(4.85,-1.11),(4.05,-1.23)], 0.116, MAT["water"], col)
    add_flat_polygon("Golden_Puddle_Magenta", [(0.72,-1.26),(1.12,-1.46),(1.68,-1.42),(2.05,-1.13),(1.76,-0.91),(1.18,-0.94)], 0.117, MAT["water"], col)
    add_flat_polygon("Golden_Puddle_Amber", [(0.08,-2.0),(0.55,-2.12),(1.05,-2.02),(1.2,-1.78),(0.72,-1.62),(0.2,-1.7)], 0.116, MAT["water"], col)
    # Structural masonry on four sides so either calibration azimuth is truthful.
    add_box("Golden_FrontBacking", (4.0, 0.0, 1.5), (8.0, 0.2, 3.0), MAT["mortar"], col)
    add_box("Golden_BackBacking", (4.0, 6.0, 1.5), (8.0, 0.2, 3.0), MAT["brick"], col)
    add_box("Golden_LeftBacking", (0.0, 3.0, 1.5), (0.2, 6.0, 3.0), MAT["brick"], col)
    add_box("Golden_RightBacking", (8.0, 3.0, 1.5), (0.2, 6.0, 3.0), MAT["mortar"], col)
    add_brick_front(col, 0.0, 8.0, 0.0, 3.0, prefix="Golden_FrontBrick")
    add_brick_side(col, 0.0, 6.0, 0.0, 3.0, prefix="Golden_RightBrick")
    # Simple alternate-visible left side for current-angle calibration.
    for row in range(14):
        for c in range(14):
            y = c*0.46 + (0.23 if row%2 else 0.0)
            if y <= 6.0:
                add_box(f"Golden_LeftBrick_{row}_{c}", (-0.09, y, row*0.205+0.092), (0.15, 0.442, 0.187), MAT["brick"], col, 0.018)
    # Lower floor
    front_door(col, 1.05, "Golden_Door")
    front_window(col, 3.45, 0.31, width=1.7, height=0.9, neon="cyan", prefix="Golden_WindowLower")
    utility_front(col, 6.95, "Golden_Utility")
    # Upper floor
    front_window(col, 2.0, 1.76, width=1.6, height=0.86, neon="cyan", prefix="Golden_WindowUpperA")
    front_window(col, 5.65, 1.76, width=1.75, height=0.86, neon="cyan", prefix="Golden_WindowUpperB")
    # Right side windows and feature modules
    side_window(col, 1.55, 0.34, width=1.5, height=0.85, neon="magenta", prefix="Golden_SideWindowLow")
    side_window(col, 4.15, 1.78, width=1.45, height=0.84, neon="cyan", prefix="Golden_SideWindowHigh")
    # Cornices, strong silhouette and floor break
    add_box("Golden_FrontFloorCornice", (4.0, -0.18, 1.43), (8.18, 0.24, 0.18), MAT["steel"], col, 0.035)
    add_box("Golden_RightFloorCornice", (8.18, 3.0, 1.43), (0.24, 6.18, 0.18), MAT["steel"], col, 0.035)
    add_box("Golden_FrontBase", (4.0, -0.17, 0.11), (8.2, 0.24, 0.22), MAT["black_metal"], col, 0.035)
    add_box("Golden_RightBase", (8.17, 3.0, 0.11), (0.24, 6.2, 0.22), MAT["black_metal"], col, 0.035)
    # Exterior pipe language
    add_pipe_front("Golden_PipeLower", 0.4, 7.6, -0.26, 0.28, 0.045, col)
    add_pipe_front("Golden_PipeMid", 5.9, 7.7, -0.27, 0.62, 0.035, col, MAT["steel"])
    add_pipe_vertical("Golden_PipeDoor", 1.72, -0.27, 0.12, 1.35, 0.042, col)
    add_pipe_vertical("Golden_PipeUpper", 4.4, -0.27, 1.52, 2.92, 0.042, col)
    add_pipe_vertical("Golden_PipeCorner", 7.68, -0.27, 0.15, 2.92, 0.052, col)
    # Fire escape / balcony on right upper facade
    add_box("Golden_FireEscapeDeck", (6.55, -0.68, 1.55), (2.65, 1.15, 0.12), MAT["black_metal"], col, 0.025)
    for i in range(8):
        add_box(f"Golden_Grate_{i}", (5.35+i*0.34, -0.68, 1.62), (0.05, 1.02, 0.035), MAT["steel"], col, 0.008)
    for x in (5.25, 7.85):
        add_pipe_vertical(f"Golden_RailPost_{x}", x, -1.23, 1.58, 2.2, 0.025, col, MAT["steel"])
    add_pipe_front("Golden_RailTop", 5.25, 7.85, -1.23, 2.18, 0.025, col, MAT["steel"])
    add_pipe_front("Golden_RailMid", 5.25, 7.85, -1.23, 1.92, 0.02, col, MAT["steel"])
    for x in (5.5, 5.78):
        add_pipe_vertical(f"Golden_Ladder_{x}", x, -0.78, 0.15, 1.62, 0.025, col, MAT["steel"])
    for z in [0.3+i*0.18 for i in range(7)]:
        add_pipe_front(f"Golden_LadderRung_{z}", 5.48, 5.8, -0.78, z, 0.018, col, MAT["steel"])
    # Roof and parapet: continuous macro surface
    roof = make_collection("TEMP_RoofForGolden")
    build_roof_macro(roof)
    for obj in list(roof.objects):
        obj.location.z += 3.05
        move_to_collection(obj, col)
    bpy.data.collections.remove(roof)
    # Ward marking as geometry bars (not text dependency)
    for i, x in enumerate((6.65, 6.82, 6.99, 7.16)):
        add_box(f"Golden_WardMark_{i}", (x, -0.285, 0.87), (0.08, 0.025, 0.24 + (0.08 if i%2 else 0.0)), MAT["magenta"], col, 0.012)


def setup_scene():
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.image_settings.color_depth = "8"
    scene.render.resolution_percentage = 100
    scene.render.use_file_extension = True
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.look = "AgX - Medium High Contrast"
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.world.color = (0.003, 0.005, 0.009)
    scene["steamtek_projection"] = "true_2_to_1_dimetric"
    scene["steamtek_camera_elevation_deg"] = 30.0
    scene["steamtek_locked_azimuth"] = AZIMUTH_WEST_EAST
    scene["steamtek_pixels_per_vertical_bu"] = PPV


def make_camera(name, vector, target, ortho_scale, col):
    data = bpy.data.cameras.new(name+"_Data")
    data.type = "ORTHO"
    data.ortho_scale = ortho_scale
    data.lens = 50
    obj = bpy.data.objects.new(name, data)
    obj.location = Vector(target) + vector
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat("-Z", "Y").to_euler()
    col.objects.link(obj)
    return obj


def set_camera_target(camera, target, vector):
    camera.location = Vector(target) + vector
    camera.rotation_euler = (Vector(target) - camera.location).to_track_quat("-Z", "Y").to_euler()


def set_only_render(collection_names):
    allowed = set(collection_names)
    for col in bpy.data.collections:
        infrastructure = col.name in {"COLLECTION_RenderRig", "COLLECTION_Lights", "COLLECTION_Infrastructure"}
        col.hide_render = col.name not in allowed and not infrastructure


def render(scene, camera, path, width, height, target, vector):
    scene.camera = camera
    scene.render.resolution_x = width
    scene.render.resolution_y = height
    camera.data.ortho_scale = height / PPV
    set_camera_target(camera, target, vector)
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def root_offset(scene, camera, origin, width, height):
    coord = world_to_camera_view(scene, camera, Vector(origin))
    x = coord.x * width
    top_y = (1.0 - coord.y) * height
    return [round(width/2.0 - x, 3), round(height/2.0 - top_y, 3)]


reset_scene()
build_materials()
setup_scene()
scene = bpy.context.scene
infra = bpy.data.collections.get("COLLECTION_Infrastructure")
render_rig = make_collection("COLLECTION_RenderRig")
lights = make_collection("COLLECTION_Lights")
golden = make_collection("COLLECTION_GoldenApartmentExterior")
modules = {}
for name in ("FrontPlain", "FrontWindow", "FrontDoor", "FrontUtility", "SidePlain", "SideWindow"):
    modules[name] = make_collection("MODULE_"+name)
for name in ("RoofMacro", "FoundationMacro"):
    modules[name] = make_collection("MODULE_"+name)

for name in ("FrontPlain", "FrontWindow", "FrontDoor", "FrontUtility"):
    build_front_module(name, modules[name])
for name in ("SidePlain", "SideWindow"):
    build_side_module(name, modules[name])
build_roof_macro(modules["RoofMacro"])
build_foundation_macro(modules["FoundationMacro"])
build_full_assembly(golden)

# Camera and real scene lighting. Neon reflections in the golden render are supported by actual nearby lights.
camera_current = make_camera("Camera_Current_SouthWest", CAMERA_VECTOR_CURRENT, (4.0, 3.0, 1.7), 7.73, render_rig)
camera_west_east = make_camera("Camera_WestEast_Locked", CAMERA_VECTOR_WEST_EAST, (4.0, 2.2, 1.65), 7.73, render_rig)
add_area("Key_Warm", (2.0, -5.0, 8.5), (1.0, 0.42, 0.12), 720, 5.0, lights, (4.0, 1.5, 1.2))
add_area("Fill_Cool", (10.0, 1.0, 6.0), (0.05, 0.35, 1.0), 420, 4.0, lights, (4.0, 2.0, 1.3))
add_area("Rim_Magenta", (2.0, 7.5, 5.0), (0.9, 0.02, 0.35), 180, 3.5, lights, (4.0, 2.0, 1.5))
add_light("Door_Amber_Light", (1.05, -0.9, 1.25), (1.0, 0.28, 0.035), 95, 0.75, lights)
add_light("Window_Cyan_Light", (3.45, -0.9, 1.2), (0.0, 0.55, 1.0), 105, 0.9, lights)
add_light("Utility_Magenta_Light", (6.95, -0.9, 1.2), (1.0, 0.0, 0.45), 90, 0.85, lights)

# Save source before renders, then render the two camera candidates and the production golden assembly.
bpy.ops.wm.save_as_mainfile(filepath=BLEND_OUT)
set_only_render({golden.name})
render(scene, camera_current, os.path.join(CALIBRATION, "ApartmentExterior_CurrentAzimuth.png"), 3000, 2200, (4.0, 2.1, 1.65), CAMERA_VECTOR_CURRENT)
render(scene, camera_west_east, os.path.join(CALIBRATION, "ApartmentExterior_WestToEastCandidate.png"), 3000, 2200, (4.0, 2.1, 1.65), CAMERA_VECTOR_WEST_EAST)
render(scene, camera_west_east, os.path.join(PRODUCTION, "SMV3_B101_ApartmentExterior_Golden.png"), 3000, 2200, (4.0, 2.1, 1.65), CAMERA_VECTOR_WEST_EAST)

manifest = {
    "contract": {
        "projection": "true_2_to_1_dimetric",
        "camera_type": "ORTHOGRAPHIC",
        "elevation_degrees": 30.0,
        "locked_azimuth": AZIMUTH_WEST_EAST,
        "comparison_azimuth": AZIMUTH_CURRENT,
        "camera_forward_locked": [round(v, 6) for v in (Vector((4.0,2.1,1.65)) - (Vector((4.0,2.1,1.65))+CAMERA_VECTOR_WEST_EAST)).normalized()],
        "pixels_per_vertical_blender_unit": PPV,
        "projected_bay_step_front": [256, -128],
        "projected_bay_step_side": [-256, -128],
        "storey_rise": [0, -219],
        "source_character_visual": "res://assets/characters/player/Steamtek_C001/animations/walk/godot/Steamtek_C001_WalkVisual.tscn",
        "character_visual_scale": [0.73, 0.73],
        "character_visual_offset": [0, -110],
        "collision_footprint": [28, 18]
    },
    "modules": {},
    "golden": {
        "texture": "res://assets/modular_v2/apartment_exterior_v3/production/SMV3_B101_ApartmentExterior_Golden.png",
        "canvas": [3000, 2200],
        "root_offset": root_offset(scene, camera_west_east, (0.0, 0.0, 0.0), 3000, 2200)
    }
}

# Individual production module renders.
module_specs = {
    "FrontPlain": ((1.0, 0.0, 0.72), (0.0, 0.0, 0.0), [256, -128]),
    "FrontWindow": ((1.0, 0.0, 0.72), (0.0, 0.0, 0.0), [256, -128]),
    "FrontDoor": ((1.0, 0.0, 0.72), (0.0, 0.0, 0.0), [256, -128]),
    "FrontUtility": ((1.0, 0.0, 0.72), (0.0, 0.0, 0.0), [256, -128]),
    "SidePlain": ((0.0, 1.0, 0.72), (0.0, 0.0, 0.0), [-256, -128]),
    "SideWindow": ((0.0, 1.0, 0.72), (0.0, 0.0, 0.0), [-256, -128]),
    "RoofMacro": ((4.0, 3.0, 0.2), (0.0, 0.0, 0.0), None),
    "FoundationMacro": ((4.0, 3.0, 0.0), (0.0, 0.0, 0.0), None),
}
for name, (target, origin, step) in module_specs.items():
    col = modules[name]
    set_only_render({col.name})
    if name in ("RoofMacro", "FoundationMacro"):
        width, height = 2200, 1300
    else:
        width, height = 768, 768
    path = os.path.join(PRODUCTION, f"SMV3_{name}.png")
    render(scene, camera_west_east, path, width, height, target, CAMERA_VECTOR_WEST_EAST)
    manifest["modules"][name] = {
        "texture": "res://assets/modular_v2/apartment_exterior_v3/production/" + os.path.basename(path),
        "canvas": [width, height],
        "root_offset": root_offset(scene, camera_west_east, origin, width, height),
        "snap_step": step,
    }

with open(MANIFEST_OUT, "w", encoding="utf-8") as f:
    json.dump(manifest, f, indent=2)

# Restore the master to the complete golden-assembly view. Module collections remain
# available but hidden so opening the blend or pressing F12 cannot render overlapping assets.
for col in bpy.data.collections:
    col.hide_render = col.name.startswith("MODULE_")
    col.hide_viewport = col.name.startswith("MODULE_")
scene.camera = camera_west_east
scene.render.resolution_x = 3000
scene.render.resolution_y = 2200
scene.render.filepath = os.path.join(PRODUCTION, "SMV3_B101_ApartmentExterior_Golden.png")
camera_west_east.data.ortho_scale = 2200 / PPV
set_camera_target(camera_west_east, (4.0, 2.1, 1.65), CAMERA_VECTOR_WEST_EAST)
bpy.ops.wm.save_as_mainfile(filepath=BLEND_OUT)
print("STEAMTEK_APARTMENT_BUILD_COMPLETE")
print(BLEND_OUT)
print(MANIFEST_OUT)
