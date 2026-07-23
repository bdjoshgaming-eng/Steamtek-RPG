from pathlib import Path
from PIL import Image, ImageChops


ROOT = Path(r"C:\My Game\Steamtek-RPG")
GENERATED = Path(r"C:\Users\bdjos\.codex\generated_images\019f8a34-de7f-7310-b112-3c2bc122523d")
OUT = ROOT / "assets" / "reference" / "meshy" / "STK_ENV_Street_Wall_1p2_A"

VIEWS = {
    "Front": ("exec-ef9d6000-1b1c-4ed6-af77-04f24dd9e7b1.png", (638, 1700)),
    "Back": ("exec-d34d47d0-bb10-40f3-b658-8ca49f9f8b8f.png", (638, 1700)),
    "Left": ("exec-178b153d-1c56-4796-936c-9598940c0adc.png", (85, 1700)),
    "Right": ("exec-df9ed106-7f01-400f-a8f3-6437cdb0c3ec.png", (85, 1700)),
    "Top": ("exec-cec71b2a-bf0b-4e65-896b-11f286d59886.png", (638, 85)),
}

CANVAS = (2048, 2048)
BACKGROUND = (228, 228, 228, 255)


def extract_object(source: Path) -> Image.Image:
    image = Image.open(source).convert("RGBA")
    rgb = image.convert("RGB")
    luminance = rgb.convert("L")
    # Generated backgrounds are very light and neutral; the wall is substantially
    # darker. This produces a soft matte that retains antialiased metal edges.
    alpha = luminance.point(lambda value: max(0, min(255, int((210 - value) * 8.5))))
    bbox = alpha.getbbox()
    if bbox is None:
        raise RuntimeError(f"No wall silhouette detected in {source}")
    padding = 6
    bbox = (
        max(0, bbox[0] - padding),
        max(0, bbox[1] - padding),
        min(image.width, bbox[2] + padding),
        min(image.height, bbox[3] + padding),
    )
    cropped = image.crop(bbox)
    cropped.putalpha(alpha.crop(bbox))
    return cropped


OUT.mkdir(parents=True, exist_ok=True)
for view, (filename, target_size) in VIEWS.items():
    wall = extract_object(GENERATED / filename)
    wall = wall.resize(target_size, Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", CANVAS, BACKGROUND)
    position = ((CANVAS[0] - target_size[0]) // 2, (CANVAS[1] - target_size[1]) // 2)
    canvas.alpha_composite(wall, position)
    final_path = OUT / f"STK_ENV_Street_Wall_1p2_A_{view}.png"
    canvas.convert("RGB").save(final_path, "PNG", optimize=True)
    print(f"{view}: {final_path} ({target_size[0]}x{target_size[1]} object on 2048x2048 canvas)")
