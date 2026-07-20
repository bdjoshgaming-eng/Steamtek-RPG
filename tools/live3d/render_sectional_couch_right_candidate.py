#!/usr/bin/env python3
"""Render the independent right-facing L4 sectional with the validated left QA rig."""

from pathlib import Path
import importlib.util


ROOT = Path(__file__).resolve().parents[2]
STAGE = ROOT / "incoming" / "meshy_apartment_assets" / "APT_Couch_L4_Right" / "staged_pipeline"
SHARED_PATH = Path(__file__).with_name("render_sectional_couch_candidate.py")
SPEC = importlib.util.spec_from_file_location("render_sectional_couch_candidate_shared", SHARED_PATH)
shared = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(shared)


def main() -> None:
    shared.STAGE = STAGE
    shared.SOURCE = STAGE / "STK_PROP_Couch_L4_Right_ProductionCandidate.glb"
    shared.PREVIEWS = STAGE / "previews"
    shared.TEXTURES = STAGE / "textures"
    shared.main()
    for preview in shared.PREVIEWS.glob("STK_PROP_Couch_L4_Left_Candidate_*.png"):
        preview.replace(preview.with_name(preview.name.replace("Couch_L4_Left", "Couch_L4_Right")))


if __name__ == "__main__":
    main()
