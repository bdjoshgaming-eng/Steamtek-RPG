class_name SteamtekItemIconRegistry
extends RefCounted

## Central lookup for placeholder item icons: a category color + a short
## abbreviation, no texture assets required. Swapping in real icon art
## later means editing this file only — callers just ask for
## `resolve(item_name)` and never touch category data directly.

const CATEGORY_STYLES := {
	"Weapon": {"color": Color(0.42, 0.44, 0.48)},
	"Metal": {"color": Color(0.35, 0.42, 0.5)},
	"Mineral": {"color": Color(0.4, 0.48, 0.52)},
	"Polymer": {"color": Color(0.3, 0.4, 0.46)},
	"Chemical": {"color": Color(0.28, 0.55, 0.32)},
	"Organic": {"color": Color(0.42, 0.5, 0.22)},
	"Salvage": {"color": Color(0.5, 0.4, 0.24)},
	"Steamtek": {"color": Color(0.55, 0.42, 0.16)},
	"Consumable": {"color": Color(0.62, 0.22, 0.22)},
	"Quest Item": {"color": Color(0.55, 0.32, 0.62)},
	"Mod": {"color": Color(0.6, 0.5, 0.15)},
	"Misc": {"color": Color(0.32, 0.32, 0.36)},
}

const ITEM_OVERRIDES := {
	"Riveted Knuckles": {"category": "Weapon", "abbreviation": "RK"},
	"Rusty Pistol": {"category": "Weapon", "abbreviation": "RP"},
	"Canister Launcher": {"category": "Weapon", "abbreviation": "GL"},
	"Crate of Bandages": {"category": "Consumable", "abbreviation": "BND"},
	"Mineral Survey Tool": {"category": "Mod", "abbreviation": "SVY"},
	"Rusty Crafting Kit": {"category": "Mod", "abbreviation": "KIT"},
	"Iron Scope": {"category": "Mod", "abbreviation": "SCP"},
	"Piston Blade": {"category": "Weapon", "abbreviation": "PB"},
	"Arc Rod": {"category": "Weapon", "abbreviation": "AR"},
	"Antiseptic Salve": {"category": "Consumable", "abbreviation": "SLV"},
	"Weapon Core": {"category": "Mod", "abbreviation": "CORE"},
}


static func resolve(item_name: String) -> Dictionary:
	if ITEM_OVERRIDES.has(item_name):
		var entry: Dictionary = ITEM_OVERRIDES[item_name]
		return {
			"category": entry.get("category", "Misc"),
			"abbreviation": entry.get("abbreviation", _fallback_abbreviation(item_name)),
			"color": CATEGORY_STYLES.get(entry.get("category", "Misc"), CATEGORY_STYLES["Misc"])["color"],
		}

	var family_category := _resolve_family_category(item_name)
	if family_category != "":
		return {
			"category": family_category,
			"abbreviation": _fallback_abbreviation(item_name),
			"color": CATEGORY_STYLES.get(family_category, CATEGORY_STYLES["Misc"])["color"],
		}

	return {
		"category": "Misc",
		"abbreviation": _fallback_abbreviation(item_name),
		"color": CATEGORY_STYLES["Misc"]["color"],
	}


static func _resolve_family_category(item_name: String) -> String:
	var families: Dictionary = CraftingData.RESOURCE_FAMILIES.duplicate()
	families.merge(CraftingData.RESOURCE_FAMILIES_EXTRA)
	for family_id in families.keys():
		var entry: Dictionary = families[family_id]
		if String(entry.get("display_name", "")) == item_name:
			return String(entry.get("category", "Misc"))
	return ""


static func _fallback_abbreviation(item_name: String) -> String:
	var words := item_name.split(" ", false)
	var abbreviation := ""
	for word in words:
		if word.length() > 0:
			abbreviation += word.substr(0, 1).to_upper()
		if abbreviation.length() >= 3:
			break
	if abbreviation == "":
		abbreviation = item_name.substr(0, mini(3, item_name.length())).to_upper()
	return abbreviation
