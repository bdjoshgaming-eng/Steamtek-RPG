"""Authoritative Blender camera helper for Steamtek environment renders."""

import math
from mathutils import Vector


STEAMTEK_CAMERA_TYPE = "ORTHOGRAPHIC"
STEAMTEK_AZIMUTH_DEGREES = 60.0
STEAMTEK_ELEVATION_DEGREES = 30.0
STEAMTEK_CAMERA_ROLL_DEGREES = 0.0
STEAMTEK_HORIZONTAL_RADIUS = math.sqrt(128.0)
STEAMTEK_PIXELS_PER_VERTICAL_BU = 181.01933598375618
STEAMTEK_CAMERA_VECTOR = Vector(
    (
        STEAMTEK_HORIZONTAL_RADIUS
        * math.cos(math.radians(STEAMTEK_AZIMUTH_DEGREES)),
        -STEAMTEK_HORIZONTAL_RADIUS
        * math.sin(math.radians(STEAMTEK_AZIMUTH_DEGREES)),
        STEAMTEK_HORIZONTAL_RADIUS
        * math.tan(math.radians(STEAMTEK_ELEVATION_DEGREES)),
    )
)
STEAMTEK_CAMERA_FORWARD = (-STEAMTEK_CAMERA_VECTOR).normalized()
STEAMTEK_FRONT_BAY_STEP = Vector((313.534, -90.509))
STEAMTEK_SIDE_BAY_STEP = Vector((-181.020, -156.768))
STEAMTEK_STOREY_RISE = Vector((0.0, -219.0))


def configure_steamtek_camera(camera, target, render_height):
    """Apply the locked Steamtek 60°/30° orthographic camera contract."""
    target = Vector(target)
    camera.location = target + STEAMTEK_CAMERA_VECTOR
    camera.rotation_euler = (
        target - camera.location
    ).to_track_quat("-Z", "Y").to_euler()
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = (
        float(render_height) / STEAMTEK_PIXELS_PER_VERTICAL_BU
    )
    return camera

