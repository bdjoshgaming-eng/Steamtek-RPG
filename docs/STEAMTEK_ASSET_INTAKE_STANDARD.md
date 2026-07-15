# Steamtek Asset Intake Standard

Steamtek assets are compatible because reusable profiles own their projection,
scale, origin, sockets, collision, and Godot scene structure. Outside artwork
supplies appearance; it does not redefine gameplay geometry.

## Location-first surface rule

Before choosing a surface pattern, write a short location brief covering:

- Purpose and users: traffic road, pedestrian frontage, service route, plaza,
  loading bay, interior floor, or another specific role
- Expected traffic and structural load
- Maintenance level and ownership
- Rain exposure, drainage, runoff, and nearby utilities
- Age, repairs, resurfacing, and district condition
- Adjacent buildings, entrances, curbs, and narrative function

Construction follows that brief. Visual attractiveness alone is not a reason
to introduce slabs, pavers, markings, polish, or damage. A service alley should
read as a continuous corridor between buildings, with its center, edges,
entrances, drains, repairs, and prop zones treated as cooperating modules.

## Supported intake paths

- Character model: use the Character Blender Pipeline for standardized scale,
  eight-direction rendering, animation frames, and Godot packaging.
- Rendered wall image: use Steamtek Modular Intake and select `front` or `side`.
  The tool creates a staging PNG, reusable module scene, collision, sockets, and
  a mixed-reference/three-piece snap test.
- Ground diamonds, roof surfaces, and foundation blocks: select their named
  intake profile. The tool generates the canonical canvas, midpoint sockets,
  reusable scene, and four-piece surface QA gate.
- Props use exact small, medium, large, or tall intake profiles. Each produces
  a fixed canvas, gameplay height, ground-contact root, collision footprint,
  reusable scene, and character-scale/Y-sort QA gate.

## Non-negotiable rule

Mechanical conformance cannot repair incorrect visual perspective. Blender may
provide the locked camera, geometry, silhouette, masks, pivots, and socket
guides, but its material render is not automatically final Steamtek artwork.
The final neutral 2D sprite must pass the art-direction gate independently.
Intake reports aspect reshaping and opaque-background warnings so incompatible
art is not silently promoted.

Production sprites never contain baked cyan, magenta, amber, glow, spill, or
colored wet-surface reflections. Those effects are supplied by Godot lights,
tintable grayscale emission layers, overlays, and shaders.

## Wall workflow

1. Run `tools/modular-intake/Launch_Steamtek_Modular_Intake.bat`.
2. Choose the outside image.
3. Enter an ID appropriate to the profile: `SMV2_W###`, `SMV2_G###`,
   `SMV2_R###`, or `SMV2_F###`.
4. Choose the correct asset profile.
5. Build the candidate.
6. Open the exact QA scene shown by the tool and run it at 1x.
7. Promote only after the mixed production seam and three-piece run both pass.

The intake tool writes only under `assets/modular_v2/intake`,
`scenes/modular_v2/intake`, and `scenes/modular_v2/validation`. It never
overwrites production assets.
