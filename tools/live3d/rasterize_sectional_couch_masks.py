#!/usr/bin/env python3
"""Create texture-aware recolor masks for the one-material L4 sectional atlas."""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter


ROOT = Path(__file__).resolve().parents[2]
TEXTURES = ROOT / "incoming" / "meshy_apartment_assets" / "APT_Couch_L4_Left" / "staged_pipeline" / "textures"


def smoothstep(edge0: float, edge1: float, value: np.ndarray) -> np.ndarray:
    t = np.clip((value - edge0) / (edge1 - edge0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def save_mask(name: str, values: np.ndarray) -> None:
    image = Image.fromarray(np.clip(values * 255.0, 0.0, 255.0).astype(np.uint8), mode="L")
    image = image.filter(ImageFilter.GaussianBlur(radius=0.65))
    image.save(TEXTURES / name, optimize=True)
    coverage = 100.0 * float(np.count_nonzero(np.asarray(image) >= 16)) / values.size
    weighted = 100.0 * float(np.mean(np.asarray(image, dtype=np.float32) / 255.0))
    print(f"{name}: {coverage:.3f}% nonzero coverage, {weighted:.3f}% weighted coverage")


def main() -> None:
    base = np.asarray(
        Image.open(TEXTURES / "STK_PROP_Couch_L4_Left_ProductionCandidate_Baked_BaseColor.png").convert("RGB"),
        dtype=np.float32,
    )
    mr = np.asarray(
        Image.open(TEXTURES / "STK_PROP_Couch_L4_Left_ProductionCandidate_Baked_MetallicRoughness.png").convert("RGB"),
        dtype=np.float32,
    )
    r, g, b = base[..., 0], base[..., 1], base[..., 2]
    metallic = mr[..., 2]
    luma = 0.2126 * r + 0.7152 * g + 0.0722 * b
    saturation = np.maximum.reduce([r, g, b]) - np.minimum.reduce([r, g, b])

    red_dominance = r - np.maximum(g, b)
    leather = smoothstep(10.0, 42.0, red_dominance)
    leather *= smoothstep(14.0, 50.0, saturation)
    leather *= 1.0 - smoothstep(80.0, 145.0, metallic)
    leather *= smoothstep(28.0, 65.0, r)

    copper = smoothstep(8.0, 40.0, r - g)
    copper *= smoothstep(-2.0, 24.0, g - b)
    copper *= smoothstep(42.0, 105.0, r)
    copper *= smoothstep(28.0, 125.0, metallic)
    copper *= 1.0 - leather

    dark_surface = 1.0 - smoothstep(115.0, 205.0, luma)
    painted_nonmetal = 1.0 - smoothstep(105.0, 180.0, metallic)
    frame = dark_surface * painted_nonmetal * (1.0 - leather) * (1.0 - copper)
    # Keep very bright labels/highlights and high-metal structural gunmetal locked.
    frame *= 1.0 - smoothstep(155.0, 225.0, np.maximum.reduce([r, g, b]))

    save_mask("MASK_CouchL4_CushionLeather.png", leather)
    save_mask("MASK_CouchL4_FramePaint.png", frame)
    save_mask("MASK_CouchL4_AccentMetal.png", copper)


if __name__ == "__main__":
    main()
