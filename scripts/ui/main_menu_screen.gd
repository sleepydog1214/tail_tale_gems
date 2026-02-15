extends Control
## Main menu screen with animated title, Play and Quit buttons.

var _title_time: float = 0.0


func _ready() -> void:
	$PlayButton.pressed.connect(_on_play_pressed)
	$QuitButton.pressed.connect(_on_quit_pressed)

	# Style the title
	$TitleLabel.add_theme_font_size_override("font_size", 40)
	$TitleLabel.add_theme_color_override("font_color", Color("f1c40f"))
	$TitleLabel.pivot_offset = $TitleLabel.size / 2.0

	$SubtitleLabel.add_theme_font_size_override("font_size", 16)
	$SubtitleLabel.add_theme_color_override("font_color", Color("bdc3c7"))
	$SubtitleLabel.text = "A Match-3 Puzzle Adventure"

	$PlayButton.add_theme_font_size_override("font_size", 26)
	$QuitButton.add_theme_font_size_override("font_size", 18)
	$VersionLabel.add_theme_font_size_override("font_size", 12)
	$VersionLabel.add_theme_color_override("font_color", Color("7f8c8d"))

	# Style play button with gradient-like feel
	var play_style := StyleBoxFlat.new()
	play_style.bg_color = Color("27ae60")
	play_style.corner_radius_top_left = 16
	play_style.corner_radius_top_right = 16
	play_style.corner_radius_bottom_left = 16
	play_style.corner_radius_bottom_right = 16
	play_style.border_width_bottom = 4
	play_style.border_color = Color("1e8449")
	play_style.content_margin_left = 24
	play_style.content_margin_right = 24
	play_style.content_margin_top = 12
	play_style.content_margin_bottom = 12
	$PlayButton.add_theme_stylebox_override("normal", play_style)

	var play_hover: StyleBoxFlat = play_style.duplicate() as StyleBoxFlat
	play_hover.bg_color = Color("2ecc71")
	$PlayButton.add_theme_stylebox_override("hover", play_hover)

	var play_pressed: StyleBoxFlat = play_style.duplicate() as StyleBoxFlat
	play_pressed.bg_color = Color("1e8449")
	play_pressed.border_width_bottom = 2
	play_pressed.content_margin_top = 14
	$PlayButton.add_theme_stylebox_override("pressed", play_pressed)
	$PlayButton.add_theme_color_override("font_color", Color.WHITE)

	# Style quit button
	var quit_style := StyleBoxFlat.new()
	quit_style.bg_color = Color("34495e")
	quit_style.corner_radius_top_left = 12
	quit_style.corner_radius_top_right = 12
	quit_style.corner_radius_bottom_left = 12
	quit_style.corner_radius_bottom_right = 12
	quit_style.border_width_bottom = 3
	quit_style.border_color = Color("2c3e50")
	$QuitButton.add_theme_stylebox_override("normal", quit_style)

	var quit_hover: StyleBoxFlat = quit_style.duplicate() as StyleBoxFlat
	quit_hover.bg_color = Color("4a6785")
	$QuitButton.add_theme_stylebox_override("hover", quit_hover)
	$QuitButton.add_theme_color_override("font_color", Color.WHITE)

	# Entrance animation
	$TitleLabel.modulate.a = 0
	$SubtitleLabel.modulate.a = 0
	$PlayButton.modulate.a = 0
	$QuitButton.modulate.a = 0
	$VersionLabel.modulate.a = 0

	var tween := create_tween()
	tween.tween_property($TitleLabel, "modulate:a", 1.0, 0.5).set_delay(0.2)
	tween.tween_property($SubtitleLabel, "modulate:a", 1.0, 0.4)
	tween.tween_property($PlayButton, "modulate:a", 1.0, 0.3)
	tween.tween_property($QuitButton, "modulate:a", 1.0, 0.3)
	tween.tween_property($VersionLabel, "modulate:a", 1.0, 0.2)


func _process(delta: float) -> void:
	# Gentle title float animation
	_title_time += delta
	if $TitleLabel:
		$TitleLabel.position.y = 150 + sin(_title_time * 1.5) * 4.0


func _on_play_pressed() -> void:
	# Transition animation
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	GameManager.go_to_level_select()


func _on_quit_pressed() -> void:
	get_tree().quit()
