extends Node2D
## Visual representation of the entire match-3 board.
## Phase 2: Full cascade animations — match, fall, spawn each animated step-by-step.

signal animation_finished
signal swap_requested(from_pos: Vector2i, to_pos: Vector2i)

const CELL_SIZE := 64.0
const SWAP_DURATION := 0.15
const FALL_DURATION_PER_ROW := 0.06
const DESTROY_DURATION := 0.18
const SPAWN_DURATION := 0.12
const CASCADE_PAUSE := 0.05

var board_state: BoardState
var match_engine: MatchEngine
var hint_system: HintSystem

var _gem_nodes: Dictionary = {}         # Vector2i -> GemRenderer
var _blocker_nodes: Dictionary = {}     # Vector2i -> BlockerRenderer
var _is_animating: bool = false
var _selected_pos: Vector2i = Vector2i(-1, -1)
var _hint_timer: float = 0.0
var _hinted_pos: Vector2i = Vector2i(-1, -1)

# Background grid
var _board_offset: Vector2 = Vector2.ZERO
var _board_bg_color_a := Color(0.95, 0.85, 0.90, 0.95)
var _board_bg_color_b := Color(0.90, 0.80, 0.88, 0.95)


func _ready() -> void:
	pass


func _process(delta: float) -> void:
	if board_state != null and not _is_animating and not board_state.is_game_over:
		_hint_timer += delta
		if _hint_timer >= 5.0 and _hinted_pos == Vector2i(-1, -1):
			_show_hint()


func initialize(state: BoardState) -> void:
	## Set up the board view from a BoardState.
	board_state = state
	match_engine = MatchEngine.new(state)
	hint_system = HintSystem.new(state)

	# Center the board
	var board_width := state.width * CELL_SIZE
	var board_height := state.height * CELL_SIZE
	_board_offset = Vector2(
		(540 - board_width) / 2.0,  # Center horizontally in viewport
		120  # Leave room for HUD at top
	)
	position = _board_offset

	# Fill the board and create visuals
	match_engine.fill_board_initial()
	_create_all_visuals()
	queue_redraw()


func _create_all_visuals() -> void:
	## Create GemRenderer and BlockerRenderer nodes for every cell.
	# Clear existing
	for node in _gem_nodes.values():
		node.queue_free()
	_gem_nodes.clear()
	for node in _blocker_nodes.values():
		node.queue_free()
	_blocker_nodes.clear()

	for r in range(board_state.height):
		for c in range(board_state.width):
			var cell := board_state.get_cell(r, c)
			var pos := Vector2i(r, c)

			if cell.is_empty:
				continue

			# Create blocker visual if present
			if cell.has_blocker():
				var blocker_node := BlockerRenderer.new()
				blocker_node.setup(cell.blocker_type, cell.blocker_hp, r, c)
				add_child(blocker_node)
				_blocker_nodes[pos] = blocker_node

			# Create gem visual if present
			if cell.has_gem():
				var gem_node := GemRenderer.new()
				gem_node.setup(cell.gem_color, cell.power_up, r, c)
				add_child(gem_node)
				_gem_nodes[pos] = gem_node


func _draw() -> void:
	## Draw the board background grid.
	if board_state == null:
		return

	# Draw outer board frame
	var total_w := board_state.width * CELL_SIZE
	var total_h := board_state.height * CELL_SIZE
	var frame_rect := Rect2(-4, -4, total_w + 8, total_h + 8)
	draw_rect(frame_rect, Color(0.85, 0.72, 0.80, 0.6), true)

	for r in range(board_state.height):
		for c in range(board_state.width):
			var cell := board_state.get_cell(r, c)
			if cell.is_empty:
				continue

			var rect := Rect2(
				c * CELL_SIZE + 2,
				r * CELL_SIZE + 2,
				CELL_SIZE - 4,
				CELL_SIZE - 4
			)

			# Checkerboard pattern
			var base_color: Color
			if (r + c) % 2 == 0:
				base_color = _board_bg_color_a
			else:
				base_color = _board_bg_color_b

			draw_rect(rect, base_color)
			draw_rect(rect, Color(0.80, 0.70, 0.78, 0.4), false, 1.0)


# ============================================================
# INPUT HANDLING
# ============================================================

func handle_input_at(local_pos: Vector2) -> void:
	## Called by the controller with a position relative to board origin.
	if _is_animating or board_state.is_game_over:
		return

	var col := int(local_pos.x / CELL_SIZE)
	var row := int(local_pos.y / CELL_SIZE)

	if not board_state.is_valid_pos(row, col) or not board_state.is_playable(row, col):
		_deselect()
		return

	var clicked := Vector2i(row, col)
	var cell := board_state.get_cell(row, col)

	if not cell.is_swappable():
		_deselect()
		return

	if _selected_pos == Vector2i(-1, -1):
		# First selection
		_select(clicked)
	elif _selected_pos == clicked:
		# Deselect
		_deselect()
	elif _is_adjacent(_selected_pos, clicked):
		# Try swap
		_try_swap(_selected_pos, clicked)
		_deselect()
	else:
		# Select new gem
		_select(clicked)


func handle_swipe(from_pos: Vector2, direction: Vector2) -> void:
	## Handle a swipe gesture starting at from_pos.
	if _is_animating or board_state.is_game_over:
		return

	var col := int(from_pos.x / CELL_SIZE)
	var row := int(from_pos.y / CELL_SIZE)

	if not board_state.is_valid_pos(row, col) or not board_state.is_playable(row, col):
		return

	var from := Vector2i(row, col)
	var to: Vector2i

	# Determine swipe direction
	if abs(direction.x) > abs(direction.y):
		to = Vector2i(row, col + (1 if direction.x > 0 else -1))
	else:
		to = Vector2i(row + (1 if direction.y > 0 else -1), col)

	if board_state.is_valid_pos(to.x, to.y):
		_try_swap(from, to)
		_deselect()


func _select(pos: Vector2i) -> void:
	_deselect()
	_selected_pos = pos
	if _gem_nodes.has(pos):
		_gem_nodes[pos].set_selected(true)
	_clear_hint()
	_hint_timer = 0.0
	AudioManager.play_sfx("select")


func _deselect() -> void:
	if _selected_pos != Vector2i(-1, -1) and _gem_nodes.has(_selected_pos):
		_gem_nodes[_selected_pos].set_selected(false)
	_selected_pos = Vector2i(-1, -1)


func _is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	return abs(a.x - b.x) + abs(a.y - b.y) == 1


func _try_swap(from: Vector2i, to: Vector2i) -> void:
	_is_animating = true
	_clear_hint()
	_hint_timer = 0.0

	# Animate the swap visually first
	var from_node: GemRenderer = _gem_nodes.get(from)
	var to_node: GemRenderer = _gem_nodes.get(to)

	if from_node and to_node:
		var tween := create_tween().set_parallel(true)
		tween.tween_property(from_node, "position",
			GemRenderer.get_board_position(to.x, to.y), SWAP_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(to_node, "position",
			GemRenderer.get_board_position(from.x, from.y), SWAP_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		AudioManager.play_sfx("gem_swap")
		await tween.finished

	# Now try the logical swap (match engine processes all cascades synchronously)
	var success := match_engine.try_swap(from.x, from.y, to.x, to.y)

	if not success:
		# Swap failed — animate back
		AudioManager.play_sfx("no_match")
		if from_node and to_node:
			var tween := create_tween().set_parallel(true)
			tween.tween_property(from_node, "position",
				GemRenderer.get_board_position(from.x, from.y), SWAP_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
			tween.tween_property(to_node, "position",
				GemRenderer.get_board_position(to.x, to.y), SWAP_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
			await tween.finished
		_is_animating = false
	else:
		# Swap succeeded — play cascade animations from recorded log
		await _animate_cascade_log(match_engine.cascade_log)
		_sync_all_visuals()
		_is_animating = false
		_hint_timer = 0.0
		animation_finished.emit()


func _show_hint() -> void:
	if hint_system == null:
		return
	var hint := hint_system.find_best_hint()
	if hint.is_empty():
		return
	var from: Vector2i = hint["from"]
	var to: Vector2i = hint["to"]
	_hinted_pos = from
	if _gem_nodes.has(from):
		_gem_nodes[from].is_hinted = true
	if _gem_nodes.has(to):
		_gem_nodes[to].is_hinted = true
	AudioManager.play_sfx("hint_show")


func _clear_hint() -> void:
	if _hinted_pos != Vector2i(-1, -1):
		for node in _gem_nodes.values():
			node.is_hinted = false
	_hinted_pos = Vector2i(-1, -1)


# ============================================================
# CASCADE ANIMATION PLAYBACK
# ============================================================

func _animate_cascade_log(log: Array) -> void:
	## Replay recorded cascade steps with animations.
	for step in log:
		var matched: Array = step.get("matched_positions", [])
		var falls: Array = step.get("falls", [])
		var spawns: Array = step.get("spawns", [])
		var depth: int = step.get("depth", 1)

		# Step 1: Animate matched gem destruction
		if not matched.is_empty():
			await _animate_destroy(matched, depth)

		# Small pause between destroy and fall
		if not falls.is_empty() or not spawns.is_empty():
			await get_tree().create_timer(CASCADE_PAUSE).timeout

		# Step 2: Animate gems falling
		if not falls.is_empty():
			await _animate_falls(falls)

		# Step 3: Animate new gems spawning
		if not spawns.is_empty():
			await _animate_spawns(spawns)

		# Brief pause between cascade steps
		if log.size() > 1:
			await get_tree().create_timer(CASCADE_PAUSE).timeout


func _animate_destroy(matched_positions: Array, cascade_depth: int) -> void:
	## Animate matched gems shrinking and flashing before removal.
	var tween := create_tween().set_parallel(true)
	var any_animated := false

	for pos in matched_positions:
		if not _gem_nodes.has(pos):
			continue
		var node: GemRenderer = _gem_nodes[pos]
		any_animated = true

		# Flash white then scale to zero
		node.modulate = Color(2.0, 2.0, 2.0, 1.0)
		tween.tween_property(node, "scale", Vector2.ZERO, DESTROY_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
		tween.tween_property(node, "modulate", Color(1, 1, 1, 0), DESTROY_DURATION)

		# Spawn particle burst at each destroyed gem
		var world_pos: Vector2 = GemRenderer.get_board_position(pos.x, pos.y) + position
		var cell := board_state.get_cell(pos.x, pos.y)
		var gem_color: Color = Color.WHITE
		if cell != null and cell.has_gem():
			gem_color = GemTypes.COLOR_HEX.get(cell.gem_color, Color.WHITE)
		ParticleEffects.spawn_gem_burst(get_tree().root, world_pos, gem_color)

	if any_animated:
		# Play match SFX
		if cascade_depth <= 1:
			AudioManager.play_sfx("gem_match")
		else:
			AudioManager.play_sfx("cascade")
		await tween.finished

		# Spawn score popup at center of matched area
		if cascade_depth >= 1:
			var center := _get_center_of_positions(matched_positions)
			_spawn_score_popup(center, matched_positions.size() * 10, cascade_depth)

		# Cascade sparkles for combo chains
		if cascade_depth >= 2:
			var center := _get_center_of_positions(matched_positions)
			ParticleEffects.spawn_cascade_sparkle(get_tree().root, center + position, cascade_depth)

	# Remove destroyed gem nodes
	for pos in matched_positions:
		if _gem_nodes.has(pos):
			_gem_nodes[pos].queue_free()
			_gem_nodes.erase(pos)


func _animate_falls(movements: Array) -> void:
	## Animate gems falling to new positions.
	var tween := create_tween().set_parallel(true)
	var any_animated := false
	var moved_nodes: Array = []

	for move in movements:
		var from: Vector2i = move["from"]
		var to: Vector2i = move["to"]
		if not _gem_nodes.has(from):
			continue

		var node: GemRenderer = _gem_nodes[from]
		_gem_nodes.erase(from)
		moved_nodes.append({"node": node, "to": to})

		var distance: int = absi(to.x - from.x)
		var duration: float = distance * FALL_DURATION_PER_ROW
		any_animated = true

		tween.tween_property(node, "position",
			GemRenderer.get_board_position(to.x, to.y), duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		node.board_row = to.x
		node.board_col = to.y

	for data in moved_nodes:
		_gem_nodes[data["to"]] = data["node"]

	if any_animated:
		await tween.finished
		AudioManager.play_sfx("gem_land")


func _animate_spawns(spawns: Array) -> void:
	## Animate new gems appearing with a scale-up effect.
	var tween := create_tween().set_parallel(true)
	var any_animated := false

	for spawn in spawns:
		var pos: Vector2i = spawn["pos"]
		var color: int = spawn["color"]

		var gem_node := GemRenderer.new()
		var pu := GemTypes.PowerUpType.NONE
		var cell := board_state.get_cell(pos.x, pos.y)
		if cell != null and cell.has_power_up():
			pu = cell.power_up
		gem_node.setup(color as GemTypes.GemColor, pu, pos.x, pos.y)
		gem_node.scale = Vector2.ZERO
		add_child(gem_node)
		_gem_nodes[pos] = gem_node
		any_animated = true

		tween.tween_property(gem_node, "scale", Vector2.ONE, SPAWN_DURATION).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	if any_animated:
		await tween.finished


# ============================================================
# SCORE POPUPS
# ============================================================

func _spawn_score_popup(board_pos: Vector2, points: int, cascade: int) -> void:
	## Show a floating score number at a board position.
	var label := Label.new()
	if cascade > 1:
		label.text = "+%d x%d" % [points, cascade]
	else:
		label.text = "+%d" % points
	label.add_theme_font_size_override("font_size", 16 + cascade * 2)
	label.add_theme_color_override("font_color", Color("e84393") if cascade <= 1 else Color("fd79a8"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = board_pos - Vector2(30, 10)
	label.z_index = 100
	add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 40, 0.6).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)


func _get_center_of_positions(positions: Array) -> Vector2:
	var sum := Vector2.ZERO
	for pos in positions:
		sum += GemRenderer.get_board_position(pos.x, pos.y)
	return sum / float(positions.size())


# ============================================================
# VISUAL SYNC
# ============================================================

func _sync_all_visuals() -> void:
	## Rebuild all visuals to match current board state (safety net after animations).

	# Remove gem nodes that no longer have gems
	var to_remove: Array = []
	for pos in _gem_nodes:
		var cell := board_state.get_cell(pos.x, pos.y)
		if cell == null or not cell.has_gem():
			to_remove.append(pos)

	for pos in to_remove:
		_gem_nodes[pos].queue_free()
		_gem_nodes.erase(pos)

	# Update existing and create missing gem nodes
	for r in range(board_state.height):
		for c in range(board_state.width):
			var cell := board_state.get_cell(r, c)
			var pos := Vector2i(r, c)

			if cell.is_empty:
				continue

			if cell.has_gem():
				if _gem_nodes.has(pos):
					var node: GemRenderer = _gem_nodes[pos]
					node.update_visual(cell.gem_color, cell.power_up)
					node.position = GemRenderer.get_board_position(r, c)
					node.scale = Vector2.ONE
					node.modulate = Color.WHITE
					node.board_row = r
					node.board_col = c
				else:
					var gem_node := GemRenderer.new()
					gem_node.setup(cell.gem_color, cell.power_up, r, c)
					add_child(gem_node)
					_gem_nodes[pos] = gem_node
			else:
				if _gem_nodes.has(pos):
					_gem_nodes[pos].queue_free()
					_gem_nodes.erase(pos)

	# Sync blockers
	var blocker_remove: Array = []
	for pos in _blocker_nodes:
		var cell := board_state.get_cell(pos.x, pos.y)
		if cell == null or not cell.has_blocker():
			blocker_remove.append(pos)
	for pos in blocker_remove:
		_blocker_nodes[pos].queue_free()
		_blocker_nodes.erase(pos)

	# Add or update blockers
	for r in range(board_state.height):
		for c in range(board_state.width):
			var cell := board_state.get_cell(r, c)
			var pos := Vector2i(r, c)
			if cell.is_empty:
				continue
			if cell.has_blocker() and not _blocker_nodes.has(pos):
				var blocker_node := BlockerRenderer.new()
				blocker_node.setup(cell.blocker_type, cell.blocker_hp, r, c)
				add_child(blocker_node)
				_blocker_nodes[pos] = blocker_node
			elif _blocker_nodes.has(pos) and cell.has_blocker():
				_blocker_nodes[pos].update_hp(cell.blocker_hp)


func get_animating() -> bool:
	return _is_animating
