extends Node2D
## Handles player input (touch/mouse) and routes it to the BoardView.
## This is attached to the GameScreen scene.

@onready var board_view: Node2D = $BoardView
@onready var hud: Control = $UILayer/HUD
@onready var game_over_popup: Control = $UILayer/GameOverPopup

var _drag_start: Vector2 = Vector2.ZERO
var _is_dragging: bool = false
var _drag_start_board_pos: Vector2 = Vector2.ZERO
const MIN_SWIPE_DISTANCE := 20.0


func _ready() -> void:
	# If current_board is null (e.g. scene ran directly), load level 1 as fallback
	if GameManager.current_board == null:
		GameManager.current_level_id = 1
		var board := LevelLoader.load_level(1)
		if board != null:
			GameManager.current_board = board

	# Initialize board from GameManager's current level
	if GameManager.current_board != null:
		board_view.initialize(GameManager.current_board)
		hud.initialize(GameManager.current_board)
		board_view.animation_finished.connect(_check_game_state)
	else:
		push_error("BoardController: No board state available!")

	# Connect game over popup signals
	if game_over_popup:
		game_over_popup.next_level_pressed.connect(_on_next_level)
		game_over_popup.retry_pressed.connect(_on_retry)
		game_over_popup.menu_pressed.connect(_on_menu)


func _unhandled_input(event: InputEvent) -> void:
	if board_view == null or board_view.board_state == null:
		return

	if board_view.get_animating():
		return

	if board_view.board_state.is_game_over:
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			var board_local := _screen_to_board(mouse_event.position)
			if mouse_event.pressed:
				_drag_start = mouse_event.position
				_drag_start_board_pos = board_local
				_is_dragging = true
			else:
				if _is_dragging:
					var drag_delta := mouse_event.position - _drag_start
					if drag_delta.length() >= MIN_SWIPE_DISTANCE:
						# Swipe
						board_view.handle_swipe(_drag_start_board_pos, drag_delta)
					else:
						# Click/Tap
						board_view.handle_input_at(_drag_start_board_pos)
					_is_dragging = false

	elif event is InputEventMouseMotion and _is_dragging:
		var motion_event := event as InputEventMouseMotion
		var drag_delta := motion_event.position - _drag_start
		if drag_delta.length() >= MIN_SWIPE_DISTANCE:
			# Early swipe detection
			board_view.handle_swipe(_drag_start_board_pos, drag_delta)
			_is_dragging = false

	elif event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		var board_local := _screen_to_board(touch_event.position)
		if touch_event.pressed:
			_drag_start = touch_event.position
			_drag_start_board_pos = board_local
			_is_dragging = true
		else:
			if _is_dragging:
				var drag_delta := touch_event.position - _drag_start
				if drag_delta.length() >= MIN_SWIPE_DISTANCE:
					board_view.handle_swipe(_drag_start_board_pos, drag_delta)
				else:
					board_view.handle_input_at(_drag_start_board_pos)
				_is_dragging = false

	elif event is InputEventScreenDrag and _is_dragging:
		var drag_event := event as InputEventScreenDrag
		var drag_delta := drag_event.position - _drag_start
		if drag_delta.length() >= MIN_SWIPE_DISTANCE:
			board_view.handle_swipe(_drag_start_board_pos, drag_delta)
			_is_dragging = false

	# Keyboard shortcuts
	if event is InputEventKey and event.pressed:
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_H:
			board_view._show_hint()
		elif key_event.keycode == KEY_R:
			_restart_level()


func _screen_to_board(screen_pos: Vector2) -> Vector2:
	## Convert screen coordinates to board-local coordinates.
	return screen_pos - board_view.position


func _restart_level() -> void:
	if GameManager:
		GameManager.restart_current_level()


func _check_game_state() -> void:
	## Called after each animation cycle. Check if the level is won or lost.
	if board_view.board_state == null:
		return
	if not board_view.board_state.is_game_over:
		return

	if board_view.board_state.is_won:
		GameManager.on_level_complete()
		var stars: int = board_view.board_state.get_stars()
		var score: int = board_view.board_state.score
		# Calculate coins for display
		var rewards: Dictionary = LevelLoader.get_level_rewards(GameManager.current_level_id)
		var remaining: int = board_view.board_state.move_limit - board_view.board_state.move_count
		var coins: int = int(rewards.get("coins_base", 50)) + remaining * int(rewards.get("coins_per_remaining_move", 5))
		if game_over_popup:
			game_over_popup.show_win(stars, score, coins)
	else:
		GameManager.on_level_failed()
		if game_over_popup:
			game_over_popup.show_lose(board_view.board_state.score)


func _on_next_level() -> void:
	GameManager.go_to_next_level()


func _on_retry() -> void:
	GameManager.restart_current_level()


func _on_menu() -> void:
	GameManager.go_to_level_select()
