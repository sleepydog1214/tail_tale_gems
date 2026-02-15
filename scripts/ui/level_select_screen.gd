extends Control
## Simple level selection screen for Phase 1.
## Shows buttons for available levels.

signal level_selected(level_id: int)

@onready var level_grid: GridContainer = $ScrollContainer/LevelGrid
@onready var title_label: Label = $TitleLabel

var max_level: int = 10  # Phase 2: 5 tutorial + 5 easy levels


func _ready() -> void:
	_create_level_buttons()
	level_selected.connect(_on_level_selected)

	# Style title
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color("f1c40f"))

	# Wire back button if present
	var back_btn = get_node_or_null("BackButton")
	if back_btn:
		back_btn.pressed.connect(_on_back_pressed)
		# Style back button
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


func _on_level_selected(level_id: int) -> void:
	GameManager.start_level(level_id)


func _on_back_pressed() -> void:
	GameManager.go_to_main_menu()


func _create_level_buttons() -> void:
	# Clear existing
	for child in level_grid.get_children():
		child.queue_free()

	for i in range(1, max_level + 1):
		var btn := Button.new()
		btn.text = str(i)
		btn.custom_minimum_size = Vector2(80, 80)
		btn.add_theme_font_size_override("font_size", 24)

		# Style the button
		var style := StyleBoxFlat.new()
		style.bg_color = Color("3498db")
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 8
		style.content_margin_bottom = 8
		btn.add_theme_stylebox_override("normal", style)

		var hover_style: StyleBoxFlat = style.duplicate() as StyleBoxFlat
		hover_style.bg_color = Color("2980b9")
		btn.add_theme_stylebox_override("hover", hover_style)

		var pressed_style: StyleBoxFlat = style.duplicate() as StyleBoxFlat
		pressed_style.bg_color = Color("1a5276")
		btn.add_theme_stylebox_override("pressed", pressed_style)

		btn.add_theme_color_override("font_color", Color.WHITE)

		var level_id := i
		btn.pressed.connect(func(): level_selected.emit(level_id))

		level_grid.add_child(btn)
