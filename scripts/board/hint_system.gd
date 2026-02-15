class_name HintSystem
## Analyzes the board to find the best move to suggest to the player.
## Runs on-demand (not every frame). Priority:
## 1. Moves that create power-ups (match 4+)
## 2. Moves that progress objectives
## 3. Any valid move

var board: BoardState


func _init(board_state: BoardState = null) -> void:
	board = board_state


func set_board(board_state: BoardState) -> void:
	board = board_state


func find_best_hint() -> Dictionary:
	## Returns {"from": Vector2i, "to": Vector2i, "score": int}
	## or {} if no valid move exists.
	if board == null:
		return {}

	var all_moves: Array = _find_all_valid_moves()
	if all_moves.is_empty():
		return {}

	# Score each move
	var best_move: Dictionary = all_moves[0]
	var best_score: int = -1

	for move in all_moves:
		var score := _score_move(move)
		if score > best_score:
			best_score = score
			best_move = move

	best_move["score"] = best_score
	return best_move


func _find_all_valid_moves() -> Array:
	## Find every valid swap on the board.
	var moves: Array = []
	for r in range(board.height):
		for c in range(board.width):
			var cell := board.get_cell(r, c)
			if not cell.is_swappable():
				continue
			# Check right
			if c + 1 < board.width:
				var right := board.get_cell(r, c + 1)
				if right.is_swappable() and board._swap_creates_match(r, c, r, c + 1):
					moves.append({"from": Vector2i(r, c), "to": Vector2i(r, c + 1)})
			# Check down
			if r + 1 < board.height:
				var below := board.get_cell(r + 1, c)
				if below.is_swappable() and board._swap_creates_match(r, c, r + 1, c):
					moves.append({"from": Vector2i(r, c), "to": Vector2i(r + 1, c)})
	return moves


func _score_move(move: Dictionary) -> int:
	## Heuristic score for a potential swap.
	var from: Vector2i = move["from"]
	var to: Vector2i = move["to"]
	var score := 1  # base score

	var cell1 := board.get_cell(from.x, from.y)
	var cell2 := board.get_cell(to.x, to.y)

	# Temporarily swap
	var temp_color := cell1.gem_color
	cell1.gem_color = cell2.gem_color
	cell2.gem_color = temp_color

	# Check match size at both positions
	var match_size_1 := _get_match_size_at(from.x, from.y)
	var match_size_2 := _get_match_size_at(to.x, to.y)
	var total_match := match_size_1 + match_size_2

	# Bigger matches → higher score
	if total_match >= 5:
		score += 50  # Likely creates a power-up
	elif total_match >= 4:
		score += 20  # Creates a rocket
	else:
		score += 5

	# Bonus if it matches an objective color
	for obj in board.objectives:
		if obj.is_complete():
			continue
		if obj.type == GemTypes.ObjectiveType.COLLECT_COLOR:
			var target_color = obj.params.get("color", GemTypes.GemColor.NONE)
			if cell1.gem_color == target_color or cell2.gem_color == target_color:
				score += 10

	# Bonus if adjacent to a blocker (might hit it)
	if _is_adjacent_to_blocker(from.x, from.y) or _is_adjacent_to_blocker(to.x, to.y):
		score += 8

	# Swap back
	cell2.gem_color = cell1.gem_color
	cell1.gem_color = temp_color

	return score


func _get_match_size_at(row: int, col: int) -> int:
	## Count how many gems are in the match group at this position.
	var cell := board.get_cell(row, col)
	if not cell.has_gem():
		return 0
	var color := cell.gem_color
	var count := 0

	# Horizontal run through this cell
	var h_count := 1
	var c := col - 1
	while c >= 0:
		var check := board.get_cell(row, c)
		if check != null and check.is_matchable() and check.gem_color == color:
			h_count += 1
			c -= 1
		else:
			break
	c = col + 1
	while c < board.width:
		var check := board.get_cell(row, c)
		if check != null and check.is_matchable() and check.gem_color == color:
			h_count += 1
			c += 1
		else:
			break
	if h_count >= 3:
		count += h_count

	# Vertical run through this cell
	var v_count := 1
	var r := row - 1
	while r >= 0:
		var check := board.get_cell(r, col)
		if check != null and check.is_matchable() and check.gem_color == color:
			v_count += 1
			r -= 1
		else:
			break
	r = row + 1
	while r < board.height:
		var check := board.get_cell(r, col)
		if check != null and check.is_matchable() and check.gem_color == color:
			v_count += 1
			r += 1
		else:
			break
	if v_count >= 3:
		count += v_count

	return count


func _is_adjacent_to_blocker(row: int, col: int) -> bool:
	var directions := [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
	for dir in directions:
		var cell := board.get_cell(row + dir.x, col + dir.y)
		if cell != null and cell.has_blocker():
			return true
	return false
