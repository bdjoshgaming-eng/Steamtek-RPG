#!/usr/bin/env python3
"""Fit a fidelity candidate to a canonical asset and reapply its exact alpha."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw


def parallelogram_mask(size: tuple[int, int], specification: str) -> Image.Image:
    try:
        left_x, left_y, right_x, right_y, height = (
            float(value.strip()) for value in specification.split(",")
        )
    except ValueError as error:
        raise SystemExit(
            "--mask-parallelogram must be left_x,left_y,right_x,right_y,height"
        ) from error

    supersample = 4
    mask = Image.new("L", (size[0] * supersample, size[1] * supersample), 0)
    draw = ImageDraw.Draw(mask)
    points = (
        (left_x, left_y),
        (right_x, right_y),
        (right_x, right_y - height),
        (left_x, left_y - height),
    )
    draw.polygon(
        [(round(x * supersample), round(y * supersample)) for x, y in points],
        fill=255,
    )
    return mask.resize(size, Image.Resampling.LANCZOS)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--candidate", required=True, type=Path)
    parser.add_argument("--canonical", required=True, type=Path)
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument(
        "--crop",
        help="Optional logical source bay as left,top,right,bottom; useful for overscan renders.",
    )
    parser.add_argument(
        "--translate",
        help="Optional non-scaling destination shift as x,y; preserves a camera-locked pixel vector.",
    )
    parser.add_argument(
        "--mask-parallelogram",
        help="Replace legacy alpha with left_x,left_y,right_x,right_y,height geometry.",
    )
    parser.add_argument(
        "--preserve-candidate-alpha",
        action="store_true",
        help="Keep the fitted Blender silhouette instead of applying the canonical legacy alpha.",
    )
    args = parser.parse_args()

    with Image.open(args.candidate) as candidate_image:
        candidate = candidate_image.convert("RGBA")
    with Image.open(args.canonical) as canonical_image:
        canonical = canonical_image.convert("RGBA")

    candidate_alpha = candidate.getchannel("A")
    canonical_alpha = canonical.getchannel("A")
    candidate_bbox = candidate_alpha.getbbox()
    canonical_bbox = canonical_alpha.getbbox()
    if candidate_bbox is None:
        raise SystemExit("Candidate has no visible pixels")
    if canonical_bbox is None:
        raise SystemExit("Canonical asset has no visible pixels")

    if args.translate:
        try:
            translate_x, translate_y = (float(value.strip()) for value in args.translate.split(","))
        except ValueError as error:
            raise SystemExit("--translate must contain two numeric values") from error
        aligned = candidate.transform(
            canonical.size,
            Image.Transform.AFFINE,
            (1.0, 0.0, -translate_x, 0.0, 1.0, -translate_y),
            resample=Image.Resampling.BICUBIC,
        )
        output_alpha = (
            parallelogram_mask(canonical.size, args.mask_parallelogram)
            if args.mask_parallelogram
            else canonical_alpha
        )
        aligned.putalpha(output_alpha)
        args.out.parent.mkdir(parents=True, exist_ok=True)
        aligned.save(args.out)
        print(f"Translated candidate by: {translate_x}, {translate_y}")
        print(f"Canonical bbox: {canonical_bbox}")
        print(f"Wrote {args.out}")
        return 0

    if args.crop:
        try:
            crop_values = tuple(int(value.strip()) for value in args.crop.split(","))
        except ValueError as error:
            raise SystemExit("--crop must contain four integer values") from error
        if len(crop_values) != 4:
            raise SystemExit("--crop must be left,top,right,bottom")
        candidate_bbox = crop_values

    candidate_crop = candidate.crop(candidate_bbox)
    target_width = canonical_bbox[2] - canonical_bbox[0]
    target_height = canonical_bbox[3] - canonical_bbox[1]
    fitted = candidate_crop.resize((target_width, target_height), Image.Resampling.LANCZOS)

    result = Image.new("RGBA", canonical.size, (0, 0, 0, 0))
    result.paste(fitted, canonical_bbox[:2])
    if not args.preserve_candidate_alpha:
        result.putalpha(canonical_alpha)

    args.out.parent.mkdir(parents=True, exist_ok=True)
    result.save(args.out)
    print(f"Candidate bbox: {candidate_bbox}")
    print(f"Canonical bbox: {canonical_bbox}")
    print(f"Wrote {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
