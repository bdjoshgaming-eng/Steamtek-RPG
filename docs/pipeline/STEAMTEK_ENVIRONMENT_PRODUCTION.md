# Steamtek Environment Production

This package builds a real high-fidelity wall module on the locked Steamtek
off-axis 60/30 orthographic camera. The calibration image is never used as
production art.

## Build

Run `Build_SMV4_W101_FrontPlain.bat`.

The build writes:

- `output/SMV4_W101_FrontPlain_HD.png`
- `output/SMV4_W101_FrontPlain_HD.json`
- `blender/master/SMV4_W101_FrontPlain_HD.blend`
- `godot/SMV4_W101_FrontPlain_HD.tscn`

It automatically runs validation after rendering.

## Locked contract

- Camera: fixed orthographic, 60 degree azimuth, 30 degree elevation
- Front bay: `(313.534, -90.509)` Godot pixels
- Storey rise: `(0, -219)` Godot pixels
- Root scale: `(1, 1)`
- Background: transparent RGBA PNG
- Style: neo-industrial / neo-punk

The Blender construction axis is rotated so the raw rendered PNG projection
already matches Godot's Y-down coordinate system. No post-render Y flip is
allowed.

## Art rule

Geometry, silhouette, pivots, anchors, and collision are authoritative. Surface
detail may be enhanced later, including with AI-assisted material repainting,
only if those protected channels remain unchanged.

## Approved visual targets

- `Steamtek_Surface_ColorPalette_Aesthetic_Reference.png` controls the complete
  surface palette, material wear, wetness, lighting, and neo-punk mood.
- `ApartmentExterior_AssemblyMockup.png` controls apartment composition.
- Calibration renders and flat-color blockouts are technical evidence only and
  must never become production art.

## Godot install

Install the generated production PNG at:

`res://assets/modular_v4/production/SMV4_W101_FrontPlain_HD.png`

Install the generated scene at:

`res://scenes/modular_v4/modules/walls/SMV4_W101_FrontPlain_HD.tscn`

The scene root remains scale `(1, 1)`. Assemble modules by matching their
`Snap_Left`, `Snap_Right`, `Snap_TopLeft`, and `Snap_TopRight` markers; do not
eyeball offsets or scale individual instances.
