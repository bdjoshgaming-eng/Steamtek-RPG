"""Validate fixed-canvas Steamtek character render output."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("render_root", type=Path)
    parser.add_argument("pipeline_manifest", type=Path)
    parser.add_argument("--production", action="store_true")
    args = parser.parse_args()
    manifest_name = "production_manifest.json" if args.production else "render_manifest.json"
    render_manifest_path = args.render_root / manifest_name
    rendered = json.loads(render_manifest_path.read_text(encoding="utf-8"))
    contract = json.loads(args.pipeline_manifest.read_text(encoding="utf-8"))
    expected_size = (
        tuple(contract["godot"]["production_frame_size"])
        if args.production
        else (contract["render"]["width"], contract["render"]["height"])
    )
    expected_directions = [item["name"] for item in contract["directions"]]
    failures: list[str] = []
    baselines_by_direction: dict[str, list[int]] = {name: [] for name in expected_directions}

    if rendered.get("directions") != expected_directions:
        failures.append("direction order differs from the locked manifest")
    if rendered.get("mirrored") is not False:
        failures.append("render manifest does not explicitly prohibit mirrored output")
    expected_count = rendered.get("frames_per_direction", 0)
    contact = rendered.get("ground_contact_pixel")
    if not isinstance(contact, list) or len(contact) != 2:
        failures.append("render manifest is missing the projected fixed ground-contact root")
    elif not (0 <= contact[0] < expected_size[0] and 0 <= contact[1] < expected_size[1]):
        failures.append("projected ground-contact root is outside the fixed canvas")
    for direction in expected_directions:
        paths = [args.render_root / path for path in rendered.get("files", {}).get(direction, [])]
        if len(paths) != expected_count or expected_count < 1:
            failures.append(f"{direction}: incomplete frame set")
            continue
        for path in paths:
            if not path.exists():
                failures.append(f"missing frame: {path}")
                continue
            with Image.open(path) as image:
                rgba = image.convert("RGBA")
                if rgba.size != expected_size:
                    failures.append(f"{path.name}: {rgba.size} != {expected_size}")
                bounds = rgba.getchannel("A").getbbox()
                if bounds is None:
                    failures.append(f"{path.name}: empty alpha")
                else:
                    baselines_by_direction[direction].append(bounds[3] - 1)

    tolerance = contract["validation"]["maximum_baseline_variation_pixels"]
    static_animations = contract["validation"].get("static_baseline_animations", ["idle"])
    if rendered.get("animation") in static_animations:
        for direction, baselines in baselines_by_direction.items():
            if baselines and max(baselines) - min(baselines) > tolerance:
                failures.append(
                    f"{direction}: static alpha baseline varies by "
                    f"{max(baselines) - min(baselines)} px; allowed {tolerance} px"
                )
    if failures:
        raise SystemExit("STEAMTEK RENDER QA FAILED\n" + "\n".join(failures))
    print(
        f"STEAMTEK RENDER QA PASSED: {len(expected_directions)} genuine directions, "
        f"{expected_count} frames each, {expected_size[0]}x{expected_size[1]} fixed canvas"
    )


if __name__ == "__main__":
    main()
