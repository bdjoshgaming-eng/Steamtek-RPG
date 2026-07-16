"""Build Vesper Kane Production Mesh v1 around the proven Steamtek rig.

This is a clean production branch.  The approved skeleton, actions, roots,
scale, ground contact, and physical-left mechanical arm are preserved while
the rig-fit blockout geometry is replaced by authored garment/body topology.
"""

from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector


CHARACTER_ID = "Steamtek_C001_VesperKane"
COLLECTION_NAME = "COLLECTION_VesperKane_ProductionMesh_v01"


def arguments():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    return parser.parse_args(argv)


def remove_old_character_meshes():
    for obj in list(bpy.data.objects):
        if obj.type == "MESH" and obj.name.startswith("VK_"):
            bpy.data.objects.remove(obj, do_unlink=True)
    for collection in list(bpy.data.collections):
        if collection.name.startswith("COLLECTION_VesperKane_"):
            bpy.data.collections.remove(collection)


def ensure_material(name, base, metallic, roughness, emission=None, emission_strength=0.0):
    mat = bpy.data.materials.get(name) or bpy.data.materials.new(name)
    mat.diffuse_color = (*base, 1.0)
    mat.metallic = metallic
    mat.roughness = roughness
    mat.use_nodes = True
    bsdf = next(node for node in mat.node_tree.nodes if node.type == "BSDF_PRINCIPLED")
    bsdf.inputs["Base Color"].default_value = (*base, 1.0)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    if emission is not None:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emission_strength
    mat["steamtek_runtime_lit"] = True
    mat["steamtek_baked_environment_color"] = False
    return mat


def bone_center(rig, name):
    bone = rig.data.bones[name]
    return (bone.head_local + bone.tail_local) * 0.5


def normalize_weights(weight_map):
    total = sum(max(0.0, value) for value in weight_map.values())
    if total <= 1e-8:
        return weight_map
    return {name: max(0.0, value) / total for name, value in weight_map.items() if value > 1e-6}


def finalize_mesh(obj, rig, root, collection, material, weight_maps, *, bevel=0.006, subdiv=0, smooth=True):
    obj.data.materials.append(material)
    for index, weights in enumerate(weight_maps):
        for bone_name, value in normalize_weights(weights).items():
            group = obj.vertex_groups.get(bone_name) or obj.vertex_groups.new(name=bone_name)
            group.add([index], value, "REPLACE")
    armature = obj.modifiers.new(name="Steamtek_HumanRig", type="ARMATURE")
    armature.object = rig
    armature.use_deform_preserve_volume = True
    if bevel > 0:
        modifier = obj.modifiers.new(name="ProductionEdgeSoftening", type="BEVEL")
        modifier.width = bevel
        modifier.segments = 2
        modifier.limit_method = "ANGLE"
    if subdiv > 0:
        modifier = obj.modifiers.new(name="ProductionSubdivision", type="SUBSURF")
        modifier.levels = subdiv
        modifier.render_levels = subdiv
    if smooth:
        for polygon in obj.data.polygons:
            polygon.use_smooth = True
    obj.parent = root
    obj["steamtek_character_id"] = CHARACTER_ID
    obj["steamtek_stage"] = "production_mesh_v01"
    if collection.objects.get(obj.name) is None:
        collection.objects.link(obj)
    for owner in list(obj.users_collection):
        if owner != collection:
            owner.objects.unlink(obj)
    # Generate usable UVs now, so the later PBR pass does not require a topology rebuild.
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    try:
        bpy.ops.object.mode_set(mode="EDIT")
        bpy.ops.mesh.select_all(action="SELECT")
        bpy.ops.uv.smart_project(angle_limit=math.radians(66.0), island_margin=0.02)
        bpy.ops.object.mode_set(mode="OBJECT")
    finally:
        obj.select_set(False)
    return obj


def mesh_object(name, verts, faces):
    mesh = bpy.data.meshes.new(f"{name}_Mesh")
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    return bpy.data.objects.new(name, mesh)


def loft(name, rings, segments=20, phase=math.pi / 20):
    """Elliptical authored loft. Rings: (z, x_radius, y_radius, y_center, weights)."""
    verts, faces, weights = [], [], []
    for z, radius_x, radius_y, center_y, ring_weights in rings:
        for index in range(segments):
            angle = phase + math.tau * index / segments
            verts.append((radius_x * math.cos(angle), center_y + radius_y * math.sin(angle), z))
            weights.append(dict(ring_weights))
    for ring in range(len(rings) - 1):
        start = ring * segments
        next_start = (ring + 1) * segments
        for index in range(segments):
            nxt = (index + 1) % segments
            faces.append((start + index, start + nxt, next_start + nxt, next_start + index))
    faces.append(tuple(reversed(range(segments))))
    top = (len(rings) - 1) * segments
    faces.append(tuple(top + i for i in range(segments)))
    return mesh_object(name, verts, faces), weights


def tube(name, points, radii, ring_bones, segments=14):
    """Create a continuous limb/sleeve tube along an arbitrary chain."""
    verts, faces, weights = [], [], []
    for index, point in enumerate(points):
        if index == 0:
            tangent = points[1] - point
        elif index == len(points) - 1:
            tangent = point - points[index - 1]
        else:
            tangent = points[index + 1] - points[index - 1]
        tangent.normalize()
        axis_y = Vector((0.0, 1.0, 0.0))
        axis_y = axis_y - tangent * tangent.dot(axis_y)
        if axis_y.length < 1e-5:
            axis_y = Vector((0.0, 0.0, 1.0))
        axis_y.normalize()
        axis_x = tangent.cross(axis_y).normalized()
        for segment in range(segments):
            angle = math.tau * segment / segments
            offset = axis_x * (math.cos(angle) * radii[index][0]) + axis_y * (math.sin(angle) * radii[index][1])
            verts.append(tuple(point + offset))
            weights.append(dict(ring_bones[index]))
    for ring in range(len(points) - 1):
        a, b = ring * segments, (ring + 1) * segments
        for segment in range(segments):
            nxt = (segment + 1) % segments
            faces.append((a + segment, a + nxt, b + nxt, b + segment))
    faces.append(tuple(reversed(range(segments))))
    end = (len(points) - 1) * segments
    faces.append(tuple(end + i for i in range(segments)))
    return mesh_object(name, verts, faces), weights


def panel(name, x0, x1, y_front, y_back, z_top, z_bottom, upper_bone, lower_bone, side_bias=0.0):
    """Subdivided coat panel with actual thickness and blended deformation."""
    rows, columns = 6, 5
    front_verts, weight_maps = [], []
    for row in range(rows):
        t = row / (rows - 1)
        z = z_top + (z_bottom - z_top) * t
        flare = 0.018 * t
        for col in range(columns):
            u = col / (columns - 1)
            x = (x0 - flare) * (1 - u) + (x1 + flare) * u + side_bias * t
            front_verts.append((x, y_front - 0.008 * t, z))
            weight_maps.append({upper_bone: 1.0 - t, lower_bone: t})
    verts = list(front_verts) + [(x, y_back + 0.008 * (i // columns) / (rows - 1), z) for i, (x, _, z) in enumerate(front_verts)]
    weights = weight_maps + [dict(w) for w in weight_maps]
    faces = []
    layer_size = rows * columns
    for layer in (0, layer_size):
        reverse = layer == layer_size
        for row in range(rows - 1):
            for col in range(columns - 1):
                a = layer + row * columns + col
                quad = (a, a + 1, a + columns + 1, a + columns)
                faces.append(tuple(reversed(quad)) if reverse else quad)
    boundary = []
    boundary += list(range(columns))
    boundary += [row * columns + columns - 1 for row in range(1, rows)]
    boundary += list(reversed(range((rows - 1) * columns, rows * columns - 1)))
    boundary += [row * columns for row in reversed(range(1, rows - 1))]
    for i, a in enumerate(boundary):
        b = boundary[(i + 1) % len(boundary)]
        faces.append((a, b, b + layer_size, a + layer_size))
    return mesh_object(name, verts, faces), weights


def rounded_box(name, location, scale, bone_name, bevel=0.012):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    weights = [{bone_name: 1.0} for _ in obj.data.vertices]
    return obj, weights, bevel


def shaped_head(name, center):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=4, radius=1.0, location=center)
    obj = bpy.context.object
    obj.name = name
    # Character-specific cranium/jaw shaping; front is -Y.
    for vertex in obj.data.vertices:
        local = vertex.co.copy()
        local.x *= 0.122
        local.y *= 0.112
        local.z *= 0.158
        if local.z < -0.025:
            factor = max(0.68, 1.0 + local.z * 2.1)
            local.x *= factor
            local.y *= 0.92
        if local.y < -0.04:
            local.y *= 1.06
        vertex.co = local
    return obj, [{"DEF-spine.006": 1.0} for _ in obj.data.vertices]


def shaped_ellipsoid(name, center, scale, bone_name, front_taper=0.0):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=3, radius=1.0, location=center)
    obj = bpy.context.object
    obj.name = name
    for vertex in obj.data.vertices:
        local = vertex.co.copy()
        local.x *= scale[0]
        local.y *= scale[1]
        local.z *= scale[2]
        if front_taper and local.y < 0:
            local.x *= 1.0 - front_taper * min(1.0, -local.y / max(scale[1], 1e-5))
        vertex.co = local
    return obj, [{bone_name: 1.0} for _ in obj.data.vertices]


def boot_mesh(name, center_x, bone_name):
    # Authored wedge profile: narrow heel, lowered toe, and an isometric-readable sole.
    x0, x1 = center_x - 0.082, center_x + 0.082
    y_back, y_front = 0.045, -0.225
    z_bottom, z_back_top, z_front_top = 0.018, 0.205, 0.125
    verts = [
        (x0, y_back, z_bottom), (x1, y_back, z_bottom),
        (x1, y_front, z_bottom), (x0, y_front, z_bottom),
        (x0, y_back, z_back_top), (x1, y_back, z_back_top),
        (x1, y_front, z_front_top), (x0, y_front, z_front_top),
    ]
    faces = [
        (0, 3, 2, 1), (4, 5, 6, 7),
        (0, 1, 5, 4), (1, 2, 6, 5),
        (2, 3, 7, 6), (3, 0, 4, 7),
    ]
    return mesh_object(name, verts, faces), [{bone_name: 1.0} for _ in verts]


def lapel_mesh(name, side, z_top, z_bottom):
    sign = 1.0 if side == "L" else -1.0
    inner_top, outer_top = 0.018 * sign, 0.155 * sign
    inner_bottom, outer_bottom = 0.055 * sign, 0.128 * sign
    y_front, y_back = -0.143, -0.128
    verts = [
        (inner_top, y_front, z_top), (outer_top, y_front, z_top - 0.025),
        (outer_bottom, y_front, z_bottom), (inner_bottom, y_front, z_bottom + 0.055),
        (inner_top, y_back, z_top), (outer_top, y_back, z_top - 0.025),
        (outer_bottom, y_back, z_bottom), (inner_bottom, y_back, z_bottom + 0.055),
    ]
    faces = [
        (0, 1, 2, 3), (7, 6, 5, 4),
        (0, 4, 5, 1), (1, 5, 6, 2),
        (2, 6, 7, 3), (3, 7, 4, 0),
    ]
    weights = [{"DEF-spine.003": 0.75, "DEF-spine.004": 0.25} for _ in verts]
    return mesh_object(name, verts, faces), weights


def cylinder_part(name, location, radius, depth, bone_name, vertices=24, taper=1.0):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices, radius1=radius, radius2=radius * taper, depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    return obj, [{bone_name: 1.0} for _ in obj.data.vertices]


def torus_part(name, location, major, minor, bone_name):
    bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=28, minor_segments=8, location=location)
    obj = bpy.context.object
    obj.name = name
    return obj, [{bone_name: 1.0} for _ in obj.data.vertices]


def chain(rig, names):
    points = [rig.data.bones[names[0]].head_local.copy()]
    points += [rig.data.bones[name].tail_local.copy() for name in names]
    maps = [{names[0]: 1.0}]
    for index, name in enumerate(names):
        if index + 1 < len(names):
            maps.append({name: 0.72, names[index + 1]: 0.28})
        else:
            maps.append({name: 1.0})
    return points, maps


def main():
    args = arguments()
    rig = bpy.data.objects.get("Armature")
    root = bpy.data.objects.get("ROOT_CharacterFacing")
    if not rig or not root:
        raise RuntimeError("The approved Steamtek humanoid rig is required")
    remove_old_character_meshes()
    collection = bpy.data.collections.new(COLLECTION_NAME)
    bpy.context.scene.collection.children.link(collection)

    coat = ensure_material("VK_PM01_Coat", (0.024, 0.030, 0.036), 0.02, 0.70)
    coat_edge = ensure_material("VK_PM01_CoatEdge", (0.055, 0.064, 0.072), 0.22, 0.48)
    leather = ensure_material("VK_PM01_Leather", (0.025, 0.021, 0.019), 0.04, 0.60)
    gunmetal = ensure_material("VK_PM01_Gunmetal", (0.065, 0.078, 0.088), 0.80, 0.33)
    dark_metal = ensure_material("VK_PM01_DarkMetal", (0.035, 0.043, 0.050), 0.72, 0.38)
    brass = ensure_material("VK_PM01_AgedBrass", (0.27, 0.105, 0.025), 0.72, 0.42)
    skin = ensure_material("VK_PM01_Skin", (0.30, 0.135, 0.072), 0.0, 0.58)
    rubber = ensure_material("VK_PM01_Rubber", (0.014, 0.019, 0.022), 0.05, 0.74)
    cyan = ensure_material("VK_PM01_DeviceCyan", (0.006, 0.085, 0.11), 0.25, 0.30, (0.02, 0.62, 0.80), 1.0)

    # Coherent upper garment, replacing the stack of spine cylinders/spheres.
    coat_rings = [
        (1.035, 0.178, 0.105, 0.025, {"DEF-spine": 0.8, "DEF-spine.001": 0.2}),
        (1.155, 0.205, 0.120, 0.020, {"DEF-spine.001": 0.85, "DEF-spine.002": 0.15}),
        (1.315, 0.220, 0.132, 0.010, {"DEF-spine.002": 0.75, "DEF-spine.003": 0.25}),
        (1.490, 0.242, 0.142, 0.006, {"DEF-spine.003": 0.85, "DEF-spine.004": 0.15}),
        (1.610, 0.238, 0.135, 0.005, {"DEF-spine.003": 0.40, "DEF-spine.004": 0.60}),
        (1.685, 0.150, 0.106, -0.006, {"DEF-spine.004": 0.45, "DEF-spine.005": 0.55}),
    ]
    obj, weights = loft("VK_PM01_CoatTorso", coat_rings, segments=24)
    finalize_mesh(obj, rig, root, collection, coat, weights, bevel=0.004, subdiv=1)
    for side in ("L", "R"):
        obj, weights = lapel_mesh(f"VK_PM01_CoatLapel_{side}", side, 1.635, 1.300)
        finalize_mesh(obj, rig, root, collection, coat_edge, weights, bevel=0.004, subdiv=1)

    # Undersuit/pelvis is a single fitted form beneath the garment.
    obj, weights = loft("VK_PM01_UndersuitPelvis", [
        (0.94, 0.158, 0.102, 0.026, {"DEF-spine": 0.4, "DEF-pelvis.L": 0.3, "DEF-pelvis.R": 0.3}),
        (1.04, 0.178, 0.110, 0.025, {"DEF-spine": 0.65, "DEF-pelvis.L": 0.175, "DEF-pelvis.R": 0.175}),
        (1.16, 0.170, 0.105, 0.018, {"DEF-spine.001": 1.0}),
    ], segments=20)
    finalize_mesh(obj, rig, root, collection, leather, weights, bevel=0.003, subdiv=1)

    # Four real coat panels provide slits and blended leg deformation.
    panels = (
        ("VK_PM01_CoatFront_L", 0.012, 0.205, -0.130, -0.098, "DEF-spine.001", "DEF-thigh.L", 0.018),
        ("VK_PM01_CoatFront_R", -0.205, -0.012, -0.130, -0.098, "DEF-spine.001", "DEF-thigh.R", -0.018),
        ("VK_PM01_CoatBack_L", 0.012, 0.212, 0.098, 0.132, "DEF-spine.001", "DEF-thigh.L", 0.020),
        ("VK_PM01_CoatBack_R", -0.212, -0.012, 0.098, 0.132, "DEF-spine.001", "DEF-thigh.R", -0.020),
    )
    for name, x0, x1, y_front, y_back, upper_bone, lower_bone, side_bias in panels:
        obj, weights = panel(
            name, x0, x1, y_front, y_back, 1.14, 0.62,
            upper_bone, lower_bone, side_bias,
        )
        finalize_mesh(obj, rig, root, collection, coat, weights, bevel=0.003, subdiv=1)

    # Human right sleeve is one continuous weighted garment tube.
    right_names = ["DEF-upper_arm.R", "DEF-upper_arm.R.001", "DEF-forearm.R", "DEF-forearm.R.001"]
    points, maps = chain(rig, right_names)
    radii = [(0.092, 0.085), (0.090, 0.083), (0.077, 0.070), (0.066, 0.060), (0.058, 0.052)]
    obj, weights = tube("VK_PM01_HumanSleeve_R", points, radii, maps, segments=16)
    finalize_mesh(obj, rig, root, collection, coat, weights, bevel=0.003, subdiv=1)

    # Trousers are coherent per-leg forms with knee/ankle tapering.
    for side in ("L", "R"):
        names = [f"DEF-thigh.{side}", f"DEF-thigh.{side}.001", f"DEF-shin.{side}", f"DEF-shin.{side}.001"]
        points, maps = chain(rig, names)
        radii = [(0.090, 0.078), (0.098, 0.082), (0.082, 0.072), (0.071, 0.064), (0.062, 0.056)]
        obj, weights = tube(f"VK_PM01_Trouser_{side}", points, radii, maps, segments=16)
        finalize_mesh(obj, rig, root, collection, leather, weights, bevel=0.002, subdiv=1)

    # Boots use one coherent foot volume per side, with no stacked sole primitives.
    for side, x in (("L", 0.098), ("R", -0.098)):
        obj, weights = boot_mesh(f"VK_PM01_Boot_{side}", x, f"DEF-foot.{side}")
        finalize_mesh(obj, rig, root, collection, dark_metal, weights, bevel=0.018, subdiv=0)
        obj, weights = torus_part(f"VK_PM01_AnkleSeal_{side}", Vector((x, -0.004, 0.285)), 0.070, 0.016, f"DEF-shin.{side}")
        obj.scale.y = 0.82
        finalize_mesh(obj, rig, root, collection, rubber, weights, bevel=0.002)

    # Character-specific head rather than the rig-fit review sphere.
    head_center = bone_center(rig, "DEF-spine.006") + Vector((0.0, -0.014, 0.040))
    obj, weights = shaped_head("VK_PM01_Head", head_center)
    finalize_mesh(obj, rig, root, collection, skin, weights, bevel=0.001, subdiv=1)
    obj, weights = torus_part("VK_PM01_HighCollar", head_center + Vector((0, 0.005, -0.165)), 0.135, 0.030, "DEF-spine.005")
    obj.scale.y = 0.82
    finalize_mesh(obj, rig, root, collection, coat_edge, weights, bevel=0.002)

    # Cleaner hat assembly.  It remains separate hard surface by design.
    obj, weights = cylinder_part("VK_PM01_HatBrim", head_center + Vector((0, 0, 0.178)), 0.202, 0.028, "DEF-spine.006", 36)
    obj.scale.y = 0.78
    finalize_mesh(obj, rig, root, collection, dark_metal, weights, bevel=0.008)
    obj, weights = cylinder_part("VK_PM01_HatCrown", head_center + Vector((0, 0.010, 0.330)), 0.145, 0.300, "DEF-spine.006", 32, taper=0.86)
    obj.scale.y = 0.90
    finalize_mesh(obj, rig, root, collection, coat, weights, bevel=0.008)
    obj, weights = torus_part("VK_PM01_HatBand", head_center + Vector((0, 0.010, 0.222)), 0.145, 0.017, "DEF-spine.006")
    obj.scale.y = 0.90
    finalize_mesh(obj, rig, root, collection, brass, weights, bevel=0.002)

    # Functional respirator and one restrained cyan status indicator.
    obj, weights, bevel = rounded_box("VK_PM01_Respirator", head_center + Vector((0, -0.112, -0.050)), (0.090, 0.022, 0.052), "DEF-spine.006", 0.014)
    finalize_mesh(obj, rig, root, collection, dark_metal, weights, bevel=bevel)
    obj, weights, bevel = rounded_box("VK_PM01_RespiratorStatus", head_center + Vector((0, -0.137, -0.048)), (0.008, 0.004, 0.020), "DEF-spine.006", 0.002)
    finalize_mesh(obj, rig, root, collection, cyan, weights, bevel=bevel)
    obj, weights = torus_part("VK_PM01_MonocleFrame", head_center + Vector((-0.054, -0.112, 0.030)), 0.034, 0.006, "DEF-spine.006")
    obj.rotation_euler.x = math.radians(90)
    finalize_mesh(obj, rig, root, collection, brass, weights, bevel=0.001)
    obj, weights = shaped_ellipsoid("VK_PM01_MonocleLens", head_center + Vector((-0.054, -0.119, 0.030)), (0.025, 0.006, 0.025), "DEF-spine.006")
    finalize_mesh(obj, rig, root, collection, cyan, weights, bevel=0.001)

    # Human right hand remains a compact glove silhouette at gameplay scale.
    hand_r = bone_center(rig, "DEF-hand.R")
    obj, weights = shaped_ellipsoid("VK_PM01_Glove_R", hand_r + Vector((0, -0.015, -0.010)), (0.070, 0.052, 0.082), "DEF-hand.R", front_taper=0.18)
    finalize_mesh(obj, rig, root, collection, leather, weights, bevel=0.002, subdiv=1)

    # Physical-left mechanical arm: intentionally modular hard surface, but with
    # coherent segments rather than dozens of decorative blocks.
    left_names = ["DEF-upper_arm.L", "DEF-upper_arm.L.001", "DEF-forearm.L", "DEF-forearm.L.001", "DEF-hand.L"]
    left_points, left_maps = chain(rig, left_names)
    left_radii = [(0.105, 0.095), (0.098, 0.090), (0.088, 0.080), (0.094, 0.080), (0.076, 0.066), (0.070, 0.060)]
    obj, weights = tube("VK_PM01_MechanicalArm_L", left_points, left_radii, left_maps, segments=12)
    finalize_mesh(obj, rig, root, collection, gunmetal, weights, bevel=0.006)
    for label, bone_name in (("Shoulder", "DEF-upper_arm.L"), ("Elbow", "DEF-forearm.L"), ("Wrist", "DEF-hand.L")):
        center = rig.data.bones[bone_name].head_local
        obj, weights = torus_part(f"VK_PM01_Mech{label}Ring_L", center, 0.083 if label != "Shoulder" else 0.102, 0.014, bone_name)
        obj.rotation_euler.y = math.radians(90)
        finalize_mesh(obj, rig, root, collection, brass, weights, bevel=0.002)
    forearm_l = bone_center(rig, "DEF-forearm.L")
    obj, weights, bevel = rounded_box("VK_PM01_PressureGauge_L", forearm_l + Vector((0, -0.098, 0.025)), (0.048, 0.018, 0.048), "DEF-forearm.L", 0.010)
    finalize_mesh(obj, rig, root, collection, brass, weights, bevel=bevel)
    obj, weights, bevel = rounded_box("VK_PM01_PressureGaugeStatus_L", forearm_l + Vector((0, -0.120, 0.025)), (0.018, 0.004, 0.011), "DEF-forearm.L", 0.002)
    finalize_mesh(obj, rig, root, collection, cyan, weights, bevel=bevel)

    # Waist construction and asymmetric equipment anchor.
    abdomen = bone_center(rig, "DEF-spine.001")
    obj, weights = torus_part("VK_PM01_WaistBelt", abdomen + Vector((0, 0, -0.060)), 0.190, 0.028, "DEF-spine.001")
    obj.scale.y = 0.66
    finalize_mesh(obj, rig, root, collection, leather, weights, bevel=0.003)
    obj, weights, bevel = rounded_box("VK_PM01_HipRig_R", abdomen + Vector((-0.235, 0.005, -0.105)), (0.052, 0.042, 0.095), "DEF-spine.001", 0.012)
    finalize_mesh(obj, rig, root, collection, gunmetal, weights, bevel=bevel)
    obj, weights, bevel = rounded_box("VK_PM01_BeltBuckle", abdomen + Vector((0, -0.132, -0.060)), (0.040, 0.010, 0.032), "DEF-spine.001", 0.006)
    finalize_mesh(obj, rig, root, collection, brass, weights, bevel=bevel)

    collection["steamtek_character_id"] = CHARACTER_ID
    collection["steamtek_stage"] = "production_mesh_v01_geometry_and_weights"
    collection["mechanical_arm_side"] = "physical_left"
    collection["source_rig_fit"] = "v07"
    collection["runtime_lighting_only"] = True
    collection["uv_ready"] = True
    collection["pbr_texture_stage"] = "pending_after_geometry_approval"
    bpy.context.scene["steamtek_character_status"] = "production_mesh_v01_ready_for_review"
    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = 25
    bpy.context.scene.frame_set(1)

    args.output.resolve().parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(args.output.resolve()), check_existing=False)
    meshes = [obj for obj in collection.objects if obj.type == "MESH"]
    print(f"VESPER_PRODUCTION_BLEND={args.output.resolve()}")
    print(f"VESPER_PRODUCTION_MESHES={len(meshes)}")
    print(f"VESPER_PRODUCTION_VERTICES={sum(len(obj.data.vertices) for obj in meshes)}")
    print("VESPER_MECHANICAL_ARM=physical_left")


if __name__ == "__main__":
    main()
