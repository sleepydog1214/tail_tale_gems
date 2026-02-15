class_name Objective
## Tracks a single level objective (e.g., "Collect 30 Ruby gems").

var type: GemTypes.ObjectiveType = GemTypes.ObjectiveType.COLLECT_COLOR
var params: Dictionary = {}
var current: int = 0
var target: int = 0


func _init(obj_type: GemTypes.ObjectiveType = GemTypes.ObjectiveType.COLLECT_COLOR,
		obj_target: int = 0, obj_params: Dictionary = {}) -> void:
	type = obj_type
	target = obj_target
	params = obj_params
	current = 0


func is_complete() -> bool:
	return current >= target


func add_progress(amount: int = 1) -> void:
	current = mini(current + amount, target)


func get_remaining() -> int:
	return maxi(target - current, 0)


func get_display_text() -> String:
	match type:
		GemTypes.ObjectiveType.COLLECT_COLOR:
			var color_name: String = params.get("color_name", "gems")
			return "%s: %d/%d" % [color_name, current, target]
		GemTypes.ObjectiveType.REMOVE_BLOCKER:
			var blocker_name: String = params.get("blocker_name", "blockers")
			return "%s: %d/%d" % [blocker_name, current, target]
		GemTypes.ObjectiveType.CREATE_POWERUP:
			var powerup_name: String = params.get("powerup_name", "power-ups")
			return "%s: %d/%d" % [powerup_name, current, target]
		GemTypes.ObjectiveType.SCORE_TARGET:
			return "Score: %d/%d" % [current, target]
		_:
			return "%d/%d" % [current, target]


func get_icon_label() -> String:
	## Short label for HUD icons.
	match type:
		GemTypes.ObjectiveType.COLLECT_COLOR:
			return params.get("color_name", "?")[0].to_upper()
		GemTypes.ObjectiveType.REMOVE_BLOCKER:
			return "B"
		GemTypes.ObjectiveType.CREATE_POWERUP:
			return "P"
		GemTypes.ObjectiveType.SCORE_TARGET:
			return "★"
		_:
			return "?"
