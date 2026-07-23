"""Print every object datablock in the Blender file passed on the command line."""

import json

import bpy


print(
    "STEAMTEK_BLEND_DATABLOCKS="
    + json.dumps(
        [
            {
                "name": obj.name,
                "type": obj.type,
                "users": obj.users,
                "in_scene": obj.name in bpy.context.scene.objects,
            }
            for obj in bpy.data.objects
        ],
        indent=2,
    )
)
