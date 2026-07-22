extends Node
class_name SteamtekLocalTalentBridge

## Minimal stand-in for main.gd's public surface that KeystoneViewer.gd
## expects on its `main` field. The talent tree data itself
## (GameData.novice_professions) is real, shared, global state — this
## stub only supplies the small per-player bits KeystoneViewer reads
## directly off `main` (XP pools, profession flags, its toast message).

signal message_requested(text: String)

var xp_pools: Dictionary = {"Combat XP": 0, "Crafting XP": 0}
var professions_unlocked: Dictionary = {"Street Thug": true}


func _show_combat_message(text: String) -> void:
	message_requested.emit(text)
