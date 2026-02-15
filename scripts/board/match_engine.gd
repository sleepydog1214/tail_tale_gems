class_name MatchEngine
## Core match-3 logic engine. Pure logic — no rendering.
##
## Responsibilities:
## - Detect matches (3+, L/T, lines)
## - Determine power-up creation from match shapes
## - Process power-up activations and combinations
## - Apply gravity (gems fall down)
## - Spawn new gems
## - Process cascades (repeat until stable)
## - Track objective progress
## - Handle blocker adjacency hits

# --- Signals (for the renderer to listen to) ---
signal gems_matched(matches: Array)
signal gems_fell(movements: Array)
signal gems_spawned(spawns: Array)
signal power_up_activated(pos: Vector2i, type: int, affected: Array)
signal blockers_hit(hits: Array)
signal board_stable()
signal objective_progress(obj_index: int, new_value: int)
signal score_changed(new_score: int)
signal cascade_started(depth: int)

var board: BoardState

## Cascade step recording for animated playback
var cascade_log: Array = []  # Array of cascade step dictionaries


func _init(board_state: BoardState = null) -> void:
	board = board_state


func set_board(board_state: BoardState) -> void:
	board = board_state


# ============================================================
# PUBLIC API
# ============================================================

func try_swap(r1: int, c1: int, r2: int, c2: int) -> bool:
	## Attempt to swap two adjacent gems. Returns true if the swap is valid
	## (creates a match). Consumes a move on success.
	if board == null or board.is_game_over:
		return false

	# Validate adjacency
	if abs(r1 - r2) + abs(c1 - c2) != 1:
		return false

	var cell1 := board.get_cell(r1, c1)
	var cell2 := board.get_cell(r2, c2)

	if cell1 == null or cell2 == null:
		return false

	# Special case: swapping two power-ups
	if cell1.has_power_up() and cell2.has_power_up():
		_do_swap(r1, c1, r2, c2)
		board.move_count += 1
		_activate_power_up_combo(r1, c1, r2, c2)
		_process_cascade()
		board.check_game_state()
		return true

	# Special case: swapping a prism with any gem
	if cell1.power_up == GemTypes.PowerUpType.PRISM and cell2.has_gem():
		_do_swap(r1, c1, r2, c2)
		board.move_count += 1
		_activate_prism(r1, c1, cell2.gem_color)
		_process_cascade()
		board.check_game_state()
		return true
	if cell2.power_up == GemTypes.PowerUpType.PRISM and cell1.has_gem():
		_do_swap(r1, c1, r2, c2)
		board.move_count += 1
		_activate_prism(r2, c2, cell1.gem_color)
		_process_cascade()
		board.check_game_state()
		return true

	# Normal swap: check if valid
	if not cell1.is_swappable() or not cell2.is_swappable():
		return false

	# Perform swap
	_do_swap(r1, c1, r2, c2)

	# Check if this creates a match
	if not board._check_match_at(r1, c1) and not board._check_match_at(r2, c2):
		# No match — swap back
		_do_swap(r1, c1, r2, c2)
		return false

	# Valid swap — consume move
	board.move_count += 1
	board.cascade_depth = 0

	# Process all matches and cascades
	_process_cascade()

	# Check win/loss
	board.check_game_state()

	# Auto-shuffle if stuck
	if not board.is_game_over and not board.has_valid_moves():
		_shuffle_board()

	return true


func fill_board_initial() -> void:
	## Fill the board with random gems, ensuring no initial matches.
	if board == null:
		return
	for r in range(board.height):
		for c in range(board.width):
			var cell := board.get_cell(r, c)
			if cell.is_empty or cell.has_blocker():
				continue
			if cell.has_gem():
				continue  # Pre-placed gem
			_place_gem_no_match(r, c)

	# Ensure at least one valid move exists
	if not board.has_valid_moves():
		_shuffle_board()


# ============================================================
# MATCH DETECTION
# ============================================================

func find_all_matches() -> Array:
	## Find all groups of 3+ matched gems on the board.
	## Returns Array of match groups. Each group is a Dictionary:
	## { "cells": Array[Vector2i], "shape": String, "color": GemColor }
	## shape: "line3", "line4", "line5", "L", "T"
	var visited := {}
	var all_matches: Array = []

	# Find horizontal runs
	for r in range(board.height):
		var c := 0
		while c < board.width:
			var cell := board.get_cell(r, c)
			if not cell.is_matchable():
				c += 1
				continue
			var color := cell.gem_color
			var run_start := c
			var run_end := c
			while run_end + 1 < board.width:
				var next := board.get_cell(r, run_end + 1)
				if next.is_matchable() and next.gem_color == color:
					run_end += 1
				else:
					break
			var run_length := run_end - run_start + 1
			if run_length >= 3:
				var cells: Array[Vector2i] = []
				for cc in range(run_start, run_end + 1):
					cells.append(Vector2i(r, cc))
				all_matches.append({
					"cells": cells,
					"color": color,
					"direction": "horizontal",
				})
			c = run_end + 1

	# Find vertical runs
	for c in range(board.width):
		var r := 0
		while r < board.height:
			var cell := board.get_cell(r, c)
			if not cell.is_matchable():
				r += 1
				continue
			var color := cell.gem_color
			var run_start := r
			var run_end := r
			while run_end + 1 < board.height:
				var next := board.get_cell(run_end + 1, c)
				if next.is_matchable() and next.gem_color == color:
					run_end += 1
				else:
					break
			var run_length := run_end - run_start + 1
			if run_length >= 3:
				var cells: Array[Vector2i] = []
				for rr in range(run_start, run_end + 1):
					cells.append(Vector2i(rr, c))
				all_matches.append({
					"cells": cells,
					"color": color,
					"direction": "vertical",
				})
			r = run_end + 1

	# Merge overlapping matches to detect L/T shapes
	return _merge_and_classify_matches(all_matches)


func _merge_and_classify_matches(raw_matches: Array) -> Array:
	## Merge overlapping match runs to detect L and T shapes,
	## then classify each merged group for power-up determination.
	if raw_matches.is_empty():
		return []

	# Build a set of all matched positions per color
	var color_groups: Dictionary = {}  # GemColor -> Array of raw match indices
	for i in range(raw_matches.size()):
		var m = raw_matches[i]
		var color: int = m["color"]
		if not color_groups.has(color):
			color_groups[color] = []
		color_groups[color].append(i)

	var result: Array = []

	for color in color_groups:
		var indices: Array = color_groups[color]
		# Union-find to merge overlapping matches of the same color
		var all_cells_by_match: Array = []
		for idx in indices:
			var cell_set := {}
			for pos in raw_matches[idx]["cells"]:
				cell_set[pos] = true
			all_cells_by_match.append(cell_set)

		# Merge sets that share any cell
		var merged := _merge_overlapping_sets(all_cells_by_match)

		for group_set in merged:
			var cells: Array[Vector2i] = []
			for pos in group_set:
				cells.append(pos as Vector2i)

			# Classify the shape
			var classification := _classify_match_shape(cells)
			result.append({
				"cells": cells,
				"color": color,
				"shape": classification["shape"],
				"power_up_type": classification["power_up_type"],
				"power_up_pos": classification["power_up_pos"],
			})

	return result


func _merge_overlapping_sets(sets: Array) -> Array:
	## Merge any sets that share at least one element.
	var parent: Array = []
	for i in range(sets.size()):
		parent.append(i)

	# Find root with path compression
	var find_root := func(x: int) -> int:
		while parent[x] != x:
			parent[x] = parent[parent[x]]
			x = parent[x]
		return x

	# Union sets that overlap
	for i in range(sets.size()):
		for j in range(i + 1, sets.size()):
			var overlaps := false
			for key in sets[i]:
				if sets[j].has(key):
					overlaps = true
					break
			if overlaps:
				var ri: int = find_root.call(i)
				var rj: int = find_root.call(j)
				parent[ri] = rj

	# Group by root
	var groups: Dictionary = {}
	for i in range(sets.size()):
		var root: int = find_root.call(i)
		if not groups.has(root):
			groups[root] = {}
		for key in sets[i]:
			groups[root][key] = true

	var result: Array = []
	for group in groups.values():
		result.append(group)
	return result


func _classify_match_shape(cells: Array[Vector2i]) -> Dictionary:
	## Given a connected group of matched cells, determine the shape
	## and what power-up should be created.
	var count := cells.size()

	# Find bounding box and runs
	var min_r := 999
	var max_r := -1
	var min_c := 999
	var max_c := -1
	var cell_set := {}
	for pos in cells:
		min_r = mini(min_r, pos.x)
		max_r = maxi(max_r, pos.x)
		min_c = mini(min_c, pos.y)
		max_c = maxi(max_c, pos.y)
		cell_set[pos] = true

	var row_span := max_r - min_r + 1
	var col_span := max_c - min_c + 1

	# Find the center of the group (for power-up placement)
	var center: Vector2i = cells[cells.size() / 2]

	# 5+ in a straight line → PRISM
	if count >= 5 and (row_span == 1 or col_span == 1):
		return {
			"shape": "line5",
			"power_up_type": GemTypes.PowerUpType.PRISM,
			"power_up_pos": center,
		}

	# L or T shape (5+ cells spanning both rows and columns) → BOMB
	if count >= 5 and row_span > 1 and col_span > 1:
		# Find the intersection point for power-up placement
		var intersection := _find_intersection(cells, cell_set)
		return {
			"shape": "LT",
			"power_up_type": GemTypes.PowerUpType.BOMB,
			"power_up_pos": intersection if intersection != Vector2i(-1, -1) else center,
		}

	# 4 in a line → ROCKET
	if count == 4:
		if row_span == 1:
			return {
				"shape": "line4",
				"power_up_type": GemTypes.PowerUpType.ROCKET_V,  # Horizontal match → vertical rocket
				"power_up_pos": center,
			}
		else:
			return {
				"shape": "line4",
				"power_up_type": GemTypes.PowerUpType.ROCKET_H,  # Vertical match → horizontal rocket
				"power_up_pos": center,
			}

	# Count >= 5 but in a line detected above; if we get here with 5+ it may be
	# an L/T with exactly 5, which was caught above. Default large group → BOMB
	if count >= 5:
		var intersection := _find_intersection(cells, cell_set)
		return {
			"shape": "LT",
			"power_up_type": GemTypes.PowerUpType.BOMB,
			"power_up_pos": intersection if intersection != Vector2i(-1, -1) else center,
		}

	# 3 in a line → no power-up
	return {
		"shape": "line3",
		"power_up_type": GemTypes.PowerUpType.NONE,
		"power_up_pos": Vector2i(-1, -1),
	}


func _find_intersection(cells: Array[Vector2i], cell_set: Dictionary) -> Vector2i:
	## Find a cell that has neighbors in both horizontal and vertical directions.
	for pos in cells:
		var has_h := cell_set.has(Vector2i(pos.x, pos.y - 1)) or cell_set.has(Vector2i(pos.x, pos.y + 1))
		var has_v := cell_set.has(Vector2i(pos.x - 1, pos.y)) or cell_set.has(Vector2i(pos.x + 1, pos.y))
		if has_h and has_v:
			return pos
	return Vector2i(-1, -1)


# ============================================================
# MATCH PROCESSING
# ============================================================

func _process_cascade() -> void:
	## Main cascade loop: find matches → remove → gravity → spawn → repeat.
	cascade_log.clear()
	var cascade_count := 0
	while true:
		var matches := find_all_matches()
		if matches.is_empty():
			break

		cascade_count += 1
		board.cascade_depth = cascade_count
		cascade_started.emit(cascade_count)

		# Process all matches
		var matched_positions := _process_matches(matches)

		# Apply gravity
		var falls := _apply_gravity()
		if not falls.is_empty():
			gems_fell.emit(falls)

		# Spawn new gems
		var spawns := _spawn_gems()
		if not spawns.is_empty():
			gems_spawned.emit(spawns)

		# Record this cascade step for animated playback
		cascade_log.append({
			"depth": cascade_count,
			"matches": matches,
			"matched_positions": matched_positions,
			"falls": falls,
			"spawns": spawns,
		})

	board_stable.emit()


func _process_matches(matches: Array) -> Array:
	## Remove matched gems, create power-ups, hit adjacent blockers, update objectives.
	## Returns array of matched positions (for animation recording).
	var all_matched_positions := {}
	var power_ups_to_create: Array = []
	var blocker_hits: Array = []

	for match_group in matches:
		var cells: Array = match_group["cells"]
		var color: int = match_group["color"]
		var pu_type: int = match_group["power_up_type"]
		var pu_pos: Vector2i = match_group["power_up_pos"]

		for pos in cells:
			all_matched_positions[pos] = color

		# Track power-up creation
		if pu_type != GemTypes.PowerUpType.NONE and pu_pos != Vector2i(-1, -1):
			power_ups_to_create.append({
				"pos": pu_pos,
				"type": pu_type,
				"color": color,
			})

	# Emit match signal
	gems_matched.emit(matches)

	# Hit adjacent blockers for each matched position
	for pos in all_matched_positions:
		var adj_hits := _hit_adjacent_blockers(pos.x, pos.y)
		blocker_hits.append_array(adj_hits)

	if not blocker_hits.is_empty():
		blockers_hit.emit(blocker_hits)

	# Update objectives
	_update_objectives_for_matches(all_matched_positions, blocker_hits, power_ups_to_create)

	# Remove matched gems (but keep power-up creation positions)
	var pu_positions := {}
	for pu in power_ups_to_create:
		pu_positions[pu["pos"]] = pu

	for pos in all_matched_positions:
		var cell := board.get_cell(pos.x, pos.y)
		if cell == null:
			continue

		# Handle blocker layers on matched gems (ice, chain)
		if cell.blocker_type == GemTypes.BlockerType.ICE or cell.blocker_type == GemTypes.BlockerType.CHAIN:
			cell.hit_blocker()

		# If this position gets a power-up, set it instead of clearing
		if pu_positions.has(pos):
			var pu_info: Dictionary = pu_positions[pos]
			cell.gem_color = pu_info["color"] as GemTypes.GemColor
			cell.power_up = pu_info["type"] as GemTypes.PowerUpType
		else:
			# Check if the gem had a power-up that should activate
			if cell.has_power_up():
				_activate_power_up(pos.x, pos.y)
			cell.clear_gem()

	# Calculate score
	var match_score := _calculate_match_score(all_matched_positions.size(), board.cascade_depth)
	board.score += match_score
	score_changed.emit(board.score)

	# Return matched positions for animation
	var result: Array = []
	for pos in all_matched_positions:
		result.append(pos)
	return result


func _calculate_match_score(gems_cleared: int, cascade: int) -> int:
	## Score formula: base per gem × cascade multiplier.
	var base := gems_cleared * 10
	var cascade_bonus := cascade * 5
	return base + (base * cascade_bonus / 100)


# ============================================================
# POWER-UP ACTIVATION
# ============================================================

func _activate_power_up(row: int, col: int) -> void:
	## Activate a single power-up at the given position.
	var cell := board.get_cell(row, col)
	if cell == null or not cell.has_power_up():
		return

	var pu_type := cell.power_up
	cell.power_up = GemTypes.PowerUpType.NONE
	var affected: Array[Vector2i] = []

	match pu_type:
		GemTypes.PowerUpType.ROCKET_H:
			affected = _rocket_horizontal(row, col)
		GemTypes.PowerUpType.ROCKET_V:
			affected = _rocket_vertical(row, col)
		GemTypes.PowerUpType.BOMB:
			affected = _bomb_explode(row, col)
		GemTypes.PowerUpType.PRISM:
			# Prism without a target color: pick the most common on board
			var target_color := _most_common_color()
			affected = _prism_clear(target_color)

	power_up_activated.emit(Vector2i(row, col), pu_type, affected)

	# Clear affected cells
	for pos in affected:
		var target := board.get_cell(pos.x, pos.y)
		if target == null:
			continue
		if target.has_blocker():
			var destroyed := target.hit_blocker()
			if destroyed:
				_track_blocker_destroyed(target.blocker_type)
		if target.has_power_up() and pos != Vector2i(row, col):
			# Chain reaction
			_activate_power_up(pos.x, pos.y)
		if target.has_gem():
			_track_gem_cleared(target.gem_color)
			target.clear_gem()


func _activate_prism(row: int, col: int, target_color: GemTypes.GemColor) -> void:
	## Activate a Prism targeting a specific color.
	var cell := board.get_cell(row, col)
	if cell != null:
		cell.power_up = GemTypes.PowerUpType.NONE

	var affected := _prism_clear(target_color)
	power_up_activated.emit(Vector2i(row, col), GemTypes.PowerUpType.PRISM, affected)

	for pos in affected:
		var target := board.get_cell(pos.x, pos.y)
		if target == null:
			continue
		if target.has_power_up():
			_activate_power_up(pos.x, pos.y)
		if target.has_gem():
			_track_gem_cleared(target.gem_color)
			target.clear_gem()


func _activate_power_up_combo(r1: int, c1: int, r2: int, c2: int) -> void:
	## Handle two power-ups being swapped together.
	var cell1 := board.get_cell(r1, c1)
	var cell2 := board.get_cell(r2, c2)
	if cell1 == null or cell2 == null:
		return

	var type1 := cell1.power_up
	var type2 := cell2.power_up
	cell1.power_up = GemTypes.PowerUpType.NONE
	cell2.power_up = GemTypes.PowerUpType.NONE

	var affected: Array[Vector2i] = []

	# Sort types for easier matching
	var types: Array = [type1, type2]
	types.sort()

	# Prism + Prism = clear entire board
	if type1 == GemTypes.PowerUpType.PRISM and type2 == GemTypes.PowerUpType.PRISM:
		for r in range(board.height):
			for c in range(board.width):
				if board.is_playable(r, c) and board.get_cell(r, c).has_gem():
					affected.append(Vector2i(r, c))

	# Prism + Rocket = all gems of rocket's color become rockets
	elif GemTypes.PowerUpType.PRISM in types and (GemTypes.PowerUpType.ROCKET_H in types or GemTypes.PowerUpType.ROCKET_V in types):
		var target_color := cell1.gem_color if type1 == GemTypes.PowerUpType.PRISM else cell2.gem_color
		if target_color == GemTypes.GemColor.NONE:
			target_color = _most_common_color()
		var color_positions := board.get_all_gems_of_color(target_color)
		for pos in color_positions:
			var target := board.get_cell(pos.x, pos.y)
			target.power_up = GemTypes.PowerUpType.ROCKET_H if randi() % 2 == 0 else GemTypes.PowerUpType.ROCKET_V
			_activate_power_up(pos.x, pos.y)
			affected.append(pos)

	# Prism + Bomb = all gems of bomb's color become bombs
	elif GemTypes.PowerUpType.PRISM in types and GemTypes.PowerUpType.BOMB in types:
		var target_color := cell1.gem_color if type1 == GemTypes.PowerUpType.PRISM else cell2.gem_color
		if target_color == GemTypes.GemColor.NONE:
			target_color = _most_common_color()
		var color_positions := board.get_all_gems_of_color(target_color)
		for pos in color_positions:
			var target := board.get_cell(pos.x, pos.y)
			target.power_up = GemTypes.PowerUpType.BOMB
			_activate_power_up(pos.x, pos.y)
			affected.append(pos)

	# Rocket + Rocket = cross (full row + full column)
	elif type1 in [GemTypes.PowerUpType.ROCKET_H, GemTypes.PowerUpType.ROCKET_V] and \
		 type2 in [GemTypes.PowerUpType.ROCKET_H, GemTypes.PowerUpType.ROCKET_V]:
		var mid_r := r1
		var mid_c := c1
		affected.append_array(_rocket_horizontal(mid_r, mid_c))
		affected.append_array(_rocket_vertical(mid_r, mid_c))

	# Rocket + Bomb = 3 rows + 3 columns
	elif (GemTypes.PowerUpType.BOMB in types) and \
		 (GemTypes.PowerUpType.ROCKET_H in types or GemTypes.PowerUpType.ROCKET_V in types):
		var mid_r := r1
		var mid_c := c1
		for dr in range(-1, 2):
			if mid_r + dr >= 0 and mid_r + dr < board.height:
				affected.append_array(_rocket_horizontal(mid_r + dr, mid_c))
		for dc in range(-1, 2):
			if mid_c + dc >= 0 and mid_c + dc < board.width:
				affected.append_array(_rocket_vertical(mid_r, mid_c + dc))

	# Bomb + Bomb = 5x5 area
	elif type1 == GemTypes.PowerUpType.BOMB and type2 == GemTypes.PowerUpType.BOMB:
		var mid_r := r1
		var mid_c := c1
		for dr in range(-2, 3):
			for dc in range(-2, 3):
				var tr := mid_r + dr
				var tc := mid_c + dc
				if board.is_valid_pos(tr, tc) and board.is_playable(tr, tc):
					affected.append(Vector2i(tr, tc))

	power_up_activated.emit(Vector2i(r1, c1), type1, affected)

	# Clear all affected
	for pos in affected:
		var target := board.get_cell(pos.x, pos.y)
		if target == null:
			continue
		if target.has_blocker():
			target.hit_blocker()
		if target.has_gem():
			_track_gem_cleared(target.gem_color)
			target.clear_gem()


func _rocket_horizontal(row: int, _col: int) -> Array[Vector2i]:
	var affected: Array[Vector2i] = []
	for c in range(board.width):
		if board.is_playable(row, c):
			affected.append(Vector2i(row, c))
	return affected


func _rocket_vertical(_row: int, col: int) -> Array[Vector2i]:
	var affected: Array[Vector2i] = []
	for r in range(board.height):
		if board.is_playable(r, col):
			affected.append(Vector2i(r, col))
	return affected


func _bomb_explode(row: int, col: int) -> Array[Vector2i]:
	var affected: Array[Vector2i] = []
	for dr in range(-1, 2):
		for dc in range(-1, 2):
			var tr := row + dr
			var tc := col + dc
			if board.is_valid_pos(tr, tc) and board.is_playable(tr, tc):
				affected.append(Vector2i(tr, tc))
	return affected


func _prism_clear(target_color: GemTypes.GemColor) -> Array[Vector2i]:
	return board.get_all_gems_of_color(target_color)


func _most_common_color() -> GemTypes.GemColor:
	var counts: Dictionary = {}
	for color in board.gem_pool:
		counts[color] = 0
	for r in range(board.height):
		for c in range(board.width):
			var cell := board.get_cell(r, c)
			if cell.has_gem():
						counts[cell.gem_color] = int(counts.get(cell.gem_color, 0)) + 1
	var best_color: GemTypes.GemColor = board.gem_pool[0] if not board.gem_pool.is_empty() else GemTypes.GemColor.RUBY
	var best_count := 0
	for color in counts:
		if counts[color] > best_count:
			best_count = counts[color]
			best_color = color
	return best_color


# ============================================================
# BLOCKER HANDLING
# ============================================================

func _hit_adjacent_blockers(row: int, col: int) -> Array:
	## Hit blockers adjacent to a matched gem. Returns array of hit info.
	var hits: Array = []
	var directions: Array[Vector2i] = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
	for dir in directions:
		var tr := row + dir.x
		var tc := col + dir.y
		var cell := board.get_cell(tr, tc)
		if cell == null:
			continue
		if cell.has_blocker() and cell.blocker_type in [
			GemTypes.BlockerType.CRATE,
			GemTypes.BlockerType.REINFORCED_CRATE,
			GemTypes.BlockerType.VASE,
		]:
			var destroyed := cell.hit_blocker()
			hits.append({"pos": Vector2i(tr, tc), "destroyed": destroyed})
			if destroyed:
				_track_blocker_destroyed(cell.blocker_type)
	return hits


# ============================================================
# GRAVITY & SPAWNING
# ============================================================

func _apply_gravity() -> Array:
	## Make gems fall down to fill empty spaces. Returns movement list.
	var movements: Array = []

	# Process each column from bottom to top
	for c in range(board.width):
		var write_row := board.height - 1  # Bottom of column

		# Find the lowest empty playable cell
		while write_row >= 0:
			if board.is_playable(write_row, c) and not board.get_cell(write_row, c).has_blocker():
				break
			write_row -= 1

		if write_row < 0:
			continue

		# Scan from bottom, pulling gems down
		var empty_slots: Array = []
		for r in range(board.height - 1, -1, -1):
			if not board.is_playable(r, c):
				continue
			var cell := board.get_cell(r, c)
			if cell.has_blocker() and not cell.has_gem():
				continue  # Blockers that occupy the cell (crate, vase) block gravity
			if not cell.has_gem():
				empty_slots.append(r)
			elif not empty_slots.is_empty():
				# Move this gem down to the lowest empty slot
				var target_row: int = empty_slots.pop_front()
				var target_cell := board.get_cell(target_row, c)
				target_cell.gem_color = cell.gem_color
				target_cell.power_up = cell.power_up
				cell.clear_gem()
				empty_slots.append(r)
				movements.append({"from": Vector2i(r, c), "to": Vector2i(target_row, c)})

	return movements


func _spawn_gems() -> Array:
	## Fill empty cells at the top of each column with new random gems.
	var spawns: Array = []

	for c in range(board.width):
		for r in range(board.height):
			if not board.is_playable(r, c):
				continue
			var cell := board.get_cell(r, c)
			if cell.has_blocker() and not cell.has_gem():
				break  # Blocker blocks spawning below it
			if not cell.has_gem():
				var color := board.random_gem_color()
				cell.set_gem(color)
				spawns.append({"pos": Vector2i(r, c), "color": color})
			else:
				break  # Filled from top, stop when we hit existing gems

	return spawns


# ============================================================
# OBJECTIVE TRACKING
# ============================================================

func _update_objectives_for_matches(matched: Dictionary, blocker_hits: Array, power_ups: Array) -> void:
	## Update objectives based on what was matched/destroyed.
	for i in range(board.objectives.size()):
		var obj := board.objectives[i]
		if obj.is_complete():
			continue

		match obj.type:
			GemTypes.ObjectiveType.COLLECT_COLOR:
				var target_color: int = int(obj.params.get("color", GemTypes.GemColor.NONE))
				var count := 0
				for pos in matched:
					if matched[pos] == target_color:
						count += 1
				if count > 0:
					obj.add_progress(count)
					objective_progress.emit(i, obj.current)

			GemTypes.ObjectiveType.REMOVE_BLOCKER:
				var target_blocker_name: String = str(obj.params.get("blocker_name", ""))
				for hit in blocker_hits:
					if hit["destroyed"]:
						obj.add_progress(1)
						objective_progress.emit(i, obj.current)

			GemTypes.ObjectiveType.CREATE_POWERUP:
				var target_pu: String = str(obj.params.get("powerup", ""))
				for pu in power_ups:
					if _powerup_matches_objective(pu["type"], target_pu):
						obj.add_progress(1)
						objective_progress.emit(i, obj.current)


func _track_gem_cleared(color: GemTypes.GemColor) -> void:
	## Track a single gem clear for objectives (from power-up effects).
	for i in range(board.objectives.size()):
		var obj := board.objectives[i]
		if obj.is_complete():
			continue
		if obj.type == GemTypes.ObjectiveType.COLLECT_COLOR:
			var target_color: int = int(obj.params.get("color", GemTypes.GemColor.NONE))
			if color == target_color:
				obj.add_progress(1)
				objective_progress.emit(i, obj.current)


func _track_blocker_destroyed(_blocker_type: GemTypes.BlockerType) -> void:
	## Track blocker destruction for objectives.
	for i in range(board.objectives.size()):
		var obj := board.objectives[i]
		if obj.is_complete():
			continue
		if obj.type == GemTypes.ObjectiveType.REMOVE_BLOCKER:
			obj.add_progress(1)
			objective_progress.emit(i, obj.current)


# ============================================================
# UTILITY
# ============================================================

func _do_swap(r1: int, c1: int, r2: int, c2: int) -> void:
	## Swap the gem data between two cells.
	var cell1 := board.get_cell(r1, c1)
	var cell2 := board.get_cell(r2, c2)
	var temp_color := cell1.gem_color
	var temp_pu := cell1.power_up
	cell1.gem_color = cell2.gem_color
	cell1.power_up = cell2.power_up
	cell2.gem_color = temp_color
	cell2.power_up = temp_pu


static func _powerup_matches_objective(pu_type: int, target: String) -> bool:
	## Check if a power-up type matches an objective target string.
	match target.to_upper():
		"ROCKET":
			return pu_type == GemTypes.PowerUpType.ROCKET_H or pu_type == GemTypes.PowerUpType.ROCKET_V
		"ROCKET_H":
			return pu_type == GemTypes.PowerUpType.ROCKET_H
		"ROCKET_V":
			return pu_type == GemTypes.PowerUpType.ROCKET_V
		"BOMB":
			return pu_type == GemTypes.PowerUpType.BOMB
		"PRISM":
			return pu_type == GemTypes.PowerUpType.PRISM
		_:
			return true  # No filter — any power-up counts


func _place_gem_no_match(row: int, col: int) -> void:
	## Place a random gem that doesn't create an immediate match.
	var cell := board.get_cell(row, col)
	var attempts := 0
	while attempts < 50:
		var color := board.random_gem_color()
		cell.gem_color = color
		cell.power_up = GemTypes.PowerUpType.NONE
		if not board._check_match_at(row, col):
			return
		attempts += 1
	# Fallback: just place it (very unlikely to loop 50 times)
	cell.gem_color = board.random_gem_color()


func _shuffle_board() -> void:
	## Shuffle all gem positions randomly. Called when no valid moves exist.
	var gems: Array = []
	var positions: Array = []

	for r in range(board.height):
		for c in range(board.width):
			var cell := board.get_cell(r, c)
			if cell.has_gem() and not cell.has_blocker():
				gems.append({"color": cell.gem_color, "power_up": cell.power_up})
				positions.append(Vector2i(r, c))

	# Fisher-Yates shuffle
	for i in range(gems.size() - 1, 0, -1):
		var j := randi() % (i + 1)
		var temp = gems[i]
		gems[i] = gems[j]
		gems[j] = temp

	# Place shuffled gems
	for i in range(positions.size()):
		var cell := board.get_cell(positions[i].x, positions[i].y)
		cell.gem_color = gems[i]["color"]
		cell.power_up = gems[i]["power_up"]

	# If still no valid moves, reshuffle (recursive, with limit)
	if not board.has_valid_moves():
		_shuffle_board()
