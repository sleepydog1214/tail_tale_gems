extends Control
## Settings screen — volume, accessibility, and preferences.
## Phase 3 implementation.


func _ready() -> void:
	# Load current settings
	var settings: Dictionary = SaveManager.get_settings()

	# Build the UI programmatically
	_build_ui(settings)


func _build_ui(settings: Dictionary) -> void:
	# Background
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.color = Color(0.96, 0.88, 0.92, 1.0)
	add_child(bg)

	# Title
	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(PRESET_TOP_WIDE)
	title.offset_top = 40
	title.offset_bottom = 80
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color("e84393"))
	add_child(title)

	# Scroll container for settings
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(PRESET_FULL_RECT)
	scroll.offset_top = 100
	scroll.offset_bottom = -80
	scroll.offset_left = 40
	scroll.offset_right = -40
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.custom_minimum_size.x = 400
	vbox.add_theme_constant_override("separation", 20)
	scroll.add_child(vbox)

	# --- Audio Section ---
	_add_section_label(vbox, "Audio")

	_add_slider(vbox, "Master Volume", float(settings.get("master_volume", 1.0)),
		func(val: float) -> void:
			AudioManager.set_master_volume(val)
			SaveManager.set_setting("master_volume", val))

	_add_slider(vbox, "Music Volume", float(settings.get("music_volume", 0.8)),
		func(val: float) -> void:
			AudioManager.set_music_volume(val)
			SaveManager.set_setting("music_volume", val))

	_add_slider(vbox, "SFX Volume", float(settings.get("sfx_volume", 1.0)),
		func(val: float) -> void:
			AudioManager.set_sfx_volume(val)
			SaveManager.set_setting("sfx_volume", val))

	# --- Accessibility Section ---
	_add_section_label(vbox, "Accessibility")

	_add_toggle(vbox, "Reduced Motion", bool(settings.get("reduced_motion", false)),
		func(enabled: bool) -> void:
			SaveManager.set_setting("reduced_motion", enabled))

	# --- Back button ---
	var back_btn := Button.new()
	back_btn.name = "BackButton"
	back_btn.text = "Back"
	back_btn.set_anchors_preset(PRESET_BOTTOM_WIDE)
	back_btn.offset_top = -60
	back_btn.offset_left = 40
	back_btn.offset_right = -40
	add_child(back_btn)

	var back_style := StyleBoxFlat.new()
	back_style.bg_color = Color("a0628a")
	back_style.corner_radius_top_left = 12
	back_style.corner_radius_top_right = 12
	back_style.corner_radius_bottom_left = 12
	back_style.corner_radius_bottom_right = 12
	back_btn.add_theme_stylebox_override("normal", back_style)
	var back_hover: StyleBoxFlat = back_style.duplicate() as StyleBoxFlat
	back_hover.bg_color = Color("b87399")
	back_btn.add_theme_stylebox_override("hover", back_hover)
	back_btn.add_theme_color_override("font_color", Color.WHITE)
	back_btn.add_theme_font_size_override("font_size", 20)
	back_btn.pressed.connect(_on_back)


func _add_section_label(parent: Control, text: String) -> void:
	var sep := HSeparator.new()
	parent.add_child(sep)
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color("e84393"))
	parent.add_child(label)


func _add_slider(parent: Control, label_text: String, initial_value: float,
		on_change: Callable) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 150
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color("6b3a5c"))
	hbox.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = initial_value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size.x = 200
	slider.custom_minimum_size.y = 30
	hbox.add_child(slider)

	var value_label := Label.new()
	value_label.text = "%d%%" % int(initial_value * 100)
	value_label.custom_minimum_size.x = 50
	value_label.add_theme_font_size_override("font_size", 14)
	value_label.add_theme_color_override("font_color", Color("a0628a"))
	hbox.add_child(value_label)

	slider.value_changed.connect(func(val: float) -> void:
		value_label.text = "%d%%" % int(val * 100)
		on_change.call(val))

	parent.add_child(hbox)


func _add_toggle(parent: Control, label_text: String, initial_value: bool,
		on_change: Callable) -> void:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 200
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color("6b3a5c"))
	hbox.add_child(label)

	var toggle := CheckButton.new()
	toggle.button_pressed = initial_value
	hbox.add_child(toggle)

	toggle.toggled.connect(func(pressed: bool) -> void:
		on_change.call(pressed))

	parent.add_child(hbox)


func _on_back() -> void:
	AudioManager.play_sfx("button_click")
	GameManager.go_to_main_menu()
