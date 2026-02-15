extends Control
## Popup displayed when a level ends (win or lose).

signal next_level_pressed
signal retry_pressed
signal menu_pressed

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var message_label: Label = $Panel/VBox/MessageLabel
@onready var stars_label: Label = $Panel/VBox/StarsLabel
@onready var score_label: Label = $Panel/VBox/ScoreLabel
@onready var next_button: Button = $Panel/VBox/ButtonRow/NextButton
@onready var retry_button: Button = $Panel/VBox/ButtonRow/RetryButton
@onready var menu_button: Button = $Panel/VBox/ButtonRow/MenuButton


func _ready() -> void:
	visible = false
	next_button.pressed.connect(func(): next_level_pressed.emit())
	retry_button.pressed.connect(func(): retry_pressed.emit())
	menu_button.pressed.connect(func(): menu_pressed.emit())

	# Style the panel
	var panel := $Panel as Panel
	if panel:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.96, 0.88, 0.92, 0.95)
		style.corner_radius_top_left = 20
		style.corner_radius_top_right = 20
		style.corner_radius_bottom_left = 20
		style.corner_radius_bottom_right = 20
		style.border_width_top = 3
		style.border_width_bottom = 3
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_color = Color("e84393")
		style.shadow_color = Color(0, 0, 0, 0.5)
		style.shadow_size = 8
		panel.add_theme_stylebox_override("panel", style)

	# Style title
	title_label.add_theme_font_size_override("font_size", 32)

	# Style stars
	stars_label.add_theme_font_size_override("font_size", 40)

	# Style score
	score_label.add_theme_font_size_override("font_size", 20)
	score_label.add_theme_color_override("font_color", Color("a0628a"))

	# Style message
	message_label.add_theme_font_size_override("font_size", 16)
	message_label.add_theme_color_override("font_color", Color("a0628a"))

	# Style buttons
	_style_button(next_button, Color("e84393"), Color("c0327a"))
	_style_button(retry_button, Color("fd79a8"), Color("e84393"))
	_style_button(menu_button, Color("a0628a"), Color("8b4f78"))


func _style_button(btn: Button, bg_color: Color, border_color: Color) -> void:
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color.WHITE)

	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.border_width_bottom = 3
	style.border_color = border_color
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", style)

	var hover: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	hover.bg_color = bg_color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	pressed.bg_color = border_color
	pressed.border_width_bottom = 1
	pressed.content_margin_top = 10
	btn.add_theme_stylebox_override("pressed", pressed)


func show_win(stars: int, score: int, coins: int) -> void:
	title_label.text = "🐱 Level Complete! 🐱"
	title_label.add_theme_color_override("font_color", Color("e84393"))

	var star_text := ""
	for i in range(3):
		star_text += "★" if i < stars else "☆"
	stars_label.text = star_text
	stars_label.add_theme_color_override("font_color", Color("e84393"))

	score_label.text = "Score: %d" % score

	# Show coins earned and total progress
	var total_stars: int = SaveManager.get_total_stars()
	message_label.text = "+%d coins  •  ⭐ %d total stars" % [coins, total_stars]

	next_button.visible = true
	retry_button.visible = true

	# Update panel border to gold for win
	var panel := $Panel as Panel
	if panel:
		var style: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			var win_style: StyleBoxFlat = style.duplicate() as StyleBoxFlat
			win_style.border_color = Color("e84393")
			panel.add_theme_stylebox_override("panel", win_style)

	_show_animated()


func show_lose(score: int) -> void:
	title_label.text = "😿 Out of Moves!"
	title_label.add_theme_color_override("font_color", Color("e74c3c"))
	stars_label.text = "☆☆☆"
	stars_label.add_theme_color_override("font_color", Color("666666"))
	score_label.text = "Score: %d" % score
	message_label.text = "Try again, nya~?"
	next_button.visible = false
	retry_button.visible = true

	# Update panel border to red for lose
	var panel := $Panel as Panel
	if panel:
		var style: StyleBoxFlat = panel.get_theme_stylebox("panel") as StyleBoxFlat
		if style:
			var lose_style: StyleBoxFlat = style.duplicate() as StyleBoxFlat
			lose_style.border_color = Color("e74c3c")
			panel.add_theme_stylebox_override("panel", lose_style)

	_show_animated()


func _show_animated() -> void:
	visible = true
	modulate.a = 0
	var panel := $Panel
	if panel:
		panel.scale = Vector2(0.8, 0.8)
		panel.pivot_offset = panel.size / 2.0

	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT)
	if panel:
		tween.tween_property(panel, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
