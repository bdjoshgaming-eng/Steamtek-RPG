# Vesper Kane Production Appearance v1 Review

## Appearance pass

- Added deterministic 512×512 PBR texture sets for coat fabric, coat trim, black leather, gunmetal, dark steel, aged brass, skin, and rubber.
- Each material has base-color, roughness, metallic, and tangent-space normal maps.
- Added restrained fabric weave, leather grain, metal wear, brass tarnish, skin variation, and rubber stipple.
- Kept environmental cyan and magenta out of every texture.
- Retained only small functional cyan indicators on the respirator and mechanical arm.

## Preserved

- Approved Production Mesh v1.1 geometry and UVs.
- Physical-left mechanical arm.
- Skeleton, scale, ground contact, roots, +40-degree facing correction, `STK_IDLE`, and `STK_WALK`.

## Runtime review

Open `res://scenes/tests/hybrid_3d/VesperKane_ProductionAppearance_v01.tscn` and press **F6**.

- Press **L** first to inspect material separation under neutral light.
- Press **L** again to confirm the same materials accept Steamtek cyan, magenta, amber, and moon lighting naturally.
- Walk in all directions and use **Space** for stationary deformation review.

Production Mesh v1 and v1.1 remain installed for direct comparison.
