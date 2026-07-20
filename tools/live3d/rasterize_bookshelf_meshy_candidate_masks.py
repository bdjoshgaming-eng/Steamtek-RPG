#!/usr/bin/env python3
"""Rasterize the staged bookshelf UV region data into Godot-ready PNG masks."""

from __future__ import annotations

import json
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[2]
STAGE = ROOT / "incoming" / "meshy_apartment_assets" / "APT_Bookshelf_A" / "staged_pipeline"
TEXTURES = STAGE / "textures"
REGIONS = STAGE / "STK_PROP_Bookshelf_A_MaskRegions.json"


def remove_small_components(image: Image.Image, minimum_pixels: int) -> Image.Image:
    array = np.asarray(image) > 0
    remaining = {tuple(point) for point in np.argwhere(array)}
    kept: list[list[tuple[int, int]]] = []
    sizes: list[int] = []
    neighbors = ((-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1))
    while remaining:
        start = remaining.pop()
        component = [start]
        queue = deque([start])
        while queue:
            y, x = queue.popleft()
            for dy, dx in neighbors:
                neighbor = (y + dy, x + dx)
                if neighbor in remaining:
                    remaining.remove(neighbor)
                    component.append(neighbor)
                    queue.append(neighbor)
        sizes.append(len(component))
        if len(component) >= minimum_pixels:
            kept.append(component)
    cleaned = np.zeros(array.shape, dtype=np.uint8)
    for component in kept:
        ys, xs = zip(*component)
        cleaned[np.asarray(ys), np.asarray(xs)] = 255
    print(f"Emission component sizes (largest first): {sorted(sizes, reverse=True)[:12]}")
    print(f"Emission components kept: {len(kept)} / {len(sizes)} at >= {minimum_pixels} px")
    return Image.fromarray(cleaned, mode="L")


def main() -> None:
    data = json.loads(REGIONS.read_text(encoding="utf-8"))
    base = Image.open(TEXTURES / "STK_PROP_Bookshelf_A_ProductionCandidate_Baked_BaseColor.png").convert("RGB")
    mr = Image.open(TEXTURES / "STK_PROP_Bookshelf_A_ProductionCandidate_Baked_MetallicRoughness.png").convert("RGB")
    emit = Image.open(TEXTURES / "STK_PROP_Bookshelf_A_ProductionCandidate_Baked_Emit.png").convert("RGB")
    size = base.width

    def rasterize(region_name: str) -> Image.Image:
        image = Image.new("L", (size, size), 0)
        draw = ImageDraw.Draw(image)
        for polygon in data["regions"][region_name]:
            points = [(round(u * (size - 1)), round(v * (size - 1))) for u, v in polygon]
            draw.polygon(points, fill=255)
        return image

    region_frame = rasterize("frame")
    region_shelf = rasterize("shelf")

    # Protect high-metallic hardware and the powered accent from broad structural masks.
    hardware_guard = mr.getchannel("B").point(lambda p: 255 if p >= 118 else 0)
    hardware_guard = hardware_guard.filter(ImageFilter.MaxFilter(3))
    accent = emit.convert("L").point(lambda p: 255 if p >= 3 else 0)
    accent = accent.filter(ImageFilter.MaxFilter(3))
    accent = remove_small_components(accent, minimum_pixels=750)
    editable = ImageChops.invert(ImageChops.lighter(hardware_guard, accent))

    frame = ImageChops.multiply(region_frame, editable)
    shelf = ImageChops.subtract(ImageChops.multiply(region_shelf, editable), frame)
    outputs = {
        "MASK_Bookshelf_Meshy_FramePaint.png": frame,
        "MASK_Bookshelf_Meshy_ShelfPaint.png": shelf,
        "MASK_Bookshelf_Meshy_AccentPowered.png": accent,
    }
    pixels = size * size
    for name, image in outputs.items():
        image.save(TEXTURES / name, optimize=True)
        coverage = 100.0 * sum(image.histogram()[1:]) / pixels
        print(f"{name}: {coverage:.3f}% atlas coverage")
    print(f"Face classification: {data['faces']}")


if __name__ == "__main__":
    main()
