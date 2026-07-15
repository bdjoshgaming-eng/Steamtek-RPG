# P006 — pipe_valve

## Metadata

- Category: Prop
- Districts: Lantern Ward
- Source Sheet: content.png
- Status: Source / Production Draft

## Godot Integration

Create a reusable `.tscn` scene after QC.

Suggested scene:

```text
P006_pipe_valve (StaticBody2D)
├── Visual (Sprite2D)
└── BaseCollision (CollisionShape2D)
```

## QC Checklist

- [ ] Transparent background
- [ ] Tight crop
- [ ] Correct scale
- [ ] Correct bottom-center ground contact
- [ ] No baked background
- [ ] No stray pixels
- [ ] Fits Steamtek neo-industrial art direction
- [ ] Tested in Godot
