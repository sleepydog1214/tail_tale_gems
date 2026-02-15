extends Control
## Heads-up display showing move counter, objectives, score, energy, and boosters.
## Phase 3: Added energy display and in-game booster toolbar.

@onready var move_label: Label = $MovePanel/MoveLabel
@onready var score_label: Label = $ScorePanel/ScoreLabel
@onready var objective_container: VBoxContainer = $ObjectivePanel/ObjectiveList
@onready var level_label: Label = $LevelLabel

var board_state: BoardState
var _objective_labels: Array[Label] = []
var _prev_score: int = 0
var _prev_moves: int = -1
var _energy_label: Label
var _booster_bar: HBoxContainer


func _ready() -> void:
	# Style HUD labels
	if level_label:
		level_label.add_theme_font_size_override("font_size", 20)
		level_label.add_theme_color_override("font_color", Color("f1c40f"))
	if move_label:
		move_label.add_theme_font_size_override("font_size", 32)
		move_label.add_theme_color_override("font_color", Color.WHITE)
	if score_label:
		score_label.add_theme_font_size_override("font_size", 20)
		score_label.add_theme_color_override("font_color", Color.WHITE)

	# Style panels with dark backgrounds
	_style_panel($MovePanel, Color(0.12, 0.14, 0.24, 0.9))
	_style_panel($ScorePanel, Color(0.12, 0.14, 0.24, 0.9))
	_style_panel($ObjectivePanel, Color(0.10, 0.12, 0.20, 0.8))

	# Energy display
	_energy_label = Label.new()
	_energy_label.name = "EnergyLabel"
	_energy_label.set_anchors_preset(PRESET_TOP_WIDE)
	_energy_label.offset_left = 220
	_energy_label.offset_top = 55
	_energy_label.offset_right = 320
	_energy_label.offset_bottom = 75
	_energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_energy_label.add_theme_font_size_override("font_size", 14)
	_energy_label.add_theme_color_override("font_color", Color("3498db"))
	add_child(_energy_label)

	# Booster toolbar at bottom
	_create_booster_bar()


func _create_booster_bar() -> void:
	_booster_bar = HBoxContainer.new()
	_booster_bar.name = "BoosterBar"
	_booster_bar.set_anchors_preset(PRESET_BOTTOM_WIDE)
	_booster_bar.offset_top = -55
	_booster_bar.offset_left = 10
	_booster_bar.offset_right = -10
	_booster_bar.offset_bottom = -5
	_booster_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_booster_bar.add_theme_constant_override("separation", 8)
	add_child(_booster_bar)

	# In-game boosters: hammer, shuffle, row_blast, col_blast
	var boosters: Array[Dictionary] = [
		{"type": "hammer", "icon": "🔨", "label": "Hammer"},
		{"type": "shuffle", "icon": "🔀", "label": "Shuffle"},
		{"type": "row_blast", "icon": "➡", "label": "Row"},
		{"type": "col_blast", "icon": "⬇", "label": "Col"},
	]

	for b in boosters:
		var count: int = SaveManager.get_booster_count(str(b["type"]))
		var btn := Button.new()
		btn.text = "%s %d" % [str(b["icon"]), count]
		btn.tooltip_text = str(b["label"])
		btn.custom_minimum_size = Vector2(70, 44)
		btn.disabled = count <= 0
		btn.add_theme_font_size_override("font_size", 16)

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.18, 0.22, 0.35, 0.9) if count > 0 else Color(0.12, 0.14, 0.22, 0.6)
		style.corner_radius_top_left = 10
		style.corner_radius_top_right = 10
		style.corner_radius_bottom_left = 10
		style.corner_radius_bottom_right = 10
		btn.add_theme_stylebox_override("normal", style)
		var hover: StyleBoxFlat = style.duplicate() as StyleBoxFlat
		hover.bg_color = Color(0.24, 0.30, 0.48, 0.9)
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_color_override("font_color", Color.WHITE if count > 0 else Color("666666"))
		btn.add_theme_color_override("font_disabled_color", Color("444444"))

		var booster_type: String = str(b["type"])
		btn.pressed.connect(func(): _on_booster_pressed(booster_type))
		_booster_bar.add_child(btn)


func _style_panel(panel: PanelContainer, bg_color: Color) -> void:
	if panel == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	style.border_width_bottom = 2
	style.border_color = Color(0.2, 0.24, 0.38, 0.6)
	panel.add_theme_stylebox_override("panel", style)


func initialize(state: BoardState) -> void:
	board_state = state
	_prev_score = 0
	_prev_moves = state.move_limit
	_setup_objectives()
	_update_display()


func _process(_delta: float) -> void:
	if board_state != null:
		_update_display()


func _setup_objectives() -> void:
	for child in objective_container.get_children():
		child.queue_free()
	_objective_labels.clear()

	for obj in board_state.objectives:
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)

		# Objective icon
		var icon := Label.new()
		icon.text = obj.get_icon_label()
		icon.add_theme_font_size_override("font_size", 18)
		icon.add_theme_color_override("font_color", Color("f39c12"))
		icon.custom_minimum_size = Vector2(24, 0)
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hbox.add_child(icon)

		# Objective text
		var label := Label.new()
		label.add_theme_font_size_override("font_size", 15)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(label)

		objective_container.add_child(hbox)
		_objective_labels.append(label)


func _update_display() -> void:
	if board_state == null:
		return

	# Energy
	_update_energy()

	# Move counter with low-move warning
	var remaining := board_state.move_limit - board_state.move_count
	move_label.text = str(remaining)
	if remaining <= 3:
		move_label.add_theme_color_override("font_color", Color("e74c3c"))
	elif remaining <= 5:
		move_label.add_theme_color_override("font_color", Color("f39c12"))
	else:
		move_label.add_theme_color_override("font_color", Color.WHITE)

	# Animate move count decrease
	if remaining != _prev_moves and _prev_moves >= 0:
		_prev_moves = remaining
		_pulse_node(move_label)

	# Score with animation on change
	var current_score := board_state.score
	score_label.text = str(current_score)
	if current_score != _prev_score:
		_prev_score = current_score
		_pulse_node(score_label)

	# Level
	level_label.text = "Level %d" % board_state.level_id

	# Objectives
	for i in range(board_state.objectives.size()):
		if i < _objective_labels.size():
			var obj := board_state.objectives[i]
			_objective_labels[i].text = obj.get_display_text()
			if obj.is_complete():
				_objective_labels[i].add_theme_color_override("font_color", Color("2ecc71"))
			else:
				_objective_labels[i].add_theme_color_override("font_color", Color.WHITE)


func _pulse_node(node: Control) -> void:
	## Brief scale pulse to draw attention.
	var tween := create_tween()
	tween.tween_property(node, "scale", Vector2(1.2, 1.2), 0.08).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", Vector2.ONE, 0.12).set_ease(Tween.EASE_IN)


func _on_booster_pressed(booster_type: String) -> void:
	if GameManager.use_ingame_booster(booster_type):
		# Refresh booster bar
		_refresh_booster_bar()


func _refresh_booster_bar() -> void:
	if _booster_bar == null:
		return
	for child in _booster_bar.get_children():
		child.queue_free()
	_create_booster_bar()

func _update_energy() -> void:
	if _energy_label:
		var energy: int = SaveManager.get_energy()
		_energy_label.text = "⚡ %d" % energy
