# Steamtek_C002

Steamtek_C002 is the first production character built through the approved reusable Steamtek character pipeline.

## Identity

- Role: maintenance worker NPC / industrial pressure-system technician
- Visual tier: production NPC, intentionally simpler than hero benchmark Steamtek_C001
- Rig: approved `Steamtek_HumanRig_v1`
- Source forward axis: Blender `-Y`
- Required actions: `STK_IDLE`, `STK_WALK`

## Locked concept

`concept/Steamtek_C002_Turnaround_v1.png` is the approved visual target. The left copper pressure-tool gauntlet, right-hip diagnostic unit and wrench holster, back regulator assembly, cyan diagnostics, and orange safety accents must remain on their physical sides in every rendered direction.

The concept controls identity, silhouette, materials, and equipment placement. The approved master controls camera, scale, roots, rig, animation names, canvas, direction order, and Godot transforms.

## Rigged blockout v1

`blender/Steamtek_C002_Blockout_v1.blend` contains 58 deform-bound modular parts on the approved rig, plus inherited `STK_IDLE` and `STK_WALK` actions. It passed production scene validation and a genuine eight-direction idle preview.

The blockout establishes the fitted silhouette and locked equipment sides. It is deliberately not the final detailed mesh.

## Detailed prototype v1

`blender/Steamtek_C002_DetailedPrototype_v1_1.blend` advances the approved blockout to 74 deform-bound parts. It adds jacket harness hardware, belt pouches, respirator and cap-lamp detail, a segmented pressure gauntlet, wrench hardware, regulator framing, paired hoses, emissive diagnostics, smooth shading, and restrained bevels while preserving the approved rig and equipment sides.

The detailed prototype passed production Blender validation and rendered 128 fixed-canvas frames: eight idle frames and eight walk frames in each of the eight genuine directions. Both the 1254x1254 raw renders and 256x256 production frames passed the automated render contract.

## Godot package

- `production/idle/` contains the 64 packaged idle frames.
- `production/walk/` contains the 64 packaged walk frames.
- `godot/Steamtek_C002_Frames.tres` contains the 16 standard directional animations.
- `godot/Steamtek_C002_Visual.tscn` applies the locked visual scale `0.73` and visual offset `(0, -110)` to the `AnimatedSprite2D` child only.

This is a production-ready pipeline prototype and a usable NPC visual. It is not a hand-sculpted hero-detail mesh; further art polish can replace individual modeled parts without changing the approved camera, roots, rig, animation names, fixed canvas, or Godot contract.

## In-game review

- `scenes/characters/npc/Steamtek_C002_NPC.tscn` is the reusable gameplay body with the standard visual child, 28x18 collision footprint, interaction area, navigation agent, and audio node.
- `scenes/characters/validation/Steamtek_C002_AnimationReview.tscn` is the standalone Godot review room. It auto-cycles all eight genuine directions, switches between idle and walk with Space, and never mirrors a frame.

## Playable-map integration

`scenes/characters/npc/Steamtek_C002_NPC.gd` gives the reusable body a four-point waypoint patrol, collision-aware movement, genuine eight-direction idle/walk selection, and a short player-facing interaction. The current map does not yet contain a baked `NavigationRegion2D`, so this first integration uses safe local waypoints while retaining the `NavigationAgent2D` node for the later navmesh pass.

The playable `main.tscn` uses C002 for the existing `Trainer`/Foreman Brassguard instance in its Y-sorted NPC layer.

## Direction correction v1.2

Playable-map QA established that Godot's screen-direction order requires a clockwise Blender turntable. Pipeline v1.6 keeps the locked `ROOT_CharacterFacing` yaw at `-45` degrees and rotates `ROOT_Direction` clockwise from south through all eight genuine directions. All 128 C002 frames were rerendered; south now shows the character front and north shows the regulator backpack. No gameplay remapping or mirroring is used.
