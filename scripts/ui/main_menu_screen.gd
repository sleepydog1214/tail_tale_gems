extends Control
## Main menu screen with animated title, Play, Settings, and Quit buttons.
## Phase 3: Daily login reward popup, settings button, version update.
## Phase 4: Player profile display and edit.

var _title_time: float = 0.0
var _daily_popup: Control = null
var _profile_label: Label = null
var _profile_popup: Control = null


func _ready() -> void:
	$PlayButton.pressed.connect(_on_play_pressed)
	$QuitButton.pressed.connect(_on_quit_pressed)

	# Style the title
	$TitleLabel.add_theme_font_size_override("font_size", 40)
	$TitleLabel.add_theme_color_override("font_color", Color("e84393"))
	$TitleLabel.pivot_offset = $TitleLabel.size / 2.0

	$SubtitleLabel.add_theme_font_size_override("font_size", 16)
	$SubtitleLabel.add_theme_color_override("font_color", Color("6b3a5c"))
	$SubtitleLabel.text = "A Purrfect Match-3 Adventure"

	$PlayButton.add_theme_font_size_override("font_size", 26)
	$QuitButton.add_theme_font_size_override("font_size", 18)
	$VersionLabel.add_theme_font_size_override("font_size", 12)
	$VersionLabel.add_theme_color_override("font_color", Color("6b3a5c"))
	$VersionLabel.text = "v0.4.0 — Phase 4"

	# Style play button with gradient-like feel
	var play_style := StyleBoxFlat.new()
	play_style.bg_color = Color("e84393")
	play_style.corner_radius_top_left = 16
	play_style.corner_radius_top_right = 16
	play_style.corner_radius_bottom_left = 16
	play_style.corner_radius_bottom_right = 16
	play_style.border_width_bottom = 4
	play_style.border_color = Color("c0327a")
	play_style.content_margin_left = 24
	play_style.content_margin_right = 24
	play_style.content_margin_top = 12
	play_style.content_margin_bottom = 12
	$PlayButton.add_theme_stylebox_override("normal", play_style)

	var play_hover: StyleBoxFlat = play_style.duplicate() as StyleBoxFlat
	play_hover.bg_color = Color("fd79a8")
	$PlayButton.add_theme_stylebox_override("hover", play_hover)

	var play_pressed: StyleBoxFlat = play_style.duplicate() as StyleBoxFlat
	play_pressed.bg_color = Color("c0327a")
	play_pressed.border_width_bottom = 2
	play_pressed.content_margin_top = 14
	$PlayButton.add_theme_stylebox_override("pressed", play_pressed)
	$PlayButton.add_theme_color_override("font_color", Color.WHITE)

	# Style quit button
	var quit_style := StyleBoxFlat.new()
	quit_style.bg_color = Color("a0628a")
	quit_style.corner_radius_top_left = 12
	quit_style.corner_radius_top_right = 12
	quit_style.corner_radius_bottom_left = 12
	quit_style.corner_radius_bottom_right = 12
	quit_style.border_width_bottom = 3
	quit_style.border_color = Color("8b4f78")
	$QuitButton.add_theme_stylebox_override("normal", quit_style)

	var quit_hover: StyleBoxFlat = quit_style.duplicate() as StyleBoxFlat
	quit_hover.bg_color = Color("b87399")
	$QuitButton.add_theme_stylebox_override("hover", quit_hover)
	$QuitButton.add_theme_color_override("font_color", Color.WHITE)

	# Create settings button
	_create_settings_button()

	# Create profile display
	_create_profile_display()

	# Create stats display
	_create_stats_display()

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

	# Show profile setup on first launch
	if not SaveManager.has_profile():
		tween.tween_callback(_show_profile_popup).set_delay(0.5)


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
	btn.add_theme_color_override("font_color", Color("6b3a5c"))

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.92, 0.82, 0.88, 0.8)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", style)
	var hover: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.95, 0.85, 0.92, 0.9)
	btn.add_theme_stylebox_override("hover", hover)

	btn.pressed.connect(_on_settings_pressed)
	add_child(btn)

	# Fade in with other elements
	btn.modulate.a = 0
	var tw := create_tween()
	tw.tween_property(btn, "modulate:a", 1.0, 0.4).set_delay(1.5)


func _create_profile_display() -> void:
	var container := Button.new()
	container.name = "ProfileButton"
	container.set_anchors_preset(PRESET_TOP_LEFT)
	container.offset_left = 10
	container.offset_top = 10
	container.offset_right = 200
	container.offset_bottom = 55
	container.flat = true

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.92, 0.82, 0.88, 0.8)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	container.add_theme_stylebox_override("normal", style)
	var hover: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.95, 0.85, 0.92, 0.9)
	container.add_theme_stylebox_override("hover", hover)

	_profile_label = Label.new()
	_profile_label.add_theme_font_size_override("font_size", 18)
	_profile_label.add_theme_color_override("font_color", Color("6b3a5c"))
	_profile_label.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	_profile_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_profile_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	container.add_child(_profile_label)
	_update_profile_display()

	container.pressed.connect(_show_profile_popup)
	add_child(container)

	# Fade in
	container.modulate.a = 0
	var tw := create_tween()
	tw.tween_property(container, "modulate:a", 1.0, 0.4).set_delay(1.3)

	SaveManager.profile_updated.connect(_update_profile_display)


func _update_profile_display() -> void:
	if _profile_label == null:
		return
	var avatar := SaveManager.get_profile_avatar()
	var pname := SaveManager.get_profile_name()
	if pname.is_empty():
		_profile_label.text = "%s Tap to set up" % avatar
	else:
		_profile_label.text = "%s %s" % [avatar, pname]


func _show_profile_popup() -> void:
	if _profile_popup != null:
		return
	AudioManager.play_sfx("button_click")
	_profile_popup = ProfilePopup.new()
	_profile_popup.profile_saved.connect(func():
		_profile_popup = null
		_update_profile_display())
	add_child(_profile_popup)


func _create_stats_display() -> void:
	var container := VBoxContainer.new()
	container.name = "StatsPanel"
	container.set_anchors_preset(PRESET_BOTTOM_WIDE)
	container.offset_top = -120
	container.offset_bottom = -45
	container.offset_left = 40
	container.offset_right = -40
	container.add_theme_constant_override("separation", 2)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.92, 0.82, 0.88, 0.6)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 8
	style.content_margin_bottom = 8

	var bg := Panel.new()
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.add_theme_stylebox_override("panel", style)
	container.add_child(bg)

	# Stars progress
	var total_stars: int = SaveManager.get_total_stars()
	var max_stars: int = 50 * 3  # 50 levels x 3 stars each
	var stars_lbl := Label.new()
	stars_lbl.text = "⭐ %d / %d Stars" % [total_stars, max_stars]
	stars_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stars_lbl.add_theme_font_size_override("font_size", 15)
	stars_lbl.add_theme_color_override("font_color", Color("e84393"))
	container.add_child(stars_lbl)

	# Coins
	var coins_lbl := Label.new()
	coins_lbl.text = "🪙 %d Coins" % SaveManager.get_coins()
	coins_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coins_lbl.add_theme_font_size_override("font_size", 14)
	coins_lbl.add_theme_color_override("font_color", Color("6b3a5c"))
	container.add_child(coins_lbl)

	# Levels completed
	var levels_won: int = SaveManager.get_stat("total_wins")
	var levels_label := Label.new()
	levels_label.text = "📊 %d Levels Won" % levels_won
	levels_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	levels_label.add_theme_font_size_override("font_size", 14)
	levels_label.add_theme_color_override("font_color", Color("6b3a5c"))
	container.add_child(levels_label)

	add_child(container)

	# Fade in
	container.modulate.a = 0
	var tw := create_tween()
	tw.tween_property(container, "modulate:a", 1.0, 0.4).set_delay(1.8)


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
	panel_style.bg_color = Color(0.96, 0.88, 0.92, 0.95)
	panel_style.corner_radius_top_left = 20
	panel_style.corner_radius_top_right = 20
	panel_style.corner_radius_bottom_left = 20
	panel_style.corner_radius_bottom_right = 20
	panel_style.border_width_top = 3
	panel_style.border_width_bottom = 3
	panel_style.border_width_left = 3
	panel_style.border_width_right = 3
	panel_style.border_color = Color("e84393")
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
	title.add_theme_color_override("font_color", Color("e84393"))
	vbox.add_child(title)

	var day_label := Label.new()
	day_label.text = "Day %d (Streak: %d)" % [int(reward.get("day", 1)), int(reward.get("streak", 1))]
	day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_label.add_theme_font_size_override("font_size", 16)
	day_label.add_theme_color_override("font_color", Color("6b3a5c"))
	vbox.add_child(day_label)

	var reward_label := Label.new()
	reward_label.text = str(reward.get("label", "Reward"))
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.add_theme_font_size_override("font_size", 22)
	reward_label.add_theme_color_override("font_color", Color("e84393"))
	vbox.add_child(reward_label)

	var ok_btn := Button.new()
	ok_btn.text = "Collect!"
	ok_btn.custom_minimum_size = Vector2(120, 40)
	ok_btn.add_theme_font_size_override("font_size", 20)
	ok_btn.add_theme_color_override("font_color", Color.WHITE)
	var ok_style := StyleBoxFlat.new()
	ok_style.bg_color = Color("e84393")
	ok_style.corner_radius_top_left = 12
	ok_style.corner_radius_top_right = 12
	ok_style.corner_radius_bottom_left = 12
	ok_style.corner_radius_bottom_right = 12
	ok_btn.add_theme_stylebox_override("normal", ok_style)
	var ok_hover: StyleBoxFlat = ok_style.duplicate() as StyleBoxFlat
	ok_hover.bg_color = Color("fd79a8")
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
