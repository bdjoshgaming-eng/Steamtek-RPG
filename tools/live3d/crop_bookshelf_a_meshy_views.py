#!/usr/bin/env python3
"""Create exact, non-generative Meshy upload views from the approved sheet."""

from pathlib import Path
from statistics import median

from PIL import Image, ImageFilter


ROOT = Path(__file__).resolve().parents[2]
SOURCE = (
    ROOT
    / "incoming"
    / "meshy_apartment_assets"
    / "APT_Bookshelf_A"
    / "true3d_candidate"
    / "STK_PROP_Bookshelf_A_ApprovedReferenceSheet.png"
)
OUTPUT_DIR = (
    ROOT
    / "incoming"
    / "meshy_apartment_assets"
    / "APT_Bookshelf_A"
    / "meshy_upload_views"
)

CANVAS_SIZE = 1024
TARGET_SPAN = 900

# Pixel crops exclude titles and the white panel separators. Each includes a
# narrow neutral-gray safety margin around the asset for feathered compositing.
VIEWS = {
    "Front": (16, 18, 392, 802),
    "Left": (436, 18, 653, 802),
    "Right": (692, 18, 914, 802),
    "Back": (949, 18, 1243, 802),
    "Top": (27, 902, 611, 1177),
}


def border_color(image: Image.Image) -> tuple[int, int, int]:
    pixels = []
    width, height = image.size
    border = max(4, min(width, height) // 30)
    for y in range(height):
        for x in range(width):
            if x < border or x >= width - border or y < border or y >= height - border:
                pixels.append(image.getpixel((x, y)))
    return tuple(int(median(channel)) for channel in zip(*pixels))


def feather_mask(size: tuple[int, int], feather: int = 18) -> Image.Image:
    width, height = size
    mask = Image.new("L", size, 255)
    px = mask.load()
    for y in range(height):
        for x in range(width):
            distance = min(x, y, width - 1 - x, height - 1 - y)
            if distance < feather:
                px[x, y] = int(255 * max(0.0, distance / feather))
    return mask.filter(ImageFilter.GaussianBlur(0.8))


def make_view(source: Image.Image, name: str, box: tuple[int, int, int, int]) -> Path:
    crop = source.crop(box).convert("RGB")
    width, height = crop.size
    scale = TARGET_SPAN / max(width, height)
    resized_size = (max(1, round(width * scale)), max(1, round(height * scale)))
    crop = crop.resize(resized_size, Image.Resampling.LANCZOS)
    crop = crop.filter(ImageFilter.UnsharpMask(radius=0.8, percent=45, threshold=3))

    background = border_color(crop)
    canvas = Image.new("RGB", (CANVAS_SIZE, CANVAS_SIZE), background)
    position = ((CANVAS_SIZE - crop.width) // 2, (CANVAS_SIZE - crop.height) // 2)
    canvas.paste(crop, position, feather_mask(crop.size))

    output = OUTPUT_DIR / f"STK_PROP_Bookshelf_A_Meshy_{name}.png"
    canvas.save(output, format="PNG", optimize=True)
    return output


def main() -> None:
    if not SOURCE.is_file():
        raise FileNotFoundError(SOURCE)
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    source = Image.open(SOURCE).convert("RGB")
    if source.size != (1254, 1254):
        raise ValueError(f"Unexpected source size {source.size}; crop coordinates require 1254x1254")

    for name, box in VIEWS.items():
        output = make_view(source, name, box)
        with Image.open(output) as check:
            if check.size != (CANVAS_SIZE, CANVAS_SIZE) or check.mode != "RGB":
                raise RuntimeError(f"Invalid output: {output}")
        print(output)


if __name__ == "__main__":
    main()
