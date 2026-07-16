# Steamtek Hybrid 3D Proof of Concept

This isolated test proves the proposed Steamtek presentation:

- a live skeletal 3D character with imported `STK_IDLE` and `STK_WALK` animations;
- fixed orthographic camera using the approved 60-degree azimuth / 30-degree elevation contract;
- runtime cyan, magenta, and amber lighting;
- real 3D shadows and depth occlusion;
- an existing painted Steamtek environment PNG mounted on a 3D plane;
- no changes to the current main scene or gameplay scripts.

## Installed resources

```text
assets/characters/npc/Steamtek_C002/production/
|-- STK_C002_RigProof_v1.glb
|-- STK_C002_RigProof_v1.export.json
`-- STK_C002_RigProof_v1.validation.json

scenes/tests/hybrid_3d/
|-- Steamtek_Hybrid3D_POC.tscn
`-- steamtek_hybrid_3d_poc.gd
```

## Run

Open and run:

```text
res://scenes/tests/hybrid_3d/Steamtek_Hybrid3D_POC.tscn
```

Use `W`, `A`, `S`, and `D` to move. Movement plays the imported `STK_WALK` clip; stopping returns to `STK_IDLE`.

The controller uses camera-relative movement with gradual acceleration,
deceleration, and frame-rate-independent turning. Keyboard input supplies eight
target directions, but the live 3D model blends through the angles instead of
snapping. A controller stick can supply the full continuous range of movement
angles.

Controller feel is tuned at the top of `steamtek_hybrid_3d_poc.gd`:

```text
WALK_SPEED
MOVEMENT_ACCELERATION
MOVEMENT_DECELERATION
TURN_RESPONSE
```

## Art-status boundary

`STK_C002_RigProof_v1.glb` is an animated technical proof, not the final Vesper Kane model. It validates the Godot import, skeleton, animation naming, collision, movement, camera, lighting, shadow, and occlusion pipeline. The final character-art pass must replace the proof mesh and materials while preserving those working contracts.

The final visual target is documented in:

```text
docs/VESPER_KANE_CHARACTER_TARGET.md
```

## Acceptance result

- Godot 4.7 GLB import: PASS
- Skeleton and mesh import: PASS
- `STK_IDLE`: PASS
- `STK_WALK`: PASS
- Smooth acceleration and deceleration: PASS
- Continuous interpolated facing: PASS
- Analog movement-angle support: PASS
- Isolated scene parse and launch: PASS
- Locked camera contract: PASS
- Final Vesper fidelity: NOT STARTED - next art phase

## Scope protection

This proof does not modify `project.godot`, `main.tscn`, or the current gameplay player. Existing errors in `scenes/main.gd` and `scenes/Combat.gd` are outside this proof and were left unchanged.
