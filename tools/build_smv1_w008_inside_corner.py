from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/modular_v1/walls/source/SMV1_W008_InsideCorner_spine.png"
TARGET = ROOT / "assets/modular_v1/walls/production/SMV1_W008_InsideCorner.png"

spine = Image.open(SOURCE).convert("RGBA")
spine = spine.resize((100, 714), Image.Resampling.LANCZOS)

canvas = Image.new("RGBA", (1280, 1152))
canvas.alpha_composite(spine, (590, 356))
canvas.save(TARGET)
