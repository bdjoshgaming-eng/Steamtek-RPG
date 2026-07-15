from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import random

ROOT = Path(__file__).resolve().parents[1]
GEN = Path(r"C:\Users\bdjos\.codex\generated_images\019f57fe-365f-7490-b71c-5dc46e68feef")

def backup_once(path: Path, suffix: str):
    backup = path.with_name(path.stem + suffix + path.suffix)
    if not backup.exists():
        backup.write_bytes(path.read_bytes())

# R002: use the generated material pass, but force the exact original alpha mask.
r002 = ROOT / "assets/modular_v1/roofs/production/SMV1_R002_ParapetFront.png"
backup_once(r002, "_pre_fidelity_fix")
old = Image.open(r002.with_name(r002.stem + "_pre_fidelity_fix.png")).convert("RGBA")
paint = Image.open(GEN / "exec-00f0bb0b-0a8d-468e-a888-d3a2d6ee0041.png").convert("RGB")
paint = paint.resize(old.size, Image.Resampling.LANCZOS)
paint.putalpha(old.getchannel("A"))
paint.save(r002)

# W003: preserve all original pixels except the three glass pane interiors.
w003 = ROOT / "assets/modular_v1/walls/production/SMV1_W003_Window.png"
backup_once(w003, "_with_city")
im = Image.open(w003.with_name(w003.stem + "_with_city.png")).convert("RGBA")
mask = Image.new("L", im.size, 0)
d = ImageDraw.Draw(mask)
panes = [
    [(354,533),(539,482),(539,798),(354,861)],
    [(547,478),(692,438),(692,746),(547,798)],
    [(701,434),(914,375),(914,674),(701,742)],
]
for pane in panes:
    d.polygon(pane, fill=255)

glass = Image.new("RGBA", im.size, (6,18,29,255))
gd = ImageDraw.Draw(glass, "RGBA")
for y in range(360, 870):
    t = (y-360)/510
    gd.line((300,y,940,y), fill=(10,38-int(16*t),58-int(23*t),255))

# Low-frequency wet reflections keep the panes dimensional without depicting a city.
gd.polygon([(330,520),(930,350),(930,420),(330,610)], fill=(19,55,76,255))
gd.polygon([(330,760),(930,585),(930,625),(330,805)], fill=(13,39,57,255))

random.seed(3003)
for _ in range(390):
    x=random.randint(350,915); y=random.randint(380,850)
    r=random.choice((1,1,2)); v=random.randint(55,105)
    gd.ellipse((x-r,y-r,x+r,y+r), fill=(40+v//3,90+v//2,120+v//2,255))
for _ in range(42):
    x=random.randint(350,915); y=random.randint(390,810)
    length=random.randint(12,55)
    gd.line((x,y,x-1,y+length), fill=(42,105,140,255), width=1)
glass = glass.filter(ImageFilter.GaussianBlur(.35))
im.alpha_composite(Image.composite(glass, Image.new("RGBA", im.size), mask))
# Restore original alpha exactly.
im.putalpha(Image.open(w003.with_name(w003.stem + "_with_city.png")).getchannel("A"))
im.save(w003)
