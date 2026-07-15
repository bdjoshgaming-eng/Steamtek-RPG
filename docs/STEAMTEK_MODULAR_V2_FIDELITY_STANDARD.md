# Steamtek Modular v2 Fidelity Standard

This document controls visual upgrades to the geometry-approved Modular v2 library. Fidelity work may improve material, lighting, weathering, and functional detail, but it may not redefine projection, canvas, silhouette, origin, sockets, collision, or joining edges.

## Fidelity target

Steamtek is rain-soaked neo-industrial / neo-punk, not Victorian steampunk and not fantasy machinery. The approved presentation target is high-fidelity 3D-to-2D isometric rendering: clean modeled forms, believable materials, controlled lighting, and excellent readability at gameplay scale. It must not look pixel-art, retro 32-bit, low-resolution, or like a flattened low-detail tileset.

Color and atmosphere vary with world depth. The surface is openly vibrant and
rain-reflective; the massive underground city becomes progressively darker and
grittier as the player descends while retaining selective neo-punk color. See
`docs/STEAMTEK_WORLD_COLOR_PROGRESSION.md` for the authoritative progression.

### Reference boundary: The Ascent

`The Ascent` is a benchmark for the *resolved fidelity visible in the final isometric image*: crisp manufactured edges, layered construction, material-specific highlights, believable surface wear, dense functional detail, and clear large/medium/small form hierarchy. It is not a palette reference, not a request for neon cyberpunk styling, and not a requirement that Steamtek become a realtime 3D game. Steamtek keeps its existing palette and exports controlled 3D masters as transparent 2D modular sprites.

Approved material language:

- Rain-darkened concrete and engineered composite panels
- Gunmetal, black steel, black iron, and restrained copper/brass fittings
- Wet roughness variation rather than uniform gloss
- Functional fasteners, service channels, pressure lines, vents, and access panels
- Vibrant cyan, electric blue, magenta, hot pink, violet, and amber used with
  deliberate focal hierarchy
- Steamtek's established blue-black, charcoal, gunmetal, copper, cyan, magenta, and amber palette
- Cool nighttime environmental light with warm amber practicals and vivid
  cyan/magenta/pink/blue technology, signage, and reflected-color accents
- Broad atmospheric shadow pools and restrained wet highlights
- Lived-in wear, stains, repairs, and imperfect maintenance

Avoid:

- Organic or cobblestone-like wall texture
- Bright white outlines around every panel
- Decorative gears or purposeless pipework
- Making the entire world uniformly dark, gray, brown, or desaturated
- Treating "controlled neon" as a ban on vibrant color
- Unrelated photographic and illustrated material styles in one assembly
- Low-resolution, pixelated, retro-console, or 32-bit-looking rendering
- Excessive microcontrast, plastic surfaces, or showroom-clean materials
- Saturated neon dominating the environment
- Baked scenery, skyline silhouettes, labels, or backgrounds
- Detail that disappears into noise at the production `0.2` display scale

## Immutable geometry

Every production fidelity edit must preserve:

- Exact PNG width and height
- Exact alpha value of every pixel
- Exact projection and visible footprint
- Exact connection boundaries
- Exact scene Visual transform
- Exact root transform, markers, and collision

The locked alpha fingerprints are stored in:

```text
assets/modular_v2/geometry_manifest.json
```

Run the validator after every proposed production edit:

```text
python tools/validate_modular_v2.py
```

An `Alpha silhouette drift` failure rejects the image even if it looks better in isolation. Refreshing the manifest is allowed only for an explicitly approved geometry revision, never to make an unapproved fidelity edit pass.

## Lighting contract

- Primary environmental light: cool, controlled nighttime key and ambient fill
- Practical light: localized amber, cyan, or magenta according to function
- Wet-edge response: narrow and material-dependent, not a white cartoon outline
- Concrete/composite: broad, low-intensity response
- Painted steel: sharper response with controlled edge wear
- Black iron: dark body with readable specular breaks
- Copper/brass: restrained warm highlights, used mainly at functional joints
- Emissive cyan/magenta/pink/blue/amber: vivid and readable at focal locations,
  with softened spill and wet reflections; it should not flatten every module
  into the same saturated color
- Neighboring modules must share the same light direction and contrast range
- Shadows should be soft and atmospheric while preserving crisp gameplay-readable silhouettes

## Preferred production route

The authoritative fidelity route is a locked Blender 3D-to-2D pipeline:

```text
Canonical Modular v2 dimensions
-> Blender model built to the same bay/story proportions
-> Locked orthographic 2:1 camera
-> Locked object origin and render framing
-> Shared Steamtek materials and light rig
-> Transparent high-resolution render
-> Deterministic canvas/alpha normalization
-> Modular v2 validation
-> Godot production PNG
```

AI-generated repaints may be used for concept exploration and material reference, but the long-term production master should come from controlled 3D geometry so projection, lighting, scale, and family consistency remain reproducible.

## Material-scale contract

Judge every asset at both source resolution and final Godot scale. Source-resolution detail is useful only when it produces clear material separation at `0.2` scale.

- Large forms establish the module from gameplay distance.
- Medium forms explain construction and function.
- Fine wear supports the surface without becoming visual static.
- Repetition must not reveal an obvious stamp across a three-bay run or tiled roof.

## Initial fidelity pilot

The first controlled pilot uses:

```text
SMV2_W001_PlainWall
SMV2_R002_ParapetFront
SMV2_C001_CorniceFront
```

Purpose:

- W001 establishes the wall material and lighting master.
- R002 proves that the same language works at parapet height.
- C001 proves that trim reads as a distinct structural component rather than a duplicate parapet.

The pilot remains in source/staging form until all three assets look related in one assembled test. Do not install a lone enhanced W001 into production while the rest of the wall family still uses the previous material language.

## Approval tests

A fidelity pass is approved only after:

1. Geometry-manifest validation passes.
2. No green fringe, white halo, painted background, or semi-transparent edge noise is visible.
3. A three-module straight run shows no material or lighting discontinuity.
4. Front and side families match at an outside corner.
5. A two-story stack maintains a consistent light direction.
6. Roof, parapet, cornice, wall, door, and fire escape read as one asset family.
7. The apartment shell is inspected at gameplay camera scale with editor overlays hidden.

## Production promotion - 2026-07-13

The first Blender-fidelity structural family is promoted to production:

- Walls: W001, W002, W003 closed/open, W004, W005, W006, W007, W008, W009, W010, W011 closed/open, W012, W013
- Cornices: C001, C002, C003, C004
- Parapets: R002, R003, R004, R005

C003/C004 and R004/R005 are deterministic two-leg scene composites rather
than independent painted corner textures. The canonical outside vectors are
`(-192, 96)` to the front leg and `(0, 0)` to the side leg. The canonical
inside vectors are `(-192, -96)` to the side leg and `(0, 0)` to the front
leg. C004 increases the production module count from 27 to 28.

The final production-only review scene is
`scenes/modular_v2/validation/SMV2_ProductionCornerFidelityGate.tscn`.
The pre-promotion snapshot is stored at
`docs/archives/pre_blender_promotion_2026-07-13.zip`.

W002 and both W003 window states were promoted in a second facade-opening
pass. W003 closed and W003 open share the same `1280x1440` canvas, canonical
alpha silhouette, wall collision, ground-contact root, and `(192, -96)` right
socket. The open state is a separate production module so designers can choose
the pose directly while assembling a facade. Its glass is rain-streaked smoked
glass with a blackout backing and contains no city silhouette.

W009 was subsequently corrected from its missed legacy ornate texture to the
same approved Blender narrow-trim master used by W007. This is intentional:
W007 and W009 share the same full-story overlay geometry, display transform,
base/upper sockets, and alpha envelope. The correction changes no scene or
snap behavior.

The W007/W008/W009 column family then received a silhouette-only alpha fix.
The previous normalization had reapplied the legacy rectangular alpha and made
empty pixels around the pointed caps opaque black. Production now preserves
the fitted Blender alpha, removing those black corner wedges while retaining
the same canvas, root, full-story height, and placement envelope.

W011 closed and open side-window modules were promoted from deterministic
horizontal mirrors of the approved W003 variants. They inherit W010's
`(192, 96)` side socket, `(96, -32)` visual position, collision, alpha
silhouette, and side-family lighting direction.

W012 was promoted as the deterministic side-family counterpart of W002. It
retains W010's visual transform, alpha silhouette, collision, and `(192, 96)`
socket while preserving the approved human-scale door proportions, pneumatic
header, access controls, and service-line terminations.

W004 was promoted as the front-facing utility feature wall. It keeps the W001
wall envelope while replacing the legacy ornate surface with a modeled axial
ventilation fan, monitored pressure/coolant cell, service manifold, and
restrained cyan/magenta status accents.

W013 was promoted as W004's deterministic side-family counterpart. It uses
W010's alpha silhouette, visual transform, collision, and `(192, 96)` socket;
the utility controls and mechanical layout are mirrored consistently with the
other side-facing modules.

W005/W006 were promoted as deterministic W001 composites with the approved
narrow-trim termination clipped inside the canonical front-wall silhouette.
W005 terminates the left root edge; W006 terminates the far right edge at the
module's `(192, -96)` socket. Neither asset changes the wall envelope.
