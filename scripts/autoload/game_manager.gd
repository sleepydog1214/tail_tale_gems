extends Node
## Global game manager singleton (AutoLoad).
## Manages screen transitions, level loading, game state, energy, and boosters.
## Phase 3: Full persistence via SaveManager, energy system, booster support.

signal level_started(level_id: int)
signal level_won(level_id: int, stars: int, score: int)
signal level_lost(level_id: int)
signal screen_changed(screen_name: String)
signal coins_changed(new_total: int)
signal energy_changed(new_total: int)
signal booster_used(booster_type: String)

# Current state
var current_level_id: int = 1
var current_board: BoardState
var current_screen: Node = null

# Scene paths
const GAME_SCREEN_PATH := "res://scenes/screens/game_screen.tscn"
const LEVEL_SELECT_PATH := "res://scenes/screens/level_select_screen.tscn"
const MAIN_MENU_PATH := "res://scenes/screens/main_menu_screen.tscn"
const SETTINGS_PATH := "res://scenes/screens/settings_screen.tscn"

# Booster types
const BOOSTER_HAMMER := "hammer"
const BOOSTER_SHUFFLE := "shuffle"
const BOOSTER_ROW_BLAST := "row_blast"
const BOOSTER_COL_BLAST := "col_blast"
const BOOSTER_STARTING_ROCKET := "starting_rocket"
const BOOSTER_STARTING_BOMB := "starting_bomb"
const BOOSTER_STARTING_PRISM := "starting_prism"
const BOOSTER_EXTRA_MOVES := "extra_moves"

# Pre-game boosters selected for current level
var selected_pre_boosters: Array[String] = []


func _ready() -> void:
	pass


# ============================================================
# CONVENIENCE ACCESSORS (delegate to SaveManager)
# ============================================================

func get_stars_for_level(level_id: int) -> int:
	return SaveManager.get_level_stars(level_id)

func get_total_stars() -> int:
	return SaveManager.get_total_stars()

func get_coins() -> int:
	return SaveManager.get_coins()

func get_energy() -> int:
	return SaveManager.get_energy()

func get_max_level_available() -> int:
	return SaveManager.get_max_level_available()


# ============================================================
# LEVEL FLOW
# ============================================================

func start_level(level_id: int) -> void:
	## Load and start a specific level.
	current_level_id = level_id

	# Consume energy (skip on retry — handled separately)
	if not SaveManager.consume_energy(1):
		push_warning("Not enough energy to start level %d" % level_id)
		# Still allow play — energy is a soft gate
		# return

	var board := LevelLoader.load_level(level_id)
	if board == null:
		push_error("Failed to load level %d" % level_id)
		SaveManager.refund_energy(1)
		return

	current_board = board

	# Apply pre-game boosters
	_apply_pre_game_boosters(board)
	selected_pre_boosters.clear()

	_switch_to_game_screen()
	energy_changed.emit(get_energy())
	level_started.emit(level_id)
	SaveManager.increment_stat("total_levels_played")
	AudioManager.play_sfx("level_start")


func restart_current_level() -> void:
	start_level(current_level_id)


func on_level_complete() -> void:
	## Called when a level is won.
	if current_board == null:
		return

	var stars: int = current_board.get_stars()
	var score: int = current_board.score

	# Save stars
	SaveManager.set_level_stars(current_level_id, stars, score)

	# Calculate and award coins
	var rewards: Dictionary = LevelLoader.get_level_rewards(current_level_id)
	var remaining_moves: int = current_board.move_limit - current_board.move_count
	var coins: int = int(rewards.get("coins_base", 50)) + remaining_moves * int(rewards.get("coins_per_remaining_move", 5))
	SaveManager.add_coins(coins)

	# Refund energy on win
	SaveManager.refund_energy(1)

	# Stats
	SaveManager.increment_stat("total_wins")

	coins_changed.emit(get_coins())
	energy_changed.emit(get_energy())
	level_won.emit(current_level_id, stars, score)
	AudioManager.play_sfx("level_win")


func on_level_failed() -> void:
	## Called when a level is lost.
	SaveManager.increment_stat("total_losses")
	level_lost.emit(current_level_id)
	AudioManager.play_sfx("level_lose")


func go_to_next_level() -> void:
	start_level(current_level_id + 1)


func go_to_level_select() -> void:
	_switch_to_screen(LEVEL_SELECT_PATH)
	AudioManager.play_music("menu")


func go_to_main_menu() -> void:
	_switch_to_screen(MAIN_MENU_PATH)
	AudioManager.play_music("menu")


func go_to_settings() -> void:
	_switch_to_screen(SETTINGS_PATH)


# ============================================================
# BOOSTERS
# ============================================================

func select_pre_booster(booster_type: String) -> bool:
	## Select a pre-game booster to apply at level start. Max 2.
	if selected_pre_boosters.size() >= 2:
		return false
	if SaveManager.get_booster_count(booster_type) <= 0:
		return false
	selected_pre_boosters.append(booster_type)
	return true


func deselect_pre_booster(booster_type: String) -> void:
	selected_pre_boosters.erase(booster_type)


func use_ingame_booster(booster_type: String) -> bool:
	## Consume an in-game booster from inventory.
	if SaveManager.use_booster(booster_type):
		booster_used.emit(booster_type)
		SaveManager.increment_stat("total_boosters_used")
		AudioManager.play_sfx("booster_use")
		return true
	return false


func _apply_pre_game_boosters(board: BoardState) -> void:
	## Apply selected pre-game boosters to the board.
	for booster in selected_pre_boosters:
		if not SaveManager.use_booster(booster):
			continue  # Not enough in inventory

		match booster:
			BOOSTER_STARTING_ROCKET:
				_place_random_powerup(board, GemTypes.PowerUpType.ROCKET_H)
			BOOSTER_STARTING_BOMB:
				_place_random_powerup(board, GemTypes.PowerUpType.BOMB)
			BOOSTER_STARTING_PRISM:
				_place_random_powerup(board, GemTypes.PowerUpType.PRISM)
			BOOSTER_EXTRA_MOVES:
				board.move_limit += 3

		SaveManager.increment_stat("total_boosters_used")


func _place_random_powerup(board: BoardState, pup: GemTypes.PowerUpType) -> void:
	## Place a power-up on a random playable cell.
	var candidates: Array[Vector2i] = []
	for r in range(board.height):
		for c in range(board.width):
			var cell := board.get_cell(r, c)
			if cell != null and not cell.is_empty and cell.has_gem() and not cell.has_blocker():
				candidates.append(Vector2i(r, c))
	if candidates.is_empty():
		return
	var pos: Vector2i = candidates[randi() % candidates.size()]
	board.get_cell(pos.x, pos.y).power_up = pup


# ============================================================
# SCREEN MANAGEMENT
# ============================================================

func _switch_to_game_screen() -> void:
	_switch_to_screen(GAME_SCREEN_PATH)


func _switch_to_screen(scene_path: String) -> void:
	var tree := get_tree()
	if tree == null:
		return

	var root := tree.root
	if tree.current_scene:
		tree.current_scene.queue_free()

	var scene: PackedScene = load(scene_path) as PackedScene
	if scene == null:
		push_error("Failed to load scene: %s" % scene_path)
		return

	var instance: Node = scene.instantiate()
	root.add_child(instance)
	tree.current_scene = instance
	current_screen = instance
	screen_changed.emit(scene_path.get_file().get_basename())
