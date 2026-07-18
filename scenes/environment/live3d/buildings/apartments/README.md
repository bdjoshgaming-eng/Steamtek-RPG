# Steamtek Live-3D Apartment Assemblies

All apartment assemblies instance the shared meter-scale live-3D kit. Their visible meshes remain temporary; layout, root, rotation, and placement sockets are the production contracts.

## Shared rules

- 1 Godot unit = 1 meter.
- Building root is the front-center ground point.
- Authored front is `+Z`; interior depth extends toward `-Z`.
- Rotate the building root around Y by 0, 90, 180, or 270 degrees.
- Never mirror a building with negative scale.
- Storey height is 3.2 m; horizontal module grid is 2.4 m.
- Building-level `Marker3D` sockets identify street front, rear service, sides, corner frontage where applicable, and roof center.

## Apartment A

- Scene: `SteamtekApartmentAAssembly3D.tscn`
- Footprint: 3 bays wide by 2 bays deep
- Storeys: 2
- Centered upper balcony and left-offset entrance

## Apartment B

- Scene: `SteamtekApartmentBAssembly3D.tscn`
- Footprint: 4 bays wide by 2 bays deep
- Storeys: 2
- Right-offset upper balcony and left-offset entrance

## Apartment C

- Scene: `SteamtekApartmentCAssembly3D.tscn`
- Footprint: 3 bays wide by 2 bays deep
- Storeys: 3
- Staggered second- and third-storey balconies with centered entrance

## Apartment D

- Scene: `SteamtekApartmentDAssembly3D.tscn`
- Footprint: 3 bays wide by 3 bays deep
- Storeys: 2
- Dual public street faces at `+Z` and `+X`
- Right-side corner balcony, visible electrical/utility band, rear service entry, and rooftop fan

Apartment D introduces corner-lot and service-infrastructure variation while remaining linked to the same facade, floor, roof, parapet, balcony, lighting, electrical, utility, and industrial prop scenes. Its building root follows the same four-way rotation contract as Apartments A, B, and C.

Collision and final production art remain deferred until assembly layouts and district-placement behavior are approved.
