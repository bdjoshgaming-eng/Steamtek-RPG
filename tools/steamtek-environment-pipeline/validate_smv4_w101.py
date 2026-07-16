"""Validate the first Steamtek high-fidelity environment module."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import bpy


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("--metadata", required=True)
    parser.add_argument("--image", required=True)
    parser.add_argument("--godot", required=True)
    argv = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else []
    return parser.parse_args(argv)


def close(a, b, tolerance=0.08):
    return abs(float(a) - float(b)) <= tolerance


def check(name, passed):
    print(("PASS " if passed else "FAIL ") + name)
    return bool(passed)


def main():
    args = parse_args()
    metadata = json.loads(Path(args.metadata).read_text(encoding="utf-8"))
    image_path = Path(args.image)
    godot_path = Path(args.godot)
    checks = []

    checks.append(check("module_id", metadata.get("module_id") == "SMV4_W101_FrontPlain"))
    checks.append(check("camera_profile", metadata.get("camera_profile") == "environment_fixed_off_axis_60_v2"))
    checks.append(check("transparent_contract", metadata.get("transparent") is True))

    front = metadata["measured_front_delta"]
    front_expected = metadata["contract_front_delta"]
    storey = metadata["measured_storey_delta"]
    storey_expected = metadata["contract_storey_delta"]
    checks.append(check("front_snap_delta", all(close(a, b) for a, b in zip(front, front_expected))))
    checks.append(check("storey_snap_delta", all(close(a, b) for a, b in zip(storey, storey_expected))))

    image = bpy.data.images.load(str(image_path), check_existing=False)
    checks.append(check("png_dimensions", list(image.size) == metadata["render_size"]))
    checks.append(check("png_has_alpha_channel", image.channels == 4))

    pixels = list(image.pixels)
    alpha = pixels[3::4]
    checks.append(check("alpha_contains_visible_pixels", max(alpha, default=0.0) > 0.95))
    checks.append(check("alpha_contains_transparency", min(alpha, default=1.0) < 0.01))

    width, height = image.size
    border_alpha = []
    for x in range(width):
        border_alpha.append(alpha[x])
        border_alpha.append(alpha[(height - 1) * width + x])
    for y in range(height):
        border_alpha.append(alpha[y * width])
        border_alpha.append(alpha[y * width + width - 1])
    checks.append(check("no_alpha_border_clipping", max(border_alpha, default=0.0) < 0.01))

    godot_text = godot_path.read_text(encoding="utf-8")
    checks.append(check("godot_scene_has_snap_markers", all(name in godot_text for name in ("Snap_Left", "Snap_Right", "Snap_TopLeft", "Snap_TopRight"))))
    checks.append(check("godot_root_scale_implicit_one", "scale =" not in godot_text))

    if not all(checks):
        raise SystemExit("STEAMTEK_W101_VALIDATION_FAILED")
    print("STEAMTEK_W101_VALIDATION_PASS")


if __name__ == "__main__":
    main()
