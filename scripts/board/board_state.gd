class_name BoardState
## Pure data model representing the state of the match-3 board.
## No rendering or UI logic — just data and queries.

var width: int = 7
var height: int = 9
var grid: Array = []         # Array of Array of Cell
var move_count: int = 0
var move_limit: int = 25
var score: int = 0
var objectives: Array[Objective] = []
var gem_pool: Array[GemTypes.GemColor] = []
var level_id: int = 0
var is_game_over: bool = false
var is_won: bool = false

# Track cascade depth for scoring bonus
var cascade_depth: int = 0


func _init(w: int = 7, h: int = 9) -> void:
	width = w
	height = h
	_init_grid()


func _init_grid() -> void:
	grid = []
	for r in range(height):
		var row_arr: Array = []
		for c in range(width):
			row_arr.append(Cell.new(r, c))
		grid.append(row_arr)


# --- Cell access ---

func get_cell(row: int, col: int) -> Cell:
	if not is_valid_pos(row, col):
		return null
	return grid[row][col]


func is_valid_pos(row: int, col: int) -> bool:
	return row >= 0 and row < height and col >= 0 and col < width


func is_playable(row: int, col: int) -> bool:
	if not is_valid_pos(row, col):
		return false
	return not grid[row][col].is_empty


# --- Gem pool and spawning ---

func set_gem_pool(colors: Array[GemTypes.GemColor]) -> void:
	gem_pool = colors


func random_gem_color() -> GemTypes.GemColor:
	if gem_pool.is_empty():
		return GemTypes.GemColor.RUBY
	return gem_pool[randi() % gem_pool.size()]


# --- Objectives ---

func all_objectives_complete() -> bool:
	for obj in objectives:
		if not obj.is_complete():
			return false
	return true


func get_stars() -> int:
	## Calculate stars based on remaining moves.
	var remaining := move_limit - move_count
	var ratio := float(remaining) / float(move_limit) if move_limit > 0 else 0.0
	if ratio >= 0.66:
		return 3
	elif ratio >= 0.33:
		return 2
	else:
		return 1


func check_game_state() -> void:
	## Check if the game is won or lost.
	if all_objectives_complete():
		is_won = true
		is_game_over = true
	elif move_count >= move_limit:
		is_won = false
		is_game_over = true


# --- Board queries ---

func get_all_gems_of_color(color: GemTypes.GemColor) -> Array:
	## Returns array of [row, col] pairs.
	var result: Array = []
	for r in range(height):
		for c in range(width):
			var cell := get_cell(r, c)
			if cell.has_gem() and cell.gem_color == color:
				result.append(Vector2i(r, c))
	return result


func count_empty_playable_cells() -> int:
	var count := 0
	for r in range(height):
		for c in range(width):
			var cell := get_cell(r, c)
			if not cell.is_empty and not cell.has_gem() and not cell.has_blocker():
				count += 1
	return count


func has_valid_moves() -> bool:
	## Check if any valid swap exists on the board.
	for r in range(height):
		for c in range(width):
			var cell := get_cell(r, c)
			if not cell.is_swappable():
				continue
			# Check swap right
			if c + 1 < width:
				var right := get_cell(r, c + 1)
				if right.is_swappable():
					# Simulate swap and check for match
					if _swap_creates_match(r, c, r, c + 1):
						return true
			# Check swap down
			if r + 1 < height:
				var below := get_cell(r + 1, c)
				if below.is_swappable():
					if _swap_creates_match(r, c, r + 1, c):
						return true
	return false


func _swap_creates_match(r1: int, c1: int, r2: int, c2: int) -> bool:
	## Check if swapping (r1,c1) with (r2,c2) would create a match.
	var cell1 := get_cell(r1, c1)
	var cell2 := get_cell(r2, c2)
	# Temporarily swap colors
	var temp_color := cell1.gem_color
	cell1.gem_color = cell2.gem_color
	cell2.gem_color = temp_color
	# Check for matches at both positions
	var match_found := _check_match_at(r1, c1) or _check_match_at(r2, c2)
	# Swap back
	cell2.gem_color = cell1.gem_color
	cell1.gem_color = temp_color
	return match_found


func _check_match_at(row: int, col: int) -> bool:
	## Check if position (row, col) is part of a 3+ match.
	var cell := get_cell(row, col)
	if not cell.has_gem():
		return false
	var color := cell.gem_color
	# Horizontal run
	var h_count := 1
	var c := col - 1
	while c >= 0 and is_playable(row, c):
		var check := get_cell(row, c)
		if check.is_matchable() and check.gem_color == color:
			h_count += 1
			c -= 1
		else:
			break
	c = col + 1
	while c < width and is_playable(row, c):
		var check := get_cell(row, c)
		if check.is_matchable() and check.gem_color == color:
			h_count += 1
			c += 1
		else:
			break
	if h_count >= 3:
		return true
	# Vertical run
	var v_count := 1
	var r := row - 1
	while r >= 0 and is_playable(r, col):
		var check := get_cell(r, col)
		if check.is_matchable() and check.gem_color == color:
			v_count += 1
			r -= 1
		else:
			break
	r = row + 1
	while r < height and is_playable(r, col):
		var check := get_cell(r, col)
		if check.is_matchable() and check.gem_color == color:
			v_count += 1
			r += 1
		else:
			break
	if v_count >= 3:
		return true
	return false


func print_board() -> void:
	## Debug: print board to console.
	for r in range(height):
		var line := ""
		for c in range(width):
			line += grid[r][c]._to_string() + " "
		print(line)
	print("Moves: %d/%d  Score: %d" % [move_count, move_limit, score])
