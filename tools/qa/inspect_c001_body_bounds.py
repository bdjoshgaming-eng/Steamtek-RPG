"""Report the current C001 render-mesh bounds for character scale matching."""

from pathlib import Path

import bpy
from mathutils import Vector


SOURCE = Path(
    r"C:\My Game\Steamtek-RPG\assets\characters\humanoid\base"
    r"\STK_C001_Protagonist\v01\STK_C001_Protagonist_RigAnim_v01.glb"
)

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(SOURCE))
body = bpy.data.objects["STK_C001_Protagonist_Body"]
corners = [body.matrix_world @ Vector(corner) for corner in body.bound_box]
minimum = [min(getattr(corner, axis) for corner in corners) for axis in "xyz"]
maximum = [max(getattr(corner, axis) for corner in corners) for axis in "xyz"]
size = [maximum[index] - minimum[index] for index in range(3)]
print(
    "STEAMTEK_C001_BODY_BOUNDS="
    + repr({"minimum": minimum, "maximum": maximum, "size": size})
)
