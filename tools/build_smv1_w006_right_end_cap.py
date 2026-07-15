from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
WALLS = ROOT / "assets/modular_v1/walls/production"
MASTER = WALLS / "SMV1_W001_PlainWall.png"
TARGET = WALLS / "SMV1_W006_RightFacadeEndCap.png"
DONOR = ROOT / "assets/modular_v1/walls/source/SMV1_W006_RightEndCap_spine.png"

master = Image.open(MASTER).convert("RGBA")
spine = Image.open(DONOR).convert("RGBA")
spine = spine.resize((72, 714), Image.Resampling.LANCZOS)

result = master.copy()
result.alpha_composite(spine, (1048, 81))

# W001 owns all deterministic geometry. The right termination is contained
# inside its mask, and the complete left connection region remains unchanged.
result.putalpha(master.getchannel("A"))
result.save(TARGET)
