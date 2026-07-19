"""Print a JSON summary of materials, textures, and node connections in a GLB."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import bpy


def main() -> None:
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    if len(argv) != 1:
        raise SystemExit("Usage: blender --background --python inspect_glb_materials.py -- <asset.glb>")

    source = Path(argv[0]).resolve()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(source))

    materials: list[dict] = []
    for material in bpy.data.materials:
        entry: dict = {
            "name": material.name,
            "blend_method": getattr(material, "surface_render_method", ""),
            "uses_nodes": material.use_nodes,
            "images": [],
            "links": [],
        }
        if material.use_nodes and material.node_tree:
            for node in material.node_tree.nodes:
                image = getattr(node, "image", None)
                if image:
                    entry["images"].append(
                        {
                            "node": node.name,
                            "image": image.name,
                            "size": [int(image.size[0]), int(image.size[1])],
                            "colorspace": image.colorspace_settings.name,
                            "packed": bool(image.packed_file),
                        }
                    )
            for link in material.node_tree.links:
                entry["links"].append(
                    {
                        "from_node": link.from_node.name,
                        "from_socket": link.from_socket.name,
                        "to_node": link.to_node.name,
                        "to_socket": link.to_socket.name,
                    }
                )
        materials.append(entry)

    print(json.dumps({"source": str(source), "materials": materials}, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
