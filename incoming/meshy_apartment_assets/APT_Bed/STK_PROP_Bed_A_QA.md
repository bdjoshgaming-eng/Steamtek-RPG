# STK_PROP_Bed_A QA

## Status

Production pipeline completed. Godot import and independent Material Variant Editor previews are approved. One source-matte instance is placed in the playable `v02` apartment sleep zone; gameplay-camera F6 approval remains pending.

## Source

- Source: `res://incoming/meshy_apartment_assets/APT_Bed/STK_PROP_Bed_A_Meshy.glb`
- Source topology: 19,131 triangles; 21,976 vertices
- Source mesh objects: 1
- Source material slots: 1 combined atlas material (`Material_0.001`)
- UV sets: 1 (`UVMap`)
- Rig: none
- Animations: none

## Production geometry

- Production GLB: `res://assets/environment/live3d/models/apartment_interior/meshy/STK_PROP_Bed_A_Production.glb`
- Final topology after GLB reimport: 19,131 triangles; 22,344 runtime vertices
- Editable pre-export mesh: 21,976 vertices; glTF import splits shared vertices at UV/normal boundaries without changing triangles or silhouette
- Final dimensions in Blender: 1.20000005 m wide x 2.09999967 m long x 1.04999995 m high
- Godot dimension contract: `Vector3(1.2, 1.05, 2.1)` (X width, Y height, Z length)
- Mattress-top target: approximately 0.52 m; wrapper sleeping-surface collision top is 0.52 m
- Root transform: location `(0,0,0)`, rotation `(0,0,0)`, scale `(1,1,1)`
- Pivot: bottom center of full footprint
- Ground contact: minimum vertical coordinate is exactly 0.0 m before export
- Forward: foot end faces Godot +Z; headboard is at -Z
- Aggressive remesh/decimation: none
- Production GLB SHA-256: `61F3227BDECF6E6A8BEC423AB81724039012693825289539838DE151E3CD0AED`

## Geometry checks

- Isolated vertices: 0
- Wire edges: 0
- Duplicate faces: 0
- Mesh validation altered data: no
- Source boundary/non-manifold edges: 19,893
- Production GLB reimport boundary/non-manifold edges: 19,895

The boundary count is retained as a documented warning. The optimized Meshy asset is constructed from many open/disconnected visual shells, but renders correctly. Automatic welding or hole filling was rejected because it would threaten the approved bedding silhouette, hard-surface panels, UVs, and texture appearance.

## Textures and material response

Texture maps found:

- 4096 x 4096 base color
- 4096 x 4096 packed metallic/roughness
- 4096 x 4096 emission
- No normal map supplied by Meshy

The wrapper applies `STK_MAT_Bed_A_SourceMatte.tres`, which preserves the source colors while enforcing these revised matte-response floors after gameplay review:

- Main blanket: 0.90
- Sheets and pillow: 0.88
- Painted frame: 0.75
- Structural metal: 0.68
- Copper: 0.58
- Powered accent housing: 0.65
- Specular response: 0.20
- Bedding metallic response: forced to 0.0 through the two fabric masks
- Painted-frame metallic response: safely capped at 0.35 before its limited adjustment

This reduces plastic-looking bedding, polished painted metal, and sharp reflections without flattening base-color wear, scratches, grime, or edge highlights. Copper remains metallic but restrained. The final matte reading still requires F6 approval under normal apartment lighting.

## Recolor masks

The source has one combined material, so explicit grayscale masks were generated from the actual 4096 atlas and packed metallic/roughness data:

- `Bedding_Main`: 10.1603% of used atlas pixels
- `Bedding_Secondary`: 4.2006%
- `Frame_PaintedMetal`: 19.7630%
- `Accent_Powered`: 0.0140%
- Locked copper helper mask: 7.9507%
- Locked structural helper mask: 57.9115%

The masks are mutually prioritized so the editable regions do not intentionally overlap. Blanket extraction uses burgundy/magenta hue plus non-metallic response; copper is excluded through hue and metallic data. Secondary bedding uses light neutral, high-roughness, non-metallic pixels. Painted frame uses cool blue/teal response while excluding bedding, copper, and powered pixels.

## Emission

- Source emission was present but extremely restrained (maximum texel value 4/255)
- The emission mask combines the source emission signal with the actual cyan headboard pixels
- Default powered color: cyan
- Default emission strength: 1.25
- Emission can be enabled/disabled and recolored independently
- No powered region is applied to bedding

## Collision and sockets

- Collision shapes: 5 `BoxShape3D` shapes
- Lower structural frame: 1 box
- Mattress/sleeping surface: 1 thin box
- Headboard: 1 box
- Footboard: 1 box
- Under-bed storage: 1 box
- Render-mesh collision: not used
- Placement profile: 0.3 m furniture
- Furniture-chain sockets: 2
- Front-alignment socket: 1 at +Z
- Interaction/sleep socket: omitted pending integration with the existing apartment interaction system

## Material variants

Reusable material-only tests were created without duplicating the GLB or staging four beds:

- `STK_MAT_Bed_A_Oxblood.tres`
- `STK_MAT_Bed_A_DeepTeal.tres`
- `STK_MAT_Bed_A_ElectricPlum.tres`
- `STK_MAT_Bed_A_BurnishedOchre.tres`

Profile: `steamtek_bed_v1`

Editable regions: `Bedding_Main`, `Bedding_Secondary`, `Frame_PaintedMetal`, `Accent_Powered`.

Locked regions: structural metal, copper, rust, grime, scratches, edge wear, and painted shading.

## Godot validation

- Production files prepared: yes
- Wrapper prepared: yes
- Live3D Builder registration prepared: yes, at the established static furniture library entry
- Material Variant Editor profile prepared and loaded: yes
- Godot import result: successful in the normal editor
- Independent `Bedding_Main` and `Bedding_Secondary` preview behavior: user-approved
- Playable apartment placement: installed in `SteamtekPlayerApartmentProductionAssembly3D_v02.tscn` at `(-4.35, 0.05, 2.55)`, rotated +90 degrees around Y after gameplay review corrected the original 180-degree orientation
- Wake spawn clearance: moved to the open side of the bed at `(-4.3, 0.08, 1.55)`
- Normal-editor gameplay-camera F6 approval: pending user review

Required F6 checks:

1. Review beside C001, the approved walls, couch, and workstation.
2. Confirm the bedding reads matte rather than plastic or wet.
3. Confirm painted metal is matte/satin and copper is restrained.
4. Preview all four recolor regions independently.
5. Confirm blanket edits do not affect sheets, and frame edits do not affect structural metal or copper.
6. Confirm scale, floor contact, forward direction, collision, and furniture sockets.

## Remaining warnings

- The source's open-shell/non-manifold topology is retained and documented.
- Meshy supplied no normal map.
- Atlas-derived masks require visual confirmation in Godot at gameplay distance.
- The placed apartment instance still requires gameplay-camera, lighting, collision, and navigation approval in F6.
