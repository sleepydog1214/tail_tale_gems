extends Control
## Main menu screen with animated title, Play, Settings, and Quit buttons.
## Phase 3: Daily login reward popup, settings button, version update.

var _title_time: float = 0.0
var _daily_popup: Control = null


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
	$VersionLabel.text = "v0.3.0 — Phase 3"

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

	# Create settings button
	_create_settings_button()

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

	# Check daily login reward after entrance animation
	tween.tween_callback(_check_daily_login).set_delay(0.3)


func _create_settings_button() -> void:
	var btn := Button.new()
	btn.name = "SettingsButton"
	btn.text = "⚙ Settings"
	btn.set_anchors_preset(PRESET_TOP_RIGHT)
	btn.offset_left = -130
	btn.offset_top = 10
	btn.offset_right = -10
	btn.offset_bottom = 45
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color("bdc3c7"))

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.18, 0.28, 0.8)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", style)
	var hover: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.22, 0.26, 0.40, 0.9)
	btn.add_theme_stylebox_override("hover", hover)

	btn.pressed.connect(_on_settings_pressed)
	add_child(btn)

	# Fade in with other elements
	btn.modulate.a = 0
	var tw := create_tween()
	tw.tween_property(btn, "modulate:a", 1.0, 0.4).set_delay(1.5)


func _check_daily_login() -> void:
	var reward: Dictionary = SaveManager.record_daily_login()
	if reward.is_empty():
		return  # Already claimed today
	_show_daily_popup(reward)


func _show_daily_popup(reward: Dictionary) -> void:
	AudioManager.play_sfx("daily_reward")

	_daily_popup = Control.new()
	_daily_popup.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_daily_popup.z_index = 50
	add_child(_daily_popup)

	# Dim overlay
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.6)
	_daily_popup.add_child(overlay)

	# Panel
	var panel := PanelContainer.new()
	panel.set_anchors_preset(PRESET_CENTER)
	panel.offset_left = -160
	panel.offset_top = -130
	panel.offset_right = 160
	panel.offset_bottom = 130
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.12, 0.22, 0.95)
	panel_style.corner_radius_top_left = 20
	panel_style.corner_radius_top_right = 20
	panel_style.corner_radius_bottom_left = 20
	panel_style.corner_radius_bottom_right = 20
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_color = Color("f39c12")
	panel.add_theme_stylebox_override("panel", panel_style)
	_daily_popup.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Daily Login Reward!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("f39c12"))
	vbox.add_child(title)

	var day_label := Label.new()
	day_label.text = "Day %d (Streak: %d)" % [int(reward.get("day", 1)), int(reward.get("streak", 1))]
	day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_label.add_theme_font_size_override("font_size", 16)
	day_label.add_theme_color_override("font_color", Color("bdc3c7"))
	vbox.add_child(day_label)

	var reward_label := Label.new()
	reward_label.text = str(reward.get("label", "Reward"))
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.add_theme_font_size_override("font_size", 22)
	reward_label.add_theme_color_override("font_color", Color("f1c40f"))
	vbox.add_child(reward_label)

	var ok_btn := Button.new()
	ok_btn.text = "Collect!"
	ok_btn.custom_minimum_size = Vector2(120, 40)
	ok_btn.add_theme_font_size_override("font_size", 20)
	ok_btn.add_theme_color_override("font_color", Color.WHITE)
	var ok_style := StyleBoxFlat.new()
	ok_style.bg_color = Color("27ae60")
	ok_style.corner_radius_top_left = 12
	ok_style.corner_radius_top_right = 12
	ok_style.corner_radius_bottom_left = 12
	ok_style.corner_radius_bottom_right = 12
	ok_btn.add_theme_stylebox_override("normal", ok_style)
	var ok_hover: StyleBoxFlat = ok_style.duplicate() as StyleBoxFlat
	ok_hover.bg_color = Color("2ecc71")
	ok_btn.add_theme_stylebox_override("hover", ok_hover)
	ok_btn.pressed.connect(func():
		AudioManager.play_sfx("button_click")
		_daily_popup.queue_free()
		_daily_popup = null)
	vbox.add_child(ok_btn)

	# Animate popup in
	_daily_popup.modulate.a = 0
	panel.scale = Vector2(0.7, 0.7)
	panel.pivot_offset = panel.size / 2.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_daily_popup, "modulate:a", 1.0, 0.3)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _process(delta: float) -> void:
	# Gentle title float animation
	_title_time += delta
	if $TitleLabel:
		$TitleLabel.position.y = 150 + sin(_title_time * 1.5) * 4.0


func _on_play_pressed() -> void:
	AudioManager.play_sfx("button_click")
	# Transition animation
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	GameManager.go_to_level_select()


func _on_settings_pressed() -> void:
	AudioManager.play_sfx("button_click")
	GameManager.go_to_settings()


func _on_quit_pressed() -> void:
	get_tree().quit()
