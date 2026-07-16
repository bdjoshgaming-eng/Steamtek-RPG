extends Node3D

@onready var character := $VesperKane_ModularCharacterReview_v01
@onready var state_label: Label = $ReviewUI/State

var mesh_nodes: Array[MeshInstance3D] = []
var current_state := 2


func _ready() -> void:
	collect_meshes(character)
	validate_swap_states()
	apply_state(current_state)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_1:
			apply_state(1)
		KEY_2:
			apply_state(2)
		KEY_3:
			apply_state(3)


func collect_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		mesh_nodes.append(node)
	for child in node.get_children():
		collect_meshes(child)


func apply_state(state: int) -> void:
	current_state = state
	for mesh in mesh_nodes:
		var mesh_name := String(mesh.name)
		if mesh_name.begins_with("VK_MB01_"):
			mesh.visible = base_region_visible(mesh_name, state)
		elif mesh_name.begins_with("VK_SLOT_"):
			mesh.visible = slot_visible(mesh_name, state)
	match state:
		1:
			state_label.text = "1 — MODULAR BASE BODY\nAll hideable body regions visible"
		2:
			state_label.text = "2 — DEFAULT OUTFIT\nBody regions masked beneath equipped slots"
		3:
			state_label.text = "3 — MIXED LOADOUT\nHeadgear and outer torso removed independently"


func base_region_visible(mesh_name: String, state: int) -> bool:
	if state == 1:
		return true
	var permanent := (
		mesh_name.contains("Head")
		or mesh_name.contains("Neck")
		or mesh_name.contains("Mechanical")
		or mesh_name.contains("Mech")
		or mesh_name.contains("PressureGauge")
		or mesh_name.contains("ShoulderCap_L")
	)
	if state == 2:
		return permanent
	# Mixed state removes the outer torso but retains trousers, boots, glove, and waist.
	return permanent or mesh_name.contains("Torso") or mesh_name.contains("UpperArm_R") or mesh_name.contains("Forearm_R")


func slot_visible(mesh_name: String, state: int) -> bool:
	if state == 1:
		return false
	if state == 2:
		return true
	return not (
		mesh_name.begins_with("VK_SLOT_HEADGEAR_")
		or mesh_name.begins_with("VK_SLOT_OUTER_TORSO_")
		or mesh_name.begins_with("VK_SLOT_SHOULDERS_")
	)


func validate_swap_states() -> void:
	var signatures: Array[String] = []
	for state in [1, 2, 3]:
		apply_state(state)
		var visible_body := 0
		var visible_slots := 0
		for mesh in mesh_nodes:
			if not mesh.visible:
				continue
			if String(mesh.name).begins_with("VK_MB01_"):
				visible_body += 1
			elif String(mesh.name).begins_with("VK_SLOT_"):
				visible_slots += 1
		signatures.append("%d:%d" % [visible_body, visible_slots])
	print("VESPER_MODULAR_SWAP_SIGNATURES=", signatures)
	print("VESPER_MODULAR_SWAP_TEST=", "PASS" if signatures.size() == 3 and signatures[0] != signatures[1] and signatures[1] != signatures[2] else "FAIL")
