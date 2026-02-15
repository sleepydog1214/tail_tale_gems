extends Node
## Global game manager singleton (AutoLoad).
## Manages screen transitions, level loading, and game state.

signal level_started(level_id: int)
signal level_won(level_id: int, stars: int, score: int)
signal level_lost(level_id: int)
signal screen_changed(screen_name: String)

# Current state
var current_level_id: int = 1
var current_board: BoardState
var current_screen: Node = null

# Player progress (Phase 1: simple tracking, not saved yet)
var stars_per_level: Dictionary = {}  # level_id -> stars
var total_stars: int = 0
var total_coins: int = 0

# Scene paths
const GAME_SCREEN_PATH := "res://scenes/screens/game_screen.tscn"
const LEVEL_SELECT_PATH := "res://scenes/screens/level_select_screen.tscn"
const MAIN_MENU_PATH := "res://scenes/screens/main_menu_screen.tscn"


func _ready() -> void:
	# Game starts at main menu
	pass


func start_level(level_id: int) -> void:
	## Load and start a specific level.
	current_level_id = level_id

	var board := LevelLoader.load_level(level_id)
	if board == null:
		push_error("Failed to load level %d" % level_id)
		return

	current_board = board
	_switch_to_game_screen()
	level_started.emit(level_id)


func restart_current_level() -> void:
	start_level(current_level_id)


func on_level_complete() -> void:
	## Called when a level is won.
	if current_board == null:
		return

	var stars := current_board.get_stars()
	var score := current_board.score

	# Track best stars
	var prev_stars: int = stars_per_level.get(current_level_id, 0)
	if stars > prev_stars:
		total_stars += (stars - prev_stars)
		stars_per_level[current_level_id] = stars

	# Calculate coins
	var rewards: Dictionary = LevelLoader.get_level_rewards(current_level_id)
	var remaining_moves := current_board.move_limit - current_board.move_count
	var coins: int = int(rewards.get("coins_base", 50)) + remaining_moves * int(rewards.get("coins_per_remaining_move", 5))
	total_coins += coins

	level_won.emit(current_level_id, stars, score)


func on_level_failed() -> void:
	## Called when a level is lost.
	level_lost.emit(current_level_id)


func go_to_next_level() -> void:
	start_level(current_level_id + 1)


func go_to_level_select() -> void:
	_switch_to_screen(LEVEL_SELECT_PATH)


func go_to_main_menu() -> void:
	_switch_to_screen(MAIN_MENU_PATH)


func _switch_to_game_screen() -> void:
	_switch_to_screen(GAME_SCREEN_PATH)


func _switch_to_screen(scene_path: String) -> void:
	# Remove current screen
	var tree := get_tree()
	if tree == null:
		return

	var root := tree.root
	# Remove the old main scene
	if tree.current_scene:
		tree.current_scene.queue_free()

	# Load and instantiate new scene
	var scene: PackedScene = load(scene_path) as PackedScene
	if scene == null:
		push_error("Failed to load scene: %s" % scene_path)
		return

	var instance: Node = scene.instantiate()
	root.add_child(instance)
	tree.current_scene = instance
	current_screen = instance
	screen_changed.emit(scene_path.get_file().get_basename())
