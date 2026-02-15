extends Control
## Level selection screen with star display, lock state, and energy display.
## Phase 3: Stars, locks, energy gating.

signal level_selected(level_id: int)

@onready var level_grid: GridContainer = $ScrollContainer/LevelGrid
@onready var title_label: Label = $TitleLabel

var max_level: int = 50  # Phase 3: 50 levels across chapters
var _energy_label: Label


func _ready() -> void:
	_create_level_buttons()
	level_selected.connect(_on_level_selected)

	# Style title
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color("f1c40f"))

	# Add energy display below title
	_energy_label = Label.new()
	_energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_energy_label.set_anchors_preset(PRESET_TOP_WIDE)
	_energy_label.offset_top = 70
	_energy_label.offset_bottom = 95
	_energy_label.offset_left = 40
	_energy_label.offset_right = -40
	_energy_label.add_theme_font_size_override("font_size", 16)
	_energy_label.add_theme_color_override("font_color", Color("3498db"))
	add_child(_energy_label)
	_update_energy_display()

	# Wire back button if present
	var back_btn = get_node_or_null("BackButton")
	if back_btn:
		back_btn.pressed.connect(_on_back_pressed)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("34495e")
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		back_btn.add_theme_stylebox_override("normal", style)
		var hover_style: StyleBoxFlat = style.duplicate() as StyleBoxFlat
		hover_style.bg_color = Color("4a6785")
		back_btn.add_theme_stylebox_override("hover", hover_style)
		back_btn.add_theme_color_override("font_color", Color.WHITE)
		back_btn.add_theme_font_size_override("font_size", 18)


func _update_energy_display() -> void:
	if _energy_label:
		var energy: int = SaveManager.get_energy()
		_energy_label.text = "Energy: %d / 15" % energy
		if energy <= 0:
			_energy_label.add_theme_color_override("font_color", Color("e74c3c"))
		elif energy <= 3:
			_energy_label.add_theme_color_override("font_color", Color("f39c12"))
		else:
			_energy_label.add_theme_color_override("font_color", Color("3498db"))


func _on_level_selected(level_id: int) -> void:
	AudioManager.play_sfx("button_click")
	GameManager.start_level(level_id)


func _on_back_pressed() -> void:
	AudioManager.play_sfx("button_click")
	GameManager.go_to_main_menu()


func _create_level_buttons() -> void:
	# Clear existing
	for child in level_grid.get_children():
		child.queue_free()

	var unlocked_level: int = SaveManager.get_max_level_available()

	for i in range(1, max_level + 1):
		var is_locked: bool = i > unlocked_level
		var stars: int = SaveManager.get_level_stars(i)

		var container := VBoxContainer.new()
		container.custom_minimum_size = Vector2(80, 95)
		container.add_theme_constant_override("separation", 2)

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(80, 65)
		btn.add_theme_font_size_override("font_size", 22)

		if is_locked:
			btn.text = "🔒"
			btn.disabled = true
			var style := StyleBoxFlat.new()
			style.bg_color = Color("2c3e50")
			style.corner_radius_top_left = 12
			style.corner_radius_top_right = 12
			style.corner_radius_bottom_left = 12
			style.corner_radius_bottom_right = 12
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("disabled", style)
			btn.add_theme_color_override("font_color", Color("7f8c8d"))
			btn.add_theme_color_override("font_disabled_color", Color("7f8c8d"))
		else:
			btn.text = str(i)
			var bg_color: Color
			if stars >= 3:
				bg_color = Color("27ae60")  # Green for 3 stars
			elif stars >= 1:
				bg_color = Color("3498db")  # Blue for completed
			else:
				bg_color = Color("8e44ad")  # Purple for available
			var style := StyleBoxFlat.new()
			style.bg_color = bg_color
			style.corner_radius_top_left = 12
			style.corner_radius_top_right = 12
			style.corner_radius_bottom_left = 12
			style.corner_radius_bottom_right = 12
			style.content_margin_left = 4
			style.content_margin_right = 4
			style.content_margin_top = 4
			style.content_margin_bottom = 4
			btn.add_theme_stylebox_override("normal", style)
			var hover_style: StyleBoxFlat = style.duplicate() as StyleBoxFlat
			hover_style.bg_color = bg_color.lightened(0.15)
			btn.add_theme_stylebox_override("hover", hover_style)
			var pressed_style: StyleBoxFlat = style.duplicate() as StyleBoxFlat
			pressed_style.bg_color = bg_color.darkened(0.2)
			btn.add_theme_stylebox_override("pressed", pressed_style)
			btn.add_theme_color_override("font_color", Color.WHITE)

			var level_id := i
			btn.pressed.connect(func(): level_selected.emit(level_id))

		container.add_child(btn)

		# Star display
		var star_label := Label.new()
		star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star_label.add_theme_font_size_override("font_size", 14)
		if is_locked:
			star_label.text = "   "
		else:
			var star_text := ""
			for s in range(3):
				star_text += "★" if s < stars else "☆"
			star_label.text = star_text
			star_label.add_theme_color_override("font_color", Color("f1c40f") if stars > 0 else Color("555555"))
		container.add_child(star_label)

		level_grid.add_child(container)
