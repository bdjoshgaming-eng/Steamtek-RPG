from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
WALLS = ROOT / "assets/modular_v1/walls/production"
MASTER = WALLS / "SMV1_W001_PlainWall.png"
TARGET = WALLS / "SMV1_W005_LeftFacadeEndCap.png"
BACKUP = WALLS / "SMV1_W005_LeftFacadeEndCap_pre_geometry_fix.png"
DONOR = ROOT / "assets/modular_v1/walls/source/SMV1_W005_LeftEndCap_spine.png"

master = Image.open(MASTER).convert("RGBA")
spine = Image.open(DONOR).convert("RGBA")
spine = spine.resize((72, 714), Image.Resampling.LANCZOS)

result = master.copy()
result.alpha_composite(spine, (160, 356))

# Lock the exact W001 alpha silhouette. This makes canvas, top/bottom profile,
# baseline, and both connection edges deterministic and family-identical.
result.putalpha(master.getchannel("A"))
result.save(TARGET)
