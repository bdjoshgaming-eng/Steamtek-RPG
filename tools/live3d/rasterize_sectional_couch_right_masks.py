#!/usr/bin/env python3
"""Create texture-aware recolor masks for the right-facing L4 sectional atlas."""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter


ROOT = Path(__file__).resolve().parents[2]
TEXTURES = ROOT / "incoming" / "meshy_apartment_assets" / "APT_Couch_L4_Right" / "staged_pipeline" / "textures"


def smoothstep(edge0: float, edge1: float, value: np.ndarray) -> np.ndarray:
    t = np.clip((value - edge0) / (edge1 - edge0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def save_mask(name: str, values: np.ndarray) -> None:
    image = Image.fromarray(np.clip(values * 255.0, 0.0, 255.0).astype(np.uint8), mode="L")
    image = image.filter(ImageFilter.GaussianBlur(radius=0.65))
    image.save(TEXTURES / name, optimize=True)
    pixels = np.asarray(image, dtype=np.float32)
    coverage = 100.0 * float(np.count_nonzero(pixels >= 16.0)) / values.size
    weighted = 100.0 * float(np.mean(pixels / 255.0))
    print(f"{name}: {coverage:.3f}% nonzero coverage, {weighted:.3f}% weighted coverage")


def main() -> None:
    base = np.asarray(
        Image.open(TEXTURES / "STK_PROP_Couch_L4_Right_ProductionCandidate_Baked_BaseColor.png").convert("RGB"),
        dtype=np.float32,
    )
    mr = np.asarray(
        Image.open(TEXTURES / "STK_PROP_Couch_L4_Right_ProductionCandidate_Baked_MetallicRoughness.png").convert("RGB"),
        dtype=np.float32,
    )
    r, g, b = base[..., 0], base[..., 1], base[..., 2]
    metallic = mr[..., 2]
    luma = 0.2126 * r + 0.7152 * g + 0.0722 * b
    saturation = np.maximum.reduce([r, g, b]) - np.minimum.reduce([r, g, b])

    # Burgundy leather is the only large warm-red region. Keep the baked grain and
    # cushion shading by using a soft tint mask rather than replacing the texture.
    red_dominance = r - np.maximum(g, b)
    leather = smoothstep(10.0, 42.0, red_dominance)
    leather *= smoothstep(14.0, 50.0, saturation)
    leather *= 1.0 - smoothstep(80.0, 145.0, metallic)
    leather *= smoothstep(28.0, 65.0, r)

    # The source bakes aged copper into narrow orange-brown trim pixels but does not
    # reliably flag those pixels as metallic. Select by warm hue and exclude leather.
    copper = smoothstep(6.0, 30.0, r - g)
    copper *= smoothstep(-2.0, 18.0, g - b)
    copper *= smoothstep(35.0, 90.0, r)
    copper *= smoothstep(12.0, 40.0, saturation)
    copper *= 1.0 - leather

    # The baked atlas compresses blue-black paint toward neutral charcoal. Use the
    # dark non-metal response while leaving bright wear and high-metal gunmetal in
    # the locked residual source material.
    visible_dark_surface = smoothstep(2.0, 20.0, luma) * (1.0 - smoothstep(115.0, 205.0, luma))
    painted_nonmetal = 1.0 - smoothstep(105.0, 180.0, metallic)
    frame = visible_dark_surface * painted_nonmetal
    frame *= (1.0 - leather) * (1.0 - copper)

    save_mask("MASK_CouchL4Right_CushionLeather.png", leather)
    save_mask("MASK_CouchL4Right_FramePaint.png", frame)
    save_mask("MASK_CouchL4Right_AccentMetal.png", copper)


if __name__ == "__main__":
    main()
