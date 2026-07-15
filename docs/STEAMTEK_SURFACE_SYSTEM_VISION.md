# Steamtek Surface System Vision

Date locked: 2026-07-14

## District layout intent

The first playable surface area is not a single repeated ground texture. It is
a connected streetscape built from distinct modular surface bands:

- A broad rain-polished main street and intersection
- Raised sidewalks on both sides of the street
- A narrower service alley connecting the apartment area to the main street
- Building frontages placed behind the pedestrian edge
- The Lantern as the primary destination in the upper portion of the layout

The user's layout sketch is the spatial authority for this block. Exact road,
sidewalk, and alley widths remain adjustable during the Godot blockout, but the
relationships above are locked.

## Location determines construction

Every ground family begins with its place in the city, not with an attractive
tile pattern:

- Main road: continuous traffic pavement with road-scale wear and repairs
- Sidewalk and venue frontage: poured slabs or other pedestrian construction
  appropriate to the maintained public edge
- Service alley: coarse continuous pavement, neglected resurfacing, utility
  cuts, runoff, grime, and localized repairs; never a polished plaza treatment
- Courtyard or plaza: pavers, cobbles, or decorative modules only where the
  civic or commercial setting supports them
- Loading or industrial bay: reinforced concrete, steel plates, heavy repair,
  and drainage appropriate to machinery and freight

The service alley is assembled as a long corridor. A visually seamless center
segment repeats along its length; separate left/right building-edge strips,
alley-mouth transitions, entrances, drainage pieces, utility repairs, and prop
zones provide structure and variation. The repeat unit must not advertise
itself as four square floor tiles.

The level designer owns the actual alley layout. The project supplies modular
ground, façade, utility, lighting, and prop families with correct sockets and
scale. Reference images may influence asset fidelity and family coverage, but
must not become pre-authored level compositions. Builder instructions live in
`docs/STEAMTEK_MODULAR_BUILDER_WORKFLOW.md`.

## The Lantern

The Lantern is a rain-soaked neo-industrial bar/tavern and a major social anchor
for Lantern Ward. It sits prominently at the upper street corner rather than
reading as a generic background building.

Its frontage should include:

- A recognizable corner entrance and venue sign
- Warm amber doorway and window light
- Restrained magenta and cyan commercial accents
- Wet pavement reflections localized around actual light sources
- Industrial pipes, vents, service hardware, and believable wall construction
- A generous sidewalk or small forecourt that can hold NPCs and interactions
- Clear pedestrian access from the main street and intersection

The venue reference establishes mood and function, not geometry to copy. The
Steamtek version must remain neo-industrial/neo-punk and avoid Victorian
ornament, decorative gears, or excessive neon.

## Color and atmosphere

This section defines the **surface** palette. The underground city and deep silo
follow the separate progression in `docs/STEAMTEK_WORLD_COLOR_PROGRESSION.md`.

Steamtek's surface must not become a uniformly dark or desaturated world. Dark wet
concrete, blue-black pavement, steel, and shadow provide the stage for vibrant
color rather than replacing it.

The city palette includes:

- Vivid cyan and turquoise technology light
- Electric and reflected blues
- Magenta, hot pink, and violet commercial light
- Warm amber and copper practical light
- Selective red and green utility indicators where functionally appropriate

Color should appear in signs, windows, kiosks, machinery, illuminated fluids,
street furniture, character accents, and especially rain-wet reflections. Use
strong focal clusters and quieter connecting areas so the district feels rich
and colorful without every object competing at equal saturation.

"Controlled neon" means intentional placement and readable hierarchy. It does
not mean dull, colorless, or almost entirely black scenery. The result should
feel vibrant inside the Steamtek neo-industrial universe, not like generic
cyberpunk pasted over it.

The complete city-street kit is organized into five cooperating families:

1. Floor and ground surfaces
2. Walls and building façades
3. Street furniture and civic details
4. Industrial machinery and utility props
5. Small details, signs, stains, puddles, and decals

## Modular construction layers

## Surface tile quality reference

The approved visual benchmark favors physically constructed modular tiles with
clear depth and role separation. Carry forward:

- Modeled slab and curb thickness instead of a flat painted diamond
- Beveled manufactured edges that catch restrained wet highlights
- Recessed joints and believable panel segmentation
- Localized chips, cracks, patches, and wear without noisy uniform damage
- Distinct material families for road, poured sidewalk, service paving, and
  cobbled or block-paved zones
- Separate straight, corner, and transition geometry that visibly assembles
  into a streetscape
- Subtle rain film and reflections that preserve surface readability

Adapt the benchmark to Steamtek rather than copying it directly:

- Keep blue-black rain-polished road and warm sidewalk materials, then let
  localized cyan, blue, magenta, pink, violet, and amber light animate them
- Do not make generic yellow hazard or lane striping the visual identity
- Do not bake a storm drain or manhole into the repeating base family
- Keep damage placement varied and avoid an obvious repeated four-panel stamp
- Preserve the exact 256x128 diamond, 64x32 lattice, and gameplay-scale player
  relationship

G006 is the approved neutral sidewalk base. Its identifiable wear, repair,
grime, puddle, and colored-reflection details belong to separate variants or
overlays so the base does not stamp repeated damage.

### 1. Fill surfaces

Fill tiles establish continuous traversable areas on the shared 2:1 lattice.

- Road field: rain-polished blue-black traffic surface
- Sidewalk field: warmer rain-wet industrial concrete slabs
- Alley field: coarse continuous service pavement with restrained oil and runoff

Current assets:

- `SMV2_G005_RainPolishedWear` - approved road-field reference
- `SMV2_G006_RainWetSidewalkSlab` - approved sidewalk-field base
- `SMV2_G007_RainWetServiceAlley` - approved continuous service-alley center base

### 2. Edge and transition pieces

Edges are separate modular pieces instead of being baked into every fill tile.

- Straight curb along both lattice axes
- Inside and outside curb corners
- Curb end caps
- Sidewalk-to-alley edge
- Alley-mouth or depressed-curb transition
- Road-to-alley transition
- Building-frontage sidewalk edge

The main intersection is assembled from road fill plus sidewalk and curb corner
pieces. Do not create one giant baked intersection image.

### 3. Environmental overlays

Effects remain separate from the base surfaces whenever possible.

- Localized lamp and sign reflections
- Puddles and thin rain-film variation
- Gutter runoff
- Steam and vent effects
- Litter, stains, and small debris

Do not bake a permanent light source into a repeating road, sidewalk, or alley
fill tile. This prevents visible repetition and keeps lighting tied to actual
props and buildings.

## Lighting ownership

Steamtek uses a hybrid Blender-and-Godot lighting contract.

Blender owns the neutral, permanent sprite presentation:

- Readable form and silhouette
- Material-specific highlights and roughness
- Beveled edge response
- Shared baseline key/fill/rim direction
- Enough baked contrast for the asset to remain readable when no local light is
  present

Godot owns contextual world lighting through reusable scenes and scripts:

- Cyan, blue, magenta, pink, violet, amber, and warning-color light spill
- Light radius, intensity, falloff, flicker, animation, and on/off state
- Shadows and occlusion where useful
- Source-linked wet-pavement reflection overlays or shaders
- District and depth-dependent environmental color

A sign, lamp, window, kiosk, machine, vent, or other luminous prop may include
its visible glowing face in its own artwork. The color it casts onto nearby
ground, walls, characters, and props must come from its Godot light scene.

Wet reflections are separate children of the light-source scene or are driven
by a shared ground shader. They must stretch and break up according to the wet
surface, and disappear or change when the source light changes. A plain
`PointLight2D` provides colored spill but is not sufficient by itself for a
convincing elongated rain reflection on pre-rendered isometric tiles.

No orphan color: every cyan, magenta, pink, blue, violet, amber, red, or green
spill/reflection must trace to a visible source in the assembled scene or to an
explicitly justified off-screen source. Decorative colored reflections with no
light source are prohibited.

Planned reusable structure:

```text
SteamtekSurfaceLight2D (Node2D)
|-- SourceGlow
|-- PointLight2D
|-- WetReflectionOverlay
|-- LightOccluder2D (optional)
`-- AnimationPlayer (optional flicker/pulse)
```

## First blockout target

Build a validation scene representing the user's sketch at gameplay scale:

1. Apartment footprint at the lower end
2. Narrow alley leading from the apartment toward the main street
3. Broad diagonal main street and intersection
4. Continuous sidewalks along the street edges
5. The Lantern frontage zone at the upper corner
6. Current Steamtek_C001 player for scale

Suggested initial proportions for testing only:

- Main street: three to four diamond rows wide
- Sidewalk: one diamond row per side, expanded near The Lantern where needed
- Alley: one to two diamond rows wide

These are blockout starting points, not immutable dimensions. Gameplay
readability, navigation, NPC space, and the exact sketch relationship decide the
final widths.

## Production sequence

1. Build sidewalk wear/repair variants derived from approved G006.
2. Build and review the G007 service-alley corridor assembly language.
3. Build the straight curb/building-edge family on both lattice axes.
4. Build curb corners, end caps, and the alley-mouth transition.
5. Assemble the surface-system blockout scene.
6. Add The Lantern frontage kit and venue lighting.
7. Add source-linked rain, colored-light reflection, steam, and debris overlays.

Each role is reviewed at gameplay scale before promotion. Preserve the exact
256x128 diamond, shared 64x32 lattice, and existing geometry/alpha contracts.
