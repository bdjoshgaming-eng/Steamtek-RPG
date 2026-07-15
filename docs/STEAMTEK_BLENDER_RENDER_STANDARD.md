# Steamtek Blender Render Standard

All Modular v2 Blender assets use `blender/scripts/steamtek_render_standard.py`.
Asset scripts define geometry only; the shared module owns camera, render size,
color management, world lighting, role materials, and profile lighting.

## Locked output

- Blender 4.5 LTS
- Eevee Next
- Orthographic camera at the canonical Steamtek isometric projection
- 1280 x 1440 RGBA PNG
- Transparent film
- AgX Medium High Contrast
- Canonical orthographic scale: 3.529
- Godot display scale: 0.2

## Profiles

- `standard_surface`: walls, doors, windows, and broad facade modules
- `narrow_trim`: columns, seam covers, posts, and small corner caps
- `horizontal_trim`: cornices and parapets
- `prop`: freestanding environment props

Do not tune camera, world, or lights inside an individual asset script. If a
family needs a perceptual adjustment after gameplay downsampling, update its
shared profile and rerender the family together.

## Fidelity gate

Every candidate is reviewed at true gameplay scale and 2x inspection scale.
Candidates must retain readable faces without becoming a bright focal point,
preserve canonical alpha and snap coordinates, and pass
`tools/validate_modular_v2.py` before production promotion.
