# Steamtek Quest Marker Handoff

## Decision

-   Quest markers will usually be static.
-   Motion should communicate importance, not simply decorate the world.

## Implementation

-   Attach the quest marker as a child node of the NPC or quest item.
-   Because it is a child, it automatically follows movement, rotation,
    and position.
-   Use a Sprite3D with billboard enabled so it always faces the camera.
-   Position it slightly above the object (roughly 1.0--2.4m depending
    on object height).

## Visual Style

-   Main Quest: Static glowing magenta exclamation point.
-   Side Quest: Cyan exclamation point.
-   Important / Chain Quest: Gold.
-   Generic interactable: White.

## Animation Philosophy

Most markers remain static.

Only optionally animate: - Active tracked quest. - Player nearby. -
Special cinematic moments.

Suggested tracked quest animation: - Tiny vertical float. - Very slow
pulse. - Small glow increase.

## Apartment Mock-up

-   Quest marker shown hovering above a note on the apartment table.
-   Revised preference is to use the original apartment mock-up with a
    magenta quest icon.

## Design Goal

Use movement sparingly so animated markers immediately attract
attention.
