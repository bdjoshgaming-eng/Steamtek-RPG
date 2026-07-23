from pathlib import Path

import numpy as np
from PIL import Image, ImageEnhance, ImageFilter


ROOT = Path(r"C:\My Game\Steamtek-RPG")
SOURCE = ROOT / "assets" / "reference" / "meshy" / "STK_ENV_Street_Wall_1p2_A" / "STK_ENV_Street_Wall_1p2_A_Front.png"
OUT = ROOT / "assets" / "environment" / "live3d" / "textures" / "street_kit" / "STK_ENV_Street_Wall_1p2_A"
OUT.mkdir(parents=True, exist_ok=True)
rng = np.random.default_rng(120320)


def object_bbox(image: Image.Image) -> tuple[int, int, int, int]:
    arr = np.asarray(image.convert("RGB"), dtype=np.float32)
    lum = arr.mean(axis=2)
    ys, xs = np.where(lum < 185)
    return int(xs.min()), int(ys.min()), int(xs.max() + 1), int(ys.max() + 1)


def normal_from_height(height: np.ndarray, strength: float) -> Image.Image:
    gy, gx = np.gradient(height.astype(np.float32) / 255.0)
    nx = -gx * strength
    ny = -gy * strength
    nz = np.ones_like(nx)
    length = np.sqrt(nx * nx + ny * ny + nz * nz)
    normal = np.stack((nx / length, -ny / length, nz / length), axis=2)
    return Image.fromarray(((normal * 0.5 + 0.5) * 255.0).clip(0, 255).astype(np.uint8), "RGB")


def save_set(prefix: str, albedo: np.ndarray, height: np.ndarray, roughness: np.ndarray, ao: np.ndarray, normal_strength: float):
    Image.fromarray(np.clip(albedo, 0, 255).astype(np.uint8), "RGB").save(OUT / f"{prefix}_Albedo.png", optimize=True)
    normal_from_height(np.clip(height, 0, 255).astype(np.uint8), normal_strength).save(OUT / f"{prefix}_Normal.png", optimize=True)
    Image.fromarray(np.clip(roughness, 0, 255).astype(np.uint8), "L").save(OUT / f"{prefix}_Roughness.png", optimize=True)
    Image.fromarray(np.clip(ao, 0, 255).astype(np.uint8), "L").save(OUT / f"{prefix}_AO.png", optimize=True)


source = Image.open(SOURCE).convert("RGB")
left, top, right, bottom = object_bbox(source)
width, height = right - left, bottom - top
brick_box = (
    round(left + width * 0.12),
    round(top + height * 0.065),
    round(left + width * 0.88),
    round(top + height * 0.765),
)

# BRICK: preserve the approved authored brick pattern, darken it, add per-brick
# painterly variation, soot, vertical water staining, and lower-wall damp grime.
brick_source = source.crop(brick_box).resize((512, 1290), Image.Resampling.LANCZOS)
brick_source = ImageEnhance.Contrast(brick_source).enhance(1.13)
brick = np.asarray(brick_source, dtype=np.float32)
brick_lum = brick.mean(axis=2)
brick_mask = brick_lum > 30

variation = np.ones((1290, 512), dtype=np.float32)
row_height = 54
brick_width = 86
for row, y0 in enumerate(range(0, 1290, row_height)):
    offset = brick_width // 2 if row % 2 else 0
    for x0 in range(-offset, 512, brick_width):
        factor = rng.uniform(0.76, 1.05)
        variation[y0 : min(1290, y0 + row_height), max(0, x0) : min(512, x0 + brick_width)] = factor

# Low-frequency vertical streaks break broad uniformity without looking wet.
streak_seed = rng.random((1, 64)).astype(np.float32)
streaks = np.asarray(Image.fromarray((streak_seed * 255).astype(np.uint8), "L").resize((512, 1290), Image.Resampling.BICUBIC), dtype=np.float32) / 255.0
streaks = np.asarray(Image.fromarray((streaks * 255).astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(8.0)), dtype=np.float32) / 255.0
vertical_flow = np.linspace(0.92, 1.0, 1290, dtype=np.float32)[:, None]
stain_factor = 1.0 - np.clip((streaks - 0.58) * 0.28, 0, 0.10) * vertical_flow

bottom_gradient = np.clip((np.linspace(0, 1, 1290)[:, None] - 0.66) / 0.34, 0, 1)
bottom_grime = 1.0 - bottom_gradient * 0.24
top_soot = 1.0 - np.exp(-np.linspace(0, 7, 1290)[:, None]) * 0.10

# Final readability lift: raise ordinary brick midtones by 12.5% while the
# existing lower-wall damp/grime masks continue to hold the base dark.
brick *= 0.81
brick[brick_mask] *= variation[brick_mask][:, None]
brick *= stain_factor[..., None] * bottom_grime[..., None] * top_soot[..., None]

# Damp lower tint is restrained and remains matte, never glossy.
damp_tint = np.array([0.86, 0.94, 0.90], dtype=np.float32)
brick = brick * (1.0 - bottom_gradient[..., None] * 0.12) + brick * damp_tint * bottom_gradient[..., None] * 0.12

# Keep mortar dark but readable through contrast and normal depth.
mortar = ~brick_mask
brick[mortar] *= 0.68
brick = np.clip(brick, 4, 166)

height_source = np.asarray(brick_source.convert("L").filter(ImageFilter.GaussianBlur(0.55)), dtype=np.float32)
grain = rng.normal(0.0, 7.0, height_source.shape)
brick_roughness = np.clip(218 + grain + bottom_gradient * 10 - (height_source - 70) * 0.07, 188, 248)
brick_ao = np.clip(92 + height_source * 0.67 - bottom_gradient * 18, 78, 238)
brick_ao = np.asarray(Image.fromarray(brick_ao.astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(1.15)), dtype=np.float32)
save_set("STK_Wall_Brick", brick, height_source, brick_roughness, brick_ao, 7.4)

# STEEL: blackened gunmetal with directional brushing, subtle edge wear, and
# restrained rust concentrated around borders/seam-like regions and lower areas.
size = 512
small = rng.random((32, 32)).astype(np.float32)
large_noise = np.asarray(Image.fromarray((small * 255).astype(np.uint8), "L").resize((size, size), Image.Resampling.BICUBIC), dtype=np.float32) / 255.0
fine = rng.random((size, size)).astype(np.float32)
mottle = np.clip(0.68 * large_noise + 0.32 * fine, 0, 1)

yy, xx = np.mgrid[0:size, 0:size]
edge_distance = np.minimum.reduce((xx, yy, size - 1 - xx, size - 1 - yy)).astype(np.float32)
edge_wear = np.clip((14 - edge_distance) / 14, 0, 1)
lower_bias = (yy / (size - 1)) ** 2

steel = np.empty((size, size, 3), dtype=np.float32)
gunmetal = np.array([33.0, 41.0, 48.0], dtype=np.float32)
steel[:] = gunmetal + (mottle[..., None] - 0.5) * np.array([18.0, 20.0, 22.0])
steel += edge_wear[..., None] * np.array([22.0, 21.0, 18.0])

rust_seed = rng.random((size, size))
rust_mask = (rust_seed > (0.993 - edge_wear * 0.020 - lower_bias * 0.010)).astype(np.uint8) * 255
rust = np.asarray(Image.fromarray(rust_mask, "L").filter(ImageFilter.GaussianBlur(0.85)), dtype=np.float32) / 255.0
rust_color = np.array([83.0, 40.0, 20.0], dtype=np.float32)
steel = steel * (1.0 - rust[..., None] * 0.70) + rust_color * rust[..., None] * 0.70

# Sparse horizontal scratches and rubbed edges.
for _ in range(42):
    x = int(rng.integers(3, size - 8))
    y = int(rng.integers(0, size))
    length = int(rng.integers(8, 58))
    steel[y : min(size, y + 1), x : min(size, x + length)] += rng.uniform(12, 34)

steel = np.clip(steel, 7, 124)
steel_height = np.asarray(Image.fromarray(steel.astype(np.uint8), "RGB").convert("L").filter(ImageFilter.GaussianBlur(0.62)), dtype=np.float32)
steel_roughness = np.clip(190 + (1.0 - mottle) * 42 + rust * 22 - edge_wear * 10, 174, 244)
steel_ao = np.clip(232 - rust * 44 - lower_bias * 8, 174, 244)
save_set("STK_Wall_Steel", steel, steel_height, steel_roughness, steel_ao, 2.6)

# Maintenance panel: same gunmetal family, darker and dirtier around the two vent
# zones and along the lower seam. The geometry/placement remains unchanged.
panel = np.asarray(Image.fromarray(steel.astype(np.uint8), "RGB").resize((512, 256), Image.Resampling.BICUBIC), dtype=np.float32)
py, px = np.mgrid[0:256, 0:512]
vent_grime = np.zeros((256, 512), dtype=np.float32)
for center_x in (142, 370):
    distance = ((px - center_x) / 82) ** 2 + ((py - 128) / 80) ** 2
    vent_grime += np.exp(-distance * 2.2)
vent_grime = np.clip(vent_grime, 0, 1)
panel *= (1.0 - vent_grime[..., None] * 0.18)
panel *= (1.0 - (py / 255.0)[..., None] * 0.10)
panel_height = np.asarray(Image.fromarray(panel.astype(np.uint8), "RGB").convert("L"), dtype=np.float32)
panel_roughness = np.clip(204 + vent_grime * 18 + (py / 255.0) * 8, 190, 246)
panel_ao = np.clip(230 - vent_grime * 40 - (py / 255.0) * 10, 172, 240)
save_set("STK_Wall_Panel", panel, panel_height, panel_roughness, panel_ao, 2.4)

# Vent trim/louvers: slightly lighter worn gunmetal for readable depth against the
# dark recess, still matte and consistent with the frame.
vent_steel = np.clip(steel * 1.22 + edge_wear[..., None] * 6, 9, 142)
vent_height = np.asarray(Image.fromarray(vent_steel.astype(np.uint8), "RGB").convert("L"), dtype=np.float32)
vent_roughness = np.clip(184 + (1.0 - mottle) * 42 + rust * 16, 174, 235)
vent_ao = np.clip(236 - rust * 35, 188, 244)
save_set("STK_Wall_VentSteel", vent_steel, vent_height, vent_roughness, vent_ao, 2.3)

print(f"SOURCE_OBJECT_BOUNDS={left},{top},{right},{bottom}")
print(f"BRICK_CROP={brick_box}")
for path in sorted(OUT.glob("*.png")):
    with Image.open(path) as image:
        print(f"TEXTURE={path.name} {image.width}x{image.height}")
