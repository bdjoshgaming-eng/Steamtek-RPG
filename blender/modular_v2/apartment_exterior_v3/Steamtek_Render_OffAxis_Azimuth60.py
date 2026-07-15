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
OUTPUT_PATH = os.path.join(OUT_DIR, "ApartmentExterior_OffAxis_Azimuth60.png")
DATA_PATH = os.path.join(OUT_DIR, "ApartmentExterior_OffAxis_Azimuth60.json")

PPV = 181.01933598375618
ELEVATION_DEGREES = 30.0
AZIMUTH_DEGREES = 60.0
HORIZONTAL_RADIUS = math.sqrt(128.0)
TARGET = Vector((4.0, 2.1, 1.65))
RENDER_WIDTH = 3000
RENDER_HEIGHT = 2200


def screen_point(scene, camera, point):
    coord = world_to_camera_view(scene, camera, Vector(point))
    return Vector((coord.x * RENDER_WIDTH, (1.0 - coord.y) * RENDER_HEIGHT))


def projected_step(scene, camera, start, end):
    delta = screen_point(scene, camera, end) - screen_point(scene, camera, start)
    return [round(delta.x, 3), round(delta.y, 3)]


os.makedirs(OUT_DIR, exist_ok=True)
scene = bpy.context.scene

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

camera = bpy.data.objects.get("Camera_OffAxis_Azimuth60")
if camera is None or camera.type != "CAMERA":
    camera_data = bpy.data.cameras.new("Camera_OffAxis_Azimuth60_Data")
    camera_data.type = "ORTHO"
    camera = bpy.data.objects.new("Camera_OffAxis_Azimuth60", camera_data)
    scene.collection.objects.link(camera)

angle = math.radians(AZIMUTH_DEGREES)
height = HORIZONTAL_RADIUS * math.tan(math.radians(ELEVATION_DEGREES))
vector = Vector(
    (
        HORIZONTAL_RADIUS * math.cos(angle),
        -HORIZONTAL_RADIUS * math.sin(angle),
        height,
    )
)
camera.location = TARGET + vector
camera.rotation_euler = (TARGET - camera.location).to_track_quat("-Z", "Y").to_euler()
camera.data.type = "ORTHO"
camera.data.ortho_scale = RENDER_HEIGHT / PPV
scene.camera = camera

scene.render.engine = "BLENDER_EEVEE_NEXT"
scene.render.film_transparent = True
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
scene.render.image_settings.color_depth = "8"
scene.render.resolution_percentage = 100
scene.render.resolution_x = RENDER_WIDTH
scene.render.resolution_y = RENDER_HEIGHT
scene.view_settings.look = "AgX - Medium High Contrast"
scene.render.filepath = OUTPUT_PATH
bpy.ops.render.render(write_still=True)

data = {
    "status": "camera_gate_only_not_locked",
    "camera_type": "ORTHOGRAPHIC",
    "elevation_degrees": ELEVATION_DEGREES,
    "azimuth_degrees": AZIMUTH_DEGREES,
    "camera_roll_degrees": 0.0,
    "render_size": [RENDER_WIDTH, RENDER_HEIGHT],
    "texture": "res://assets/modular_v2/apartment_exterior_v3/calibration/off_axis_camera_gate/"
    + os.path.basename(OUTPUT_PATH),
    "camera_location_vector": [round(v, 6) for v in vector],
    "camera_forward": [round(v, 6) for v in (-vector).normalized()],
    "front_bay_step": projected_step(scene, camera, (0, 0, 0), (2, 0, 0)),
    "side_bay_step": projected_step(scene, camera, (0, 0, 0), (0, 2, 0)),
    "vertical_unit_step": projected_step(scene, camera, (0, 0, 0), (0, 0, 1)),
}

with open(DATA_PATH, "w", encoding="utf-8") as handle:
    json.dump(data, handle, indent=2)

print("STEAMTEK_OFF_AXIS_AZIMUTH60_COMPLETE")
print(OUTPUT_PATH)
print(DATA_PATH)
