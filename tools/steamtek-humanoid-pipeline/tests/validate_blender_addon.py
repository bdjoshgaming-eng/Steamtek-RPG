import importlib.util
import sys
from pathlib import Path

import bpy


ROOT = Path(__file__).resolve().parents[1]
ADDON_FILE = ROOT / "blender_addon" / "steamtek_humanoid_intake" / "__init__.py"


def load_addon():
    spec = importlib.util.spec_from_file_location("steamtek_humanoid_intake_test", ADDON_FILE)
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    module.register()
    return module


def make_fixture():
    bpy.ops.object.armature_add(enter_editmode=True, location=(0, 0, 0))
    armature = bpy.context.object
    armature.name = "Steamtek_TestRig"
    base = armature.data.edit_bones[0]
    base.name = "Hips"
    base.head = (0, 0, 0.9)
    base.tail = (0, 0, 1.1)
    parent = base
    for name, length in (("Spine", 0.25), ("Chest", 0.25), ("Neck", 0.12), ("Head", 0.22)):
        bone = armature.data.edit_bones.new(name)
        bone.head = parent.tail
        bone.tail = (0, 0, bone.head.z + length)
        bone.parent = parent
        parent = bone
    for side, x in (("L", 0.22), ("R", -0.22)):
        hand = armature.data.edit_bones.new(f"hand.{side}")
        hand.head = (x, 0, 1.35)
        hand.tail = (x * 2, 0, 1.25)
        foot = armature.data.edit_bones.new(f"foot.{side}")
        foot.head = (x * 0.5, 0, 0.2)
        foot.tail = (x * 0.5, -0.2, 0.15)
    bpy.ops.object.mode_set(mode="OBJECT")

    bpy.ops.mesh.primitive_cube_add(scale=(0.25, 0.15, 0.55), location=(0, 0, 0.85))
    body = bpy.context.object
    body.name = "Steamtek_TestBody"
    body.parent = armature
    modifier = body.modifiers.new("Armature", "ARMATURE")
    modifier.object = armature
    group = body.vertex_groups.new(name="Hips")
    group.add(range(len(body.data.vertices)), 1.0, "REPLACE")

    for name in ("Idle", "Walking"):
        action = bpy.data.actions.new(name)
        action.frame_start = 1
        action.frame_end = 24
    bpy.context.scene.steamtek_humanoid.armature = armature
    return armature, body


addon = load_addon()
armature, body = make_fixture()
report = addon._scene_report()
assert report["passed"], report

result = bpy.ops.steamtek.normalize_animations()
assert result == {"FINISHED"}
assert "STK_IDLE" in bpy.data.actions
assert "STK_WALK" in bpy.data.actions

result = bpy.ops.steamtek.create_sockets()
assert result == {"FINISHED"}
for socket in ("SOCKET_Head", "SOCKET_Hand_R", "SOCKET_Hand_L", "SOCKET_Back"):
    assert bpy.data.objects.get(socket) is not None, socket

print("STEAMTEK_VALIDATION_OK: Blender intake, animation normalization, and sockets passed")
