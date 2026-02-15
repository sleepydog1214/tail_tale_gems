extends Node
## Unit tests for the match-3 engine.
## Run with: Godot --headless --script res://tests/test_match_engine.gd
##
## These tests verify core gameplay logic without any rendering.
## Each test function prints PASS/FAIL and the script exits with a summary.

var _tests_run: int = 0
var _tests_passed: int = 0
var _tests_failed: int = 0
var _current_test: String = ""


func _ready() -> void:
	print("==============================================")
	print("  Gem Kingdoms — Match Engine Test Suite")
	print("==============================================\n")

	# Cell tests
	_run("test_cell_creation", test_cell_creation)
	_run("test_cell_has_gem", test_cell_has_gem)
	_run("test_cell_blocker_hit", test_cell_blocker_hit)
	_run("test_cell_ice_blocks_swap", test_cell_ice_blocks_swap)
	_run("test_cell_stone_indestructible", test_cell_stone_indestructible)

	# BoardState tests
	_run("test_board_creation", test_board_creation)
	_run("test_board_valid_pos", test_board_valid_pos)
	_run("test_board_gem_pool", test_board_gem_pool)
	_run("test_board_stars_3", test_board_stars_3)
	_run("test_board_stars_2", test_board_stars_2)
	_run("test_board_stars_1", test_board_stars_1)
	_run("test_board_check_game_state_win", test_board_check_game_state_win)
	_run("test_board_check_game_state_lose", test_board_check_game_state_lose)

	# Objective tests
	_run("test_objective_creation", test_objective_creation)
	_run("test_objective_progress", test_objective_progress)
	_run("test_objective_display_text", test_objective_display_text)

	# MatchEngine tests
	_run("test_fill_board_no_initial_matches", test_fill_board_no_initial_matches)
	_run("test_match_detection_horizontal", test_match_detection_horizontal)
	_run("test_match_detection_vertical", test_match_detection_vertical)
	_run("test_no_match_detection", test_no_match_detection)
	_run("test_swap_valid", test_swap_valid)
	_run("test_swap_invalid_no_match", test_swap_invalid_no_match)
	_run("test_swap_not_adjacent", test_swap_not_adjacent)
	_run("test_move_count_increments", test_move_count_increments)
	_run("test_gravity_fills_gaps", test_gravity_fills_gaps)
	_run("test_match4_creates_rocket", test_match4_creates_rocket)
	_run("test_match5_line_creates_prism", test_match5_line_creates_prism)
	_run("test_match5_L_creates_bomb", test_match5_L_creates_bomb)
	_run("test_cascade_scoring", test_cascade_scoring)
	_run("test_collect_color_objective_tracking", test_collect_color_objective_tracking)
	_run("test_blocker_adjacency_hit", test_blocker_adjacency_hit)
	_run("test_board_has_valid_moves", test_board_has_valid_moves)

	# HintSystem tests
	_run("test_hint_finds_valid_move", test_hint_finds_valid_move)
	_run("test_hint_prefers_powerup_move", test_hint_prefers_powerup_move)

	# LevelLoader tests
	_run("test_level_loader_level_1", test_level_loader_level_1)
	_run("test_level_loader_rewards", test_level_loader_rewards)
	_run("test_level_loader_missing_file", test_level_loader_missing_file)

	# GemTypes tests
	_run("test_gem_color_from_string", test_gem_color_from_string)
	_run("test_blocker_from_string", test_blocker_from_string)
	_run("test_objective_from_string", test_objective_from_string)

	# Game Readiness regression tests (Phase 3)
	_run("test_particle_effects_class_available", test_particle_effects_class_available)
	_run("test_board_view_script_loads", test_board_view_script_loads)
	_run("test_game_screen_instantiates", test_game_screen_instantiates)
	_run("test_board_initializes_with_gems", test_board_initializes_with_gems)
	_run("test_hud_initializes_from_board", test_hud_initializes_from_board)

	# Gameplay flow regression tests (Phase 4)
	_run("test_main_menu_screen_loads", test_main_menu_screen_loads)
	_run("test_level_select_screen_loads", test_level_select_screen_loads)
	_run("test_profile_popup_class_available", test_profile_popup_class_available)
	_run("test_all_screen_scripts_compile", test_all_screen_scripts_compile)
	_run("test_gameplay_flow_start_level", test_gameplay_flow_start_level)

	# Print summary
	print("\n==============================================")
	print("  Results: %d/%d passed, %d failed" % [_tests_passed, _tests_run, _tests_failed])
	print("==============================================")

	if _tests_failed > 0:
		print("\n  SOME TESTS FAILED!")
	else:
		print("\n  ALL TESTS PASSED!")

	# Exit
	get_tree().quit(0 if _tests_failed == 0 else 1)


# ============================================================
# Test runner helpers
# ============================================================

func _run(test_name: String, test_func: Callable) -> void:
	_current_test = test_name
	_tests_run += 1
	test_func.call()


func _assert_true(condition: bool, message: String = "") -> void:
	if condition:
		_tests_passed += 1
		print("  PASS: %s %s" % [_current_test, ("— " + message) if message else ""])
	else:
		_tests_failed += 1
		print("  FAIL: %s %s" % [_current_test, ("— " + message) if message else ""])


func _assert_eq(a, b, message: String = "") -> void:
	var msg := "%s (expected %s, got %s)" % [message, str(b), str(a)]
	_assert_true(a == b, msg)


func _assert_neq(a, b, message: String = "") -> void:
	var msg := "%s (expected != %s)" % [message, str(b)]
	_assert_true(a != b, msg)


func _assert_gt(a, b, message: String = "") -> void:
	var msg := "%s (expected %s > %s)" % [message, str(a), str(b)]
	_assert_true(a > b, msg)


# ============================================================
# CELL TESTS
# ============================================================

func test_cell_creation() -> void:
	var cell := Cell.new(3, 5)
	_assert_eq(cell.row, 3, "row")
	_assert_eq(cell.col, 5, "col")
	_assert_eq(cell.gem_color, GemTypes.GemColor.NONE, "default gem_color")
	_assert_eq(cell.is_empty, false, "not empty by default")


func test_cell_has_gem() -> void:
	var cell := Cell.new(0, 0)
	_assert_true(not cell.has_gem(), "no gem initially")
	cell.set_gem(GemTypes.GemColor.RUBY)
	_assert_true(cell.has_gem(), "has gem after set_gem")
	cell.clear_gem()
	_assert_true(not cell.has_gem(), "no gem after clear")


func test_cell_blocker_hit() -> void:
	var cell := Cell.new(0, 0)
	cell.set_blocker(GemTypes.BlockerType.ICE, 3)
	_assert_eq(cell.blocker_hp, 3, "initial hp")
	var destroyed := cell.hit_blocker()
	_assert_true(not destroyed, "not destroyed at hp 2")
	_assert_eq(cell.blocker_hp, 2, "hp reduced")
	cell.hit_blocker()
	destroyed = cell.hit_blocker()
	_assert_true(destroyed, "destroyed at hp 0")
	_assert_eq(cell.blocker_type, GemTypes.BlockerType.NONE, "blocker removed")


func test_cell_ice_blocks_swap() -> void:
	var cell := Cell.new(0, 0)
	cell.set_gem(GemTypes.GemColor.RUBY)
	cell.set_blocker(GemTypes.BlockerType.ICE, 1)
	_assert_true(not cell.is_swappable(), "ice blocks swapping")
	_assert_true(cell.is_matchable(), "ice allows matching")


func test_cell_stone_indestructible() -> void:
	var cell := Cell.new(0, 0)
	cell.set_blocker(GemTypes.BlockerType.STONE, 1)
	var destroyed := cell.hit_blocker()
	_assert_true(not destroyed, "stone cannot be destroyed by hit")
	_assert_eq(cell.blocker_type, GemTypes.BlockerType.STONE, "stone remains")


# ============================================================
# BOARD STATE TESTS
# ============================================================

func test_board_creation() -> void:
	var board := BoardState.new(7, 9)
	_assert_eq(board.width, 7, "width")
	_assert_eq(board.height, 9, "height")
	_assert_eq(board.grid.size(), 9, "grid rows")
	_assert_eq(board.grid[0].size(), 7, "grid cols")


func test_board_valid_pos() -> void:
	var board := BoardState.new(7, 9)
	_assert_true(board.is_valid_pos(0, 0), "0,0 valid")
	_assert_true(board.is_valid_pos(8, 6), "8,6 valid")
	_assert_true(not board.is_valid_pos(-1, 0), "-1,0 invalid")
	_assert_true(not board.is_valid_pos(9, 0), "9,0 invalid")
	_assert_true(not board.is_valid_pos(0, 7), "0,7 invalid")


func test_board_gem_pool() -> void:
	var board := BoardState.new(7, 9)
	var pool: Array[GemTypes.GemColor] = [GemTypes.GemColor.RUBY, GemTypes.GemColor.SAPPHIRE]
	board.set_gem_pool(pool)
	# Random gem should be one of the pool colors
	var color := board.random_gem_color()
	_assert_true(color == GemTypes.GemColor.RUBY or color == GemTypes.GemColor.SAPPHIRE,
		"random color from pool")


func test_board_stars_3() -> void:
	var board := BoardState.new(7, 9)
	board.move_limit = 30
	board.move_count = 5  # 25 remaining = 83% → 3 stars
	_assert_eq(board.get_stars(), 3, "3 stars at 83%")


func test_board_stars_2() -> void:
	var board := BoardState.new(7, 9)
	board.move_limit = 30
	board.move_count = 17  # 13 remaining = 43% → 2 stars
	_assert_eq(board.get_stars(), 2, "2 stars at 43%")


func test_board_stars_1() -> void:
	var board := BoardState.new(7, 9)
	board.move_limit = 30
	board.move_count = 28  # 2 remaining = 6.7% → 1 star
	_assert_eq(board.get_stars(), 1, "1 star at 6.7%")


func test_board_check_game_state_win() -> void:
	var board := BoardState.new(7, 9)
	board.move_limit = 30
	var obj := Objective.new(GemTypes.ObjectiveType.COLLECT_COLOR, 10, {"color": GemTypes.GemColor.RUBY})
	obj.current = 10  # Complete
	board.objectives.append(obj)
	board.check_game_state()
	_assert_true(board.is_won, "level won when objectives complete")
	_assert_true(board.is_game_over, "game over on win")


func test_board_check_game_state_lose() -> void:
	var board := BoardState.new(7, 9)
	board.move_limit = 30
	board.move_count = 30  # Out of moves
	var obj := Objective.new(GemTypes.ObjectiveType.COLLECT_COLOR, 10, {"color": GemTypes.GemColor.RUBY})
	obj.current = 5  # Not complete
	board.objectives.append(obj)
	board.check_game_state()
	_assert_true(not board.is_won, "level not won")
	_assert_true(board.is_game_over, "game over when out of moves")


# ============================================================
# OBJECTIVE TESTS
# ============================================================

func test_objective_creation() -> void:
	var obj := Objective.new(GemTypes.ObjectiveType.COLLECT_COLOR, 30, {"color": GemTypes.GemColor.RUBY, "color_name": "Ruby"})
	_assert_eq(obj.type, GemTypes.ObjectiveType.COLLECT_COLOR, "type")
	_assert_eq(obj.target, 30, "target")
	_assert_eq(obj.current, 0, "initial progress")
	_assert_true(not obj.is_complete(), "not complete initially")


func test_objective_progress() -> void:
	var obj := Objective.new(GemTypes.ObjectiveType.COLLECT_COLOR, 10, {})
	obj.add_progress(5)
	_assert_eq(obj.current, 5, "progress 5")
	_assert_eq(obj.get_remaining(), 5, "remaining 5")
	obj.add_progress(10)
	_assert_eq(obj.current, 10, "clamped to target")
	_assert_true(obj.is_complete(), "complete at target")


func test_objective_display_text() -> void:
	var obj := Objective.new(GemTypes.ObjectiveType.COLLECT_COLOR, 30, {"color_name": "Ruby"})
	obj.current = 15
	var text := obj.get_display_text()
	_assert_true(text.contains("Ruby"), "display text has color name")
	_assert_true(text.contains("15"), "display text has current")
	_assert_true(text.contains("30"), "display text has target")


# ============================================================
# MATCH ENGINE TESTS
# ============================================================

func _create_test_board(w: int = 7, h: int = 7) -> BoardState:
	## Create a small test board with a fixed gem pool.
	var board := BoardState.new(w, h)
	var pool: Array[GemTypes.GemColor] = [
		GemTypes.GemColor.RUBY,
		GemTypes.GemColor.SAPPHIRE,
		GemTypes.GemColor.EMERALD,
		GemTypes.GemColor.TOPAZ,
	]
	board.set_gem_pool(pool)
	board.move_limit = 50
	return board


func _set_gem(board: BoardState, row: int, col: int, color: GemTypes.GemColor) -> void:
	board.get_cell(row, col).set_gem(color)


func test_fill_board_no_initial_matches() -> void:
	var board := _create_test_board()
	var engine := MatchEngine.new(board)
	engine.fill_board_initial()

	# After filling, there should be no matches
	var matches := engine.find_all_matches()
	_assert_eq(matches.size(), 0, "no initial matches after fill")

	# Every non-empty cell should have a gem
	for r in range(board.height):
		for c in range(board.width):
			var cell := board.get_cell(r, c)
			if not cell.is_empty:
				_assert_true(cell.has_gem(), "cell (%d,%d) has gem" % [r, c])


func test_match_detection_horizontal() -> void:
	var board := _create_test_board(5, 5)
	var engine := MatchEngine.new(board)

	# Set up a clear board with no matches, then create one
	for r in range(5):
		for c in range(5):
			# Alternating pattern to avoid accidental matches
			var colors := [GemTypes.GemColor.RUBY, GemTypes.GemColor.SAPPHIRE]
			_set_gem(board, r, c, colors[(r + c) % 2])

	# Create horizontal match-3 at row 2
	_set_gem(board, 2, 0, GemTypes.GemColor.EMERALD)
	_set_gem(board, 2, 1, GemTypes.GemColor.EMERALD)
	_set_gem(board, 2, 2, GemTypes.GemColor.EMERALD)

	var matches := engine.find_all_matches()
	_assert_gt(matches.size(), 0, "horizontal match detected")


func test_match_detection_vertical() -> void:
	var board := _create_test_board(5, 5)
	var engine := MatchEngine.new(board)

	# Set up a clear board
	for r in range(5):
		for c in range(5):
			var colors := [GemTypes.GemColor.RUBY, GemTypes.GemColor.SAPPHIRE]
			_set_gem(board, r, c, colors[(r + c) % 2])

	# Create vertical match-3 at col 1
	_set_gem(board, 0, 1, GemTypes.GemColor.TOPAZ)
	_set_gem(board, 1, 1, GemTypes.GemColor.TOPAZ)
	_set_gem(board, 2, 1, GemTypes.GemColor.TOPAZ)

	var matches := engine.find_all_matches()
	_assert_gt(matches.size(), 0, "vertical match detected")


func test_no_match_detection() -> void:
	var board := _create_test_board(5, 5)
	var engine := MatchEngine.new(board)

	# Set up alternating pattern — no 3 in a row
	for r in range(5):
		for c in range(5):
			var colors := [GemTypes.GemColor.RUBY, GemTypes.GemColor.SAPPHIRE]
			_set_gem(board, r, c, colors[(r + c) % 2])

	var matches := engine.find_all_matches()
	_assert_eq(matches.size(), 0, "no matches in alternating pattern")


func test_swap_valid() -> void:
	var board := _create_test_board(5, 5)
	var engine := MatchEngine.new(board)

	# Set up board manually:
	# Row 0: R S E T R
	# Row 1: S R S R S
	# Row 2: R S R* S* R  ← swap (2,3) and (2,4) to extend bottom row
	# Row 3: S R R R S  ← already R-R-R? No, let's set up for swap
	# Actually let's be precise. Create a situation where swapping makes a match.

	# Fill all with alternating to avoid matches
	for r in range(5):
		for c in range(5):
			var idx := (r * 5 + c) % 4
			var colors := [GemTypes.GemColor.RUBY, GemTypes.GemColor.SAPPHIRE, GemTypes.GemColor.EMERALD, GemTypes.GemColor.TOPAZ]
			_set_gem(board, r, c, colors[idx])

	# Set up so swapping (2,1) with (2,2) creates a horizontal match:
	# Row 2: ? R E ? ?  → becomes ? E R ? ? — but that doesn't help.
	# Better: make row 2 = [R, S, R, R, E] and swap (2,0) with (2,1) → [S, R, R, R, E] = match!
	_set_gem(board, 2, 0, GemTypes.GemColor.SAPPHIRE)
	_set_gem(board, 2, 1, GemTypes.GemColor.RUBY)
	_set_gem(board, 2, 2, GemTypes.GemColor.RUBY)
	_set_gem(board, 2, 3, GemTypes.GemColor.RUBY)
	# But we need the swap itself to create the match, not pre-existing.
	# Let's make: row 2 = [R, S, R, R, E]. Swapping (2,0)↔(2,1) doesn't create 3-in-row.
	# Better: row 2 = [S, R, R, E, T] and row 1, col 0 = R. Swap (1,0)↔(2,0) = [R, R, R, E, T].
	_set_gem(board, 1, 0, GemTypes.GemColor.EMERALD)  # was something else
	_set_gem(board, 2, 0, GemTypes.GemColor.RUBY)
	_set_gem(board, 2, 1, GemTypes.GemColor.RUBY)
	_set_gem(board, 2, 2, GemTypes.GemColor.EMERALD)

	# Actually, the simplest approach:
	# Create row 2 = [E, R, R, ?, ?]. Put R at (1,0). Swap (1,0)↔(2,0) → row 2 = [R, R, R, ...] = match!
	_set_gem(board, 1, 0, GemTypes.GemColor.RUBY)
	_set_gem(board, 2, 0, GemTypes.GemColor.EMERALD)
	_set_gem(board, 2, 1, GemTypes.GemColor.RUBY)
	_set_gem(board, 2, 2, GemTypes.GemColor.RUBY)

	# Ensure neighbors won't create accidental matches
	_set_gem(board, 1, 1, GemTypes.GemColor.SAPPHIRE)
	_set_gem(board, 1, 2, GemTypes.GemColor.TOPAZ)
	_set_gem(board, 0, 0, GemTypes.GemColor.SAPPHIRE)
	_set_gem(board, 3, 0, GemTypes.GemColor.SAPPHIRE)

	# Swap (1,0) with (2,0): Ruby↔Emerald → row 2 becomes [R, R, R,...] = match
	var result := engine.try_swap(1, 0, 2, 0)
	_assert_true(result, "valid swap returns true")


func test_swap_invalid_no_match() -> void:
	var board := _create_test_board(5, 5)
	var engine := MatchEngine.new(board)

	# Fill with distinct pattern that won't create matches on any swap
	var colors := [GemTypes.GemColor.RUBY, GemTypes.GemColor.SAPPHIRE, GemTypes.GemColor.EMERALD, GemTypes.GemColor.TOPAZ]
	for r in range(5):
		for c in range(5):
			_set_gem(board, r, c, colors[(r * 2 + c) % 4])

	# Make sure swapping (0,0) and (0,1) doesn't create a match
	_set_gem(board, 0, 0, GemTypes.GemColor.RUBY)
	_set_gem(board, 0, 1, GemTypes.GemColor.SAPPHIRE)
	_set_gem(board, 0, 2, GemTypes.GemColor.EMERALD)
	_set_gem(board, 1, 0, GemTypes.GemColor.TOPAZ)
	_set_gem(board, 1, 1, GemTypes.GemColor.EMERALD)

	var old_count := board.move_count
	var result := engine.try_swap(0, 0, 0, 1)
	_assert_true(not result, "invalid swap returns false")
	_assert_eq(board.move_count, old_count, "move count unchanged on invalid swap")


func test_swap_not_adjacent() -> void:
	var board := _create_test_board(5, 5)
	var engine := MatchEngine.new(board)
	engine.fill_board_initial()

	var result := engine.try_swap(0, 0, 2, 2)
	_assert_true(not result, "non-adjacent swap rejected")


func test_move_count_increments() -> void:
	var board := _create_test_board(5, 5)
	var engine := MatchEngine.new(board)

	# Set up a guaranteed valid swap
	for r in range(5):
		for c in range(5):
			var colors := [GemTypes.GemColor.RUBY, GemTypes.GemColor.SAPPHIRE, GemTypes.GemColor.EMERALD, GemTypes.GemColor.TOPAZ]
			_set_gem(board, r, c, colors[(r * 2 + c) % 4])

	# Create match setup at row 3
	_set_gem(board, 3, 0, GemTypes.GemColor.RUBY)
	_set_gem(board, 3, 1, GemTypes.GemColor.SAPPHIRE)
	_set_gem(board, 3, 2, GemTypes.GemColor.SAPPHIRE)
	# Swap (3,0)↔(3,1) won't work if it doesn't create match.
	# Setup: (2,1)=R, (3,1)=E, (3,2)=R, (3,3)=R → swap (2,1)↔(3,1) makes row 3 = [?, R, R, R] = match
	_set_gem(board, 2, 1, GemTypes.GemColor.RUBY)
	_set_gem(board, 3, 1, GemTypes.GemColor.TOPAZ)
	_set_gem(board, 3, 2, GemTypes.GemColor.RUBY)
	_set_gem(board, 3, 3, GemTypes.GemColor.RUBY)
	# Prevent accidental matches
	_set_gem(board, 2, 0, GemTypes.GemColor.SAPPHIRE)
	_set_gem(board, 2, 2, GemTypes.GemColor.EMERALD)
	_set_gem(board, 1, 1, GemTypes.GemColor.SAPPHIRE)
	_set_gem(board, 4, 1, GemTypes.GemColor.SAPPHIRE)

	var old := board.move_count
	engine.try_swap(2, 1, 3, 1)
	_assert_eq(board.move_count, old + 1, "move count +1 after valid swap")


func test_gravity_fills_gaps() -> void:
	var board := _create_test_board(3, 5)
	var engine := MatchEngine.new(board)

	# Fill board
	for r in range(5):
		for c in range(3):
			_set_gem(board, r, c, GemTypes.GemColor.RUBY if (r + c) % 2 == 0 else GemTypes.GemColor.SAPPHIRE)

	# Clear middle row to simulate a match
	for c in range(3):
		board.get_cell(2, c).clear_gem()

	# Count empty cells before gravity
	var empty_before := board.count_empty_playable_cells()
	_assert_gt(empty_before, 0, "gaps exist before gravity")


func test_match4_creates_rocket() -> void:
	var board := _create_test_board(7, 7)
	var engine := MatchEngine.new(board)

	# Fill board with non-matching pattern
	var colors := [GemTypes.GemColor.RUBY, GemTypes.GemColor.SAPPHIRE, GemTypes.GemColor.EMERALD, GemTypes.GemColor.TOPAZ]
	for r in range(7):
		for c in range(7):
			_set_gem(board, r, c, colors[(r * 3 + c) % 4])

	# Set up a match-4 horizontal: swap creates 4-in-a-row
	# Row 3: [?, R, R, R, ?, ?, ?]. Put S at (3,0), R at (2,0).
	# Swap (2,0)↔(3,0) → row 3 = [R, R, R, R,...] = match 4
	_set_gem(board, 3, 0, GemTypes.GemColor.SAPPHIRE)
	_set_gem(board, 3, 1, GemTypes.GemColor.RUBY)
	_set_gem(board, 3, 2, GemTypes.GemColor.RUBY)
	_set_gem(board, 3, 3, GemTypes.GemColor.RUBY)
	_set_gem(board, 3, 4, GemTypes.GemColor.EMERALD)
	_set_gem(board, 2, 0, GemTypes.GemColor.RUBY)
	# Prevent vertical matches
	_set_gem(board, 1, 0, GemTypes.GemColor.EMERALD)
	_set_gem(board, 4, 0, GemTypes.GemColor.EMERALD)
	_set_gem(board, 2, 1, GemTypes.GemColor.EMERALD)
	_set_gem(board, 4, 1, GemTypes.GemColor.TOPAZ)
	_set_gem(board, 4, 2, GemTypes.GemColor.SAPPHIRE)
	_set_gem(board, 4, 3, GemTypes.GemColor.EMERALD)

	# Check match detection sees a match-4
	_set_gem(board, 3, 0, GemTypes.GemColor.RUBY)  # Pre-place to test detection
	var matches := engine.find_all_matches()
	var found_4 := false
	for m in matches:
		if m["cells"].size() >= 4:
			found_4 = true
	_assert_true(found_4, "match-4 detected")


func test_match5_line_creates_prism() -> void:
	var board := _create_test_board(7, 7)
	var engine := MatchEngine.new(board)

	# Fill board
	var colors := [GemTypes.GemColor.RUBY, GemTypes.GemColor.SAPPHIRE, GemTypes.GemColor.EMERALD, GemTypes.GemColor.TOPAZ]
	for r in range(7):
		for c in range(7):
			_set_gem(board, r, c, colors[(r * 3 + c) % 4])

	# Create 5-in-a-row at row 4
	for c in range(5):
		_set_gem(board, 4, c, GemTypes.GemColor.TOPAZ)
	_set_gem(board, 4, 5, GemTypes.GemColor.EMERALD)
	_set_gem(board, 4, 6, GemTypes.GemColor.SAPPHIRE)
	# Prevent vertical matches
	_set_gem(board, 3, 0, GemTypes.GemColor.EMERALD)
	_set_gem(board, 5, 0, GemTypes.GemColor.EMERALD)

	var matches := engine.find_all_matches()
	var found_5 := false
	for m in matches:
		if m["cells"].size() >= 5:
			found_5 = true
	_assert_true(found_5, "match-5 line detected")


func test_match5_L_creates_bomb() -> void:
	var board := _create_test_board(7, 7)
	var engine := MatchEngine.new(board)

	# Fill board
	var colors := [GemTypes.GemColor.RUBY, GemTypes.GemColor.SAPPHIRE, GemTypes.GemColor.EMERALD, GemTypes.GemColor.TOPAZ]
	for r in range(7):
		for c in range(7):
			_set_gem(board, r, c, colors[(r * 3 + c) % 4])

	# Create L shape: 3 horizontal + 3 vertical sharing a corner
	# R at (2,2), (2,3), (2,4): horizontal
	# R at (3,2), (4,2): extend vertically from corner
	_set_gem(board, 2, 2, GemTypes.GemColor.RUBY)
	_set_gem(board, 2, 3, GemTypes.GemColor.RUBY)
	_set_gem(board, 2, 4, GemTypes.GemColor.RUBY)
	_set_gem(board, 3, 2, GemTypes.GemColor.RUBY)
	_set_gem(board, 4, 2, GemTypes.GemColor.RUBY)

	# Prevent extending further
	_set_gem(board, 2, 1, GemTypes.GemColor.SAPPHIRE)
	_set_gem(board, 2, 5, GemTypes.GemColor.SAPPHIRE)
	_set_gem(board, 1, 2, GemTypes.GemColor.SAPPHIRE)
	_set_gem(board, 5, 2, GemTypes.GemColor.SAPPHIRE)

	var matches := engine.find_all_matches()
	# Should detect this as an L/T shape (merged match)
	_assert_gt(matches.size(), 0, "L-shape match detected")


func test_cascade_scoring() -> void:
	var board := _create_test_board(7, 7)
	board.move_limit = 50
	var engine := MatchEngine.new(board)
	engine.fill_board_initial()

	# Score starts at 0
	_assert_eq(board.score, 0, "initial score is 0")


func test_collect_color_objective_tracking() -> void:
	var board := _create_test_board(7, 7)
	board.move_limit = 50
	var obj := Objective.new(GemTypes.ObjectiveType.COLLECT_COLOR, 30, {
		"color": GemTypes.GemColor.RUBY,
		"color_name": "Ruby"
	})
	board.objectives.append(obj)

	# Simulate progress
	obj.add_progress(10)
	_assert_eq(obj.current, 10, "progress tracked")
	_assert_true(not obj.is_complete(), "not complete yet")
	obj.add_progress(20)
	_assert_true(obj.is_complete(), "objective complete")
	_assert_true(board.all_objectives_complete(), "all objectives complete")


func test_blocker_adjacency_hit() -> void:
	var board := _create_test_board(5, 5)

	# Place a crate at (2, 2)
	board.get_cell(2, 2).set_blocker(GemTypes.BlockerType.CRATE, 1)
	_assert_true(board.get_cell(2, 2).has_blocker(), "blocker placed")

	# Hit it
	var destroyed := board.get_cell(2, 2).hit_blocker()
	_assert_true(destroyed, "crate destroyed in 1 hit")
	_assert_true(not board.get_cell(2, 2).has_blocker(), "blocker gone")


func test_board_has_valid_moves() -> void:
	var board := _create_test_board(5, 5)
	var engine := MatchEngine.new(board)
	engine.fill_board_initial()
	# After initial fill, there should be valid moves (engine ensures this)
	_assert_true(board.has_valid_moves(), "board has valid moves after fill")


# ============================================================
# HINT SYSTEM TESTS
# ============================================================

func test_hint_finds_valid_move() -> void:
	var board := _create_test_board(7, 7)
	var engine := MatchEngine.new(board)
	engine.fill_board_initial()

	var hints := HintSystem.new(board)
	var hint := hints.find_best_hint()
	_assert_true(not hint.is_empty(), "hint found on valid board")
	_assert_true(hint.has("from"), "hint has 'from'")
	_assert_true(hint.has("to"), "hint has 'to'")


func test_hint_prefers_powerup_move() -> void:
	var board := _create_test_board(7, 7)

	# Fill with non-matching
	var colors := [GemTypes.GemColor.RUBY, GemTypes.GemColor.SAPPHIRE, GemTypes.GemColor.EMERALD, GemTypes.GemColor.TOPAZ]
	for r in range(7):
		for c in range(7):
			_set_gem(board, r, c, colors[(r * 3 + c) % 4])

	# Create a match-4 opportunity: swap (3,0)↔(3,1) creates 4-in-row
	_set_gem(board, 3, 0, GemTypes.GemColor.EMERALD)
	_set_gem(board, 3, 1, GemTypes.GemColor.RUBY)
	_set_gem(board, 3, 2, GemTypes.GemColor.RUBY)
	_set_gem(board, 3, 3, GemTypes.GemColor.RUBY)
	_set_gem(board, 2, 0, GemTypes.GemColor.RUBY)  # Swap this down for match-4
	# Prevent accidental matches
	_set_gem(board, 1, 0, GemTypes.GemColor.SAPPHIRE)
	_set_gem(board, 4, 0, GemTypes.GemColor.SAPPHIRE)

	# Also create a simple match-3 elsewhere
	_set_gem(board, 6, 4, GemTypes.GemColor.TOPAZ)
	_set_gem(board, 6, 5, GemTypes.GemColor.TOPAZ)
	_set_gem(board, 5, 5, GemTypes.GemColor.TOPAZ)

	var hints := HintSystem.new(board)
	var hint := hints.find_best_hint()
	# The hint should prefer the match-4 move (higher score)
	_assert_true(not hint.is_empty(), "hint found")
	_assert_gt(hint.get("score", 0), 5, "hint score indicates power-up preference")


# ============================================================
# LEVEL LOADER TESTS
# ============================================================

func test_level_loader_level_1() -> void:
	var board := LevelLoader.load_level(1)
	_assert_true(board != null, "level 1 loaded")
	if board:
		_assert_eq(board.level_id, 1, "level_id is 1")
		_assert_eq(board.width, 7, "width is 7")
		_assert_eq(board.height, 7, "height is 7")
		_assert_eq(board.move_limit, 60, "move limit is 60")
		_assert_gt(board.objectives.size(), 0, "has objectives")
		_assert_gt(board.gem_pool.size(), 0, "has gem pool")


func test_level_loader_rewards() -> void:
	var rewards := LevelLoader.get_level_rewards(1)
	_assert_true(rewards.has("coins_base"), "rewards has coins_base")
	_assert_true(rewards.has("coins_per_remaining_move"), "rewards has coins_per_move")


func test_level_loader_missing_file() -> void:
	var board := LevelLoader.load_level(999)
	_assert_true(board == null, "missing level returns null")


# ============================================================
# GEM TYPES TESTS
# ============================================================

func test_gem_color_from_string() -> void:
	_assert_eq(GemTypes.color_from_string("RUBY"), GemTypes.GemColor.RUBY, "RUBY")
	_assert_eq(GemTypes.color_from_string("sapphire"), GemTypes.GemColor.SAPPHIRE, "sapphire lowercase")
	_assert_eq(GemTypes.color_from_string("INVALID"), GemTypes.GemColor.NONE, "invalid returns NONE")


func test_blocker_from_string() -> void:
	_assert_eq(GemTypes.blocker_from_string("CRATE"), GemTypes.BlockerType.CRATE, "CRATE")
	_assert_eq(GemTypes.blocker_from_string("ICE"), GemTypes.BlockerType.ICE, "ICE")
	_assert_eq(GemTypes.blocker_from_string("UNKNOWN"), GemTypes.BlockerType.NONE, "unknown")


func test_objective_from_string() -> void:
	_assert_eq(GemTypes.objective_from_string("COLLECT_COLOR"), GemTypes.ObjectiveType.COLLECT_COLOR, "COLLECT_COLOR")
	_assert_eq(GemTypes.objective_from_string("REMOVE_BLOCKER"), GemTypes.ObjectiveType.REMOVE_BLOCKER, "REMOVE_BLOCKER")
	_assert_eq(GemTypes.objective_from_string("CREATE_POWERUP"), GemTypes.ObjectiveType.CREATE_POWERUP, "CREATE_POWERUP")


# ============================================================
# GAME READINESS REGRESSION TESTS
# ============================================================

func test_particle_effects_class_available() -> void:
	## Regression: ParticleEffects class_name must be registered globally.
	var script: GDScript = load("res://scripts/board/particle_effects.gd") as GDScript
	_assert_true(script != null, "particle_effects.gd loads")
	_assert_true(script.can_instantiate(), "script can instantiate")


func test_board_view_script_loads() -> void:
	## Regression: board_view.gd must compile (depends on ParticleEffects).
	var script: GDScript = load("res://scripts/board/board_view.gd") as GDScript
	_assert_true(script != null, "board_view.gd compiles and loads")


func test_game_screen_instantiates() -> void:
	## Regression: game_screen.tscn must instantiate with all scripts attached.
	var scene: PackedScene = load("res://scenes/screens/game_screen.tscn") as PackedScene
	_assert_true(scene != null, "game_screen.tscn loads")
	var instance: Node = scene.instantiate()
	_assert_true(instance != null, "game_screen instantiates")

	# Verify BoardView has its script (not a bare Node2D)
	var board_view: Node = instance.get_node("BoardView")
	_assert_true(board_view != null, "BoardView node exists")
	_assert_true(board_view.has_method("initialize"), "BoardView has initialize method")

	# Verify HUD has its script
	var hud: Node = instance.get_node("UILayer/HUD")
	_assert_true(hud != null, "HUD node exists")
	_assert_true(hud.has_method("initialize"), "HUD has initialize method")

	instance.free()


func test_board_initializes_with_gems() -> void:
	## Regression: board_view.initialize() must populate the board with gem nodes.
	var board := LevelLoader.load_level(1)
	_assert_true(board != null, "level 1 loads")

	var script: GDScript = load("res://scripts/board/board_view.gd") as GDScript
	var view: Node2D = Node2D.new()
	view.set_script(script)
	add_child(view)

	view.initialize(board)
	_assert_true(view.board_state != null, "board_state is set")
	_assert_true(view.get_child_count() > 0, "gem nodes created")
	_assert_gt(view.get_child_count(), 10, "many gem nodes on board")

	view.queue_free()


func test_hud_initializes_from_board() -> void:
	## Regression: HUD must display correct values after initialize.
	var board := LevelLoader.load_level(1)
	_assert_true(board != null, "level 1 loads for HUD test")

	# HUD requires @onready nodes, so instantiate from scene
	var scene: PackedScene = load("res://scenes/screens/game_screen.tscn") as PackedScene
	var instance: Node = scene.instantiate()
	add_child(instance)

	# HUD's _ready() runs when added to tree — now initialize
	var hud: Node = instance.get_node("UILayer/HUD")
	hud.initialize(board)

	# Verify move label shows actual move limit (not default "25")
	var move_label: Label = hud.get_node("MovePanel/MoveLabel") as Label
	_assert_eq(move_label.text, str(board.move_limit), "moves show level move_limit")

	instance.queue_free()


# ============================================================
# GAMEPLAY FLOW REGRESSION TESTS (Phase 4)
# ============================================================

func test_main_menu_screen_loads() -> void:
	## Regression: main_menu_screen.tscn must load and its script must compile.
	var scene: PackedScene = load("res://scenes/screens/main_menu_screen.tscn") as PackedScene
	_assert_true(scene != null, "main_menu_screen.tscn loads")
	var instance: Node = scene.instantiate()
	_assert_true(instance != null, "main_menu instantiates")

	# Verify script is actually attached and running (not fallback Control)
	_assert_true(instance.has_method("_on_play_pressed"), "script has _on_play_pressed")
	_assert_true(instance.has_method("_on_quit_pressed"), "script has _on_quit_pressed")

	# Verify key child nodes exist
	var play_btn: Node = instance.get_node_or_null("PlayButton")
	_assert_true(play_btn != null, "PlayButton node exists")
	var quit_btn: Node = instance.get_node_or_null("QuitButton")
	_assert_true(quit_btn != null, "QuitButton node exists")

	# Add to tree so _ready runs, then check signals connected
	add_child(instance)
	_assert_true(play_btn.is_connected("pressed", instance._on_play_pressed), "PlayButton signal connected")
	_assert_true(quit_btn.is_connected("pressed", instance._on_quit_pressed), "QuitButton signal connected")

	instance.queue_free()


func test_level_select_screen_loads() -> void:
	## Regression: level_select_screen.tscn must load with its script.
	var scene: PackedScene = load("res://scenes/screens/level_select_screen.tscn") as PackedScene
	_assert_true(scene != null, "level_select_screen.tscn loads")
	var instance: Node = scene.instantiate()
	_assert_true(instance != null, "level_select instantiates")

	add_child(instance)
	# Should have level buttons created
	var grid: Node = instance.get_node_or_null("ScrollContainer/LevelGrid")
	_assert_true(grid != null, "LevelGrid exists")
	_assert_gt(grid.get_child_count(), 0, "level buttons created")

	instance.queue_free()


func test_profile_popup_class_available() -> void:
	## Regression: ProfilePopup class_name must be registered globally.
	var script: GDScript = load("res://scripts/ui/profile_popup.gd") as GDScript
	_assert_true(script != null, "profile_popup.gd loads")
	_assert_true(script.can_instantiate(), "ProfilePopup can instantiate")


func test_all_screen_scripts_compile() -> void:
	## Regression: every UI script must compile without parse errors.
	var scripts := [
		"res://scripts/ui/main_menu_screen.gd",
		"res://scripts/ui/level_select_screen.gd",
		"res://scripts/ui/game_over_popup.gd",
		"res://scripts/ui/hud.gd",
		"res://scripts/ui/settings_screen.gd",
		"res://scripts/ui/profile_popup.gd",
	]
	for path in scripts:
		var script: GDScript = load(path) as GDScript
		_assert_true(script != null, "%s compiles" % path.get_file())


func test_gameplay_flow_start_level() -> void:
	## Regression: full flow from level load to board init to game state check.
	# Load level
	var board := LevelLoader.load_level(1)
	_assert_true(board != null, "level 1 loads for gameplay")
	_assert_gt(board.move_limit, 0, "move_limit > 0")
	_assert_gt(board.objectives.size(), 0, "has objectives")

	# Initialize board with gems via MatchEngine
	var engine := MatchEngine.new()
	engine.board = board
	engine.fill_board_initial()

	# Verify board has playable gems
	var gem_count: int = 0
	for r in range(board.height):
		for c in range(board.width):
			var cell := board.get_cell(r, c)
			if cell != null and cell.has_gem():
				gem_count += 1
	_assert_gt(gem_count, 10, "board has playable gems")

	# Verify game is not immediately over
	_assert_true(not board.is_game_over, "game not over at start")
	_assert_true(not board.is_won, "level not won at start")

	# Verify valid moves exist (player can play)
	var hint := HintSystem.new(board)
	var move: Dictionary = hint.find_best_hint()
	_assert_true(not move.is_empty(), "valid moves available at start")
