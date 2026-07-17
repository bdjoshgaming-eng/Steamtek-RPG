@tool
extends EditorPlugin

func _enter_tree() -> void:
	# The runtime scripts declare class_name themselves. Keeping the editor
	# plug-in passive prevents duplicate global-class registrations.
	pass


func _exit_tree() -> void:
	pass
