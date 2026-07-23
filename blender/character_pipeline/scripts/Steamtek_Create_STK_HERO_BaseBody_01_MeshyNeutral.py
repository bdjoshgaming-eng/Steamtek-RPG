"""Create a texture-neutral Meshy rigging diagnostic from the approved GLB.

This rewrites only the GLB JSON material declaration. Mesh, skinless geometry,
indices, normals, UVs, and the binary buffer are preserved byte-for-byte.
"""

from __future__ import annotations

import hashlib
import json
import struct
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
SOURCE = (
    ROOT
    / "output"
    / "meshy_rig_input"
    / "STK_HERO_BaseBody_01_MeshyRigInput.glb"
)
OUTPUT = (
    ROOT
    / "output"
    / "meshy_rig_input"
    / "STK_HERO_BaseBody_01_MeshyRigInput_Neutral.glb"
)

GLB_MAGIC = 0x46546C67
JSON_CHUNK = 0x4E4F534A


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def read_glb(path: Path) -> tuple[int, list[tuple[int, bytes]]]:
    payload = path.read_bytes()
    magic, version, total_length = struct.unpack_from("<III", payload, 0)
    if magic != GLB_MAGIC or version != 2 or total_length != len(payload):
        raise RuntimeError(f"Not a valid GLB 2.0 file: {path}")

    chunks: list[tuple[int, bytes]] = []
    offset = 12
    while offset < len(payload):
        chunk_length, chunk_type = struct.unpack_from("<II", payload, offset)
        offset += 8
        chunk_data = payload[offset : offset + chunk_length]
        if len(chunk_data) != chunk_length:
            raise RuntimeError("Truncated GLB chunk")
        chunks.append((chunk_type, chunk_data))
        offset += chunk_length
    return version, chunks


def encode_json_chunk(document: dict) -> bytes:
    encoded = json.dumps(
        document, ensure_ascii=False, separators=(",", ":")
    ).encode("utf-8")
    return encoded + (b" " * ((-len(encoded)) % 4))


def write_glb(path: Path, version: int, chunks: list[tuple[int, bytes]]) -> None:
    body = bytearray()
    for chunk_type, chunk_data in chunks:
        if len(chunk_data) % 4:
            raise RuntimeError("GLB chunks must be 4-byte aligned")
        body += struct.pack("<II", len(chunk_data), chunk_type)
        body += chunk_data
    payload = struct.pack("<III", GLB_MAGIC, version, 12 + len(body)) + body
    path.write_bytes(payload)


def main() -> None:
    version, chunks = read_glb(SOURCE)
    if not chunks or chunks[0][0] != JSON_CHUNK:
        raise RuntimeError("GLB does not begin with a JSON chunk")

    document = json.loads(chunks[0][1].decode("utf-8").rstrip(" \t\r\n\0"))
    meshes = document.get("meshes", [])
    if len(meshes) != 1:
        raise RuntimeError(f"Expected one mesh, found {len(meshes)}")

    primitives = meshes[0].get("primitives", [])
    if len(primitives) != 1:
        raise RuntimeError(f"Expected one primitive, found {len(primitives)}")

    index_accessor = document["accessors"][primitives[0]["indices"]]
    triangle_count = index_accessor["count"] // 3
    if triangle_count != 31_138:
        raise RuntimeError(f"Unexpected triangle count: {triangle_count}")

    document["materials"] = [
        {
            "name": "STK_MAT_HERO_MeshyRigNeutral",
            "pbrMetallicRoughness": {
                "baseColorFactor": [0.6, 0.6, 0.6, 1.0],
                "metallicFactor": 0.0,
                "roughnessFactor": 0.8,
            },
        }
    ]
    primitives[0]["material"] = 0

    # No image is referenced by the diagnostic material. Removing these JSON
    # declarations prevents importers from treating the original atlas as an
    # input while leaving all geometry-related buffer views untouched.
    document.pop("images", None)
    document.pop("textures", None)
    document.pop("samplers", None)

    for key in ("extensionsUsed", "extensionsRequired"):
        extensions = [
            item
            for item in document.get(key, [])
            if item != "KHR_materials_specular"
        ]
        if extensions:
            document[key] = extensions
        else:
            document.pop(key, None)

    asset = document.setdefault("asset", {})
    asset["generator"] = "Steamtek Meshy neutral rig diagnostic"
    asset["extras"] = {
        "purpose": "Texture-neutral Meshy auto-rigging diagnostic",
        "sourceFile": SOURCE.name,
        "sourceSha256": sha256(SOURCE.read_bytes()),
        "geometryBinaryPreserved": True,
    }

    output_chunks = list(chunks)
    output_chunks[0] = (JSON_CHUNK, encode_json_chunk(document))
    write_glb(OUTPUT, version, output_chunks)

    _, verification_chunks = read_glb(OUTPUT)
    if len(verification_chunks) != len(chunks):
        raise RuntimeError("Output GLB chunk count changed")
    for index in range(1, len(chunks)):
        if chunks[index] != verification_chunks[index]:
            raise RuntimeError(f"Binary chunk {index} changed")

    print(f"OUTPUT={OUTPUT}")
    print(f"SOURCE_SHA256={sha256(SOURCE.read_bytes())}")
    print(f"OUTPUT_SHA256={sha256(OUTPUT.read_bytes())}")
    print(f"TRIANGLES={triangle_count}")
    print("GEOMETRY_BINARY_PRESERVED=true")


if __name__ == "__main__":
    main()
