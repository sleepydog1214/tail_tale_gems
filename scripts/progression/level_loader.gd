class_name LevelLoader
## Loads level definitions from JSON files and creates BoardState objects.

static func load_level(level_id: int) -> BoardState:
	## Load a level by ID. Searches chapter folders for the matching file.
	var chapter := _get_chapter_for_level(level_id)
	var path := "res://data/levels/chapter_%02d/level_%03d.json" % [chapter, level_id]
	return load_level_from_path(path)


static func load_level_from_path(path: String) -> BoardState:
	## Load a level from a specific JSON file path.
	if not FileAccess.file_exists(path):
		push_error("Level file not found: %s" % path)
		return null

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open level file: %s" % path)
		return null

	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("JSON parse error in %s: %s" % [path, json.get_error_message()])
		return null

	return _build_board_from_json(json.data)


static func _build_board_from_json(data: Dictionary) -> BoardState:
	## Convert parsed JSON into a BoardState.
	var board_data: Dictionary = data.get("board", {})
	var width: int = int(board_data.get("width", 7))
	var height: int = int(board_data.get("height", 9))

	var board := BoardState.new(width, height)
	board.level_id = int(data.get("level_id", 0))
	board.move_limit = int(data.get("move_limit", 25))
	board.move_count = 0
	board.score = 0

	# --- Set up gem pool ---
	var pool_strings: Array = board_data.get("gem_pool", ["RUBY", "SAPPHIRE", "EMERALD", "TOPAZ"])
	var gem_pool: Array[GemTypes.GemColor] = []
	for s in pool_strings:
		var color := GemTypes.color_from_string(s)
		if color != GemTypes.GemColor.NONE:
			gem_pool.append(color)
	board.set_gem_pool(gem_pool)

	# --- Set up board layout ---
	var layout: Array = board_data.get("layout", [])
	for r in range(mini(layout.size(), height)):
		var row_data: Array = layout[r]
		for c in range(mini(row_data.size(), width)):
			var cell := board.get_cell(r, c)
			if row_data[c] == 0:
				cell.is_empty = true
			# Value 1 = normal, 2 = special (handled by special_tiles)

	# --- Place blockers ---
	var blockers: Array = data.get("blockers", [])
	for blocker_data in blockers:
		var row: int = int(blocker_data.get("row", 0))
		var col: int = int(blocker_data.get("col", 0))
		var type_str: String = str(blocker_data.get("type", "CRATE"))
		var hp: int = int(blocker_data.get("hp", 1))
		var cell := board.get_cell(row, col)
		if cell != null:
			cell.set_blocker(GemTypes.blocker_from_string(type_str), hp)

	# --- Set up objectives ---
	var objectives_data: Array = data.get("objectives", [])
	for obj_data in objectives_data:
		var type_str: String = str(obj_data.get("type", "COLLECT_COLOR"))
		var obj_type := GemTypes.objective_from_string(type_str)
		var params: Dictionary = obj_data.get("params", {})
		var obj_target: int = int(params.get("count", 0))

		# Resolve color name for display
		var obj_params: Dictionary = params.duplicate()
		if params.has("color"):
			var color: GemTypes.GemColor = GemTypes.color_from_string(str(params["color"]))
			obj_params["color"] = color
			obj_params["color_name"] = str(GemTypes.COLOR_NAMES.get(color, "???"))
		if params.has("blocker"):
			obj_params["blocker_name"] = str(params["blocker"]).capitalize()
		if params.has("powerup"):
			obj_params["powerup_name"] = str(params["powerup"]).capitalize()
		if params.has("score"):
			obj_target = int(params["score"])

		var objective := Objective.new(obj_type, obj_target, obj_params)
		board.objectives.append(objective)

	# --- Rewards metadata (stored but not used by board directly) ---
	# The game manager reads these from the JSON separately.

	return board


static func _get_chapter_for_level(level_id: int) -> int:
	## Map level ID to chapter number.
	## Chapter 1: levels 1-30, Chapter 2: 31-60, etc.
	return ((level_id - 1) / 30) + 1


static func get_level_rewards(level_id: int) -> Dictionary:
	## Load just the rewards section from a level file.
	var chapter := _get_chapter_for_level(level_id)
	var path := "res://data/levels/chapter_%02d/level_%03d.json" % [chapter, level_id]

	if not FileAccess.file_exists(path):
		return {"coins_base": 50, "coins_per_remaining_move": 5}

	var file := FileAccess.open(path, FileAccess.READ)
	var json_text := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(json_text) != OK:
		return {"coins_base": 50, "coins_per_remaining_move": 5}

	var data_result: Dictionary = json.data.get("rewards", {"coins_base": 50, "coins_per_remaining_move": 5})
	return data_result
