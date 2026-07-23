"""Print the object inventory of the Blender file passed on the command line."""

import json

import bpy


print(
    "STEAMTEK_BLEND_OBJECTS="
    + json.dumps(
        [
            {
                "name": obj.name,
                "type": obj.type,
                "parent": obj.parent.name if obj.parent else "",
                "instance_type": obj.instance_type,
            }
            for obj in bpy.context.scene.objects
        ],
        indent=2,
    )
)
