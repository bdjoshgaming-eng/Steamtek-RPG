import bpy
import json
import math
import os
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view


PROJECT = r"C:\My Game\Steamtek-RPG"
OUT_DIR = os.path.join(
    PROJECT,
    "assets",
    "modular_v2",
    "apartment_exterior_v3",
    "calibration",
    "off_axis_camera_gate",
)
MANIFEST = os.path.join(OUT_DIR, "Steamtek_OffAxis_CameraGate_Manifest.json")

PPV = 181.01933598375618
ELEVATION_DEGREES = 30.0
HORIZONTAL_RADIUS = math.sqrt(128.0)
TARGET = Vector((4.0, 2.1, 1.65))
RENDER_WIDTH = 3000
RENDER_HEIGHT = 2200
CANDIDATES = (45.0, 35.0, 30.0, 25.0)


def camera_vector(azimuth_degrees):
    angle = math.radians(azimuth_degrees)
    z = HORIZONTAL_RADIUS * math.tan(math.radians(ELEVATION_DEGREES))
    return Vector(
        (
            HORIZONTAL_RADIUS * math.cos(angle),
            -HORIZONTAL_RADIUS * math.sin(angle),
            z,
        )
    )


def ensure_camera(name):
    obj = bpy.data.objects.get(name)
    if obj and obj.type == "CAMERA":
        return obj
    data = bpy.data.cameras.new(name + "_Data")
    data.type = "ORTHO"
    obj = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def configure_camera(camera, vector):
    camera.location = TARGET + vector
    camera.rotation_euler = (TARGET - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = RENDER_HEIGHT / PPV


def show_only_golden():
    for collection in bpy.data.collections:
        infrastructure = collection.name in {
            "COLLECTION_RenderRig",
            "COLLECTION_Lights",
            "COLLECTION_Infrastructure",
        }
        collection.hide_render = (
            collection.name != "COLLECTION_GoldenApartmentExterior"
            and not infrastructure
        )


def screen_point(scene, camera, point):
    coord = world_to_camera_view(scene, camera, Vector(point))
    return Vector((coord.x * RENDER_WIDTH, (1.0 - coord.y) * RENDER_HEIGHT))


def projected_step(scene, camera, start, end):
    delta = screen_point(scene, camera, end) - screen_point(scene, camera, start)
    return [round(delta.x, 3), round(delta.y, 3)]


os.makedirs(OUT_DIR, exist_ok=True)
scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE_NEXT"
scene.render.film_transparent = True
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
scene.render.image_settings.color_depth = "8"
scene.render.resolution_percentage = 100
scene.render.resolution_x = RENDER_WIDTH
scene.render.resolution_y = RENDER_HEIGHT
scene.view_settings.look = "AgX - Medium High Contrast"
show_only_golden()

manifest = {
    "status": "camera_gate_only_not_locked",
    "camera_type": "ORTHOGRAPHIC",
    "elevation_degrees": ELEVATION_DEGREES,
    "camera_roll_degrees": 0.0,
    "render_size": [RENDER_WIDTH, RENDER_HEIGHT],
    "candidates": [],
}

for azimuth in CANDIDATES:
    suffix = str(int(azimuth))
    camera = ensure_camera("Camera_OffAxis_Azimuth" + suffix)
    vector = camera_vector(azimuth)
    configure_camera(camera, vector)
    scene.camera = camera
    output_path = os.path.join(
        OUT_DIR, f"ApartmentExterior_OffAxis_Azimuth{suffix}.png"
    )
    scene.render.filepath = output_path
    bpy.ops.render.render(write_still=True)

    front_step = projected_step(scene, camera, (0, 0, 0), (2, 0, 0))
    side_step = projected_step(scene, camera, (0, 0, 0), (0, 2, 0))
    vertical_step = projected_step(scene, camera, (0, 0, 0), (0, 0, 1))
    manifest["candidates"].append(
        {
            "azimuth_degrees": azimuth,
            "texture": "res://assets/modular_v2/apartment_exterior_v3/calibration/off_axis_camera_gate/"
            + os.path.basename(output_path),
            "camera_location_vector": [round(v, 6) for v in vector],
            "camera_forward": [round(v, 6) for v in (-vector).normalized()],
            "front_bay_step": front_step,
            "side_bay_step": side_step,
            "vertical_unit_step": vertical_step,
        }
    )

with open(MANIFEST, "w", encoding="utf-8") as handle:
    json.dump(manifest, handle, indent=2)

print("STEAMTEK_OFF_AXIS_CAMERA_GATE_COMPLETE")
print(MANIFEST)
