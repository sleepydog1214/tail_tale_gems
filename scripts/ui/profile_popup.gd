class_name ProfilePopup
extends Control
## Popup for creating or editing a player profile (name + avatar).

signal profile_saved

var _name_input: LineEdit
var _avatar_buttons: Array[Button] = []
var _selected_avatar: int = 0
var _panel: PanelContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	z_index = 60

	# Dim overlay
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.6)
	add_child(overlay)

	_build_panel()

	# Load existing profile
	_selected_avatar = SaveManager.get_profile_avatar_index()
	_name_input.text = SaveManager.get_profile_name()
	_highlight_selected_avatar()

	# Animate in
	modulate.a = 0
	_panel.scale = Vector2(0.7, 0.7)
	_panel.pivot_offset = _panel.size / 2.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.3)
	tw.tween_property(_panel, "scale", Vector2.ONE, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _build_panel() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(PRESET_CENTER)
	_panel.offset_left = -200
	_panel.offset_top = -220
	_panel.offset_right = 200
	_panel.offset_bottom = 220
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.96, 0.88, 0.92, 0.98)
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_color = Color("e84393")
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 20
	style.content_margin_bottom = 20
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	_panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "🐱 Your Profile 🐱"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color("e84393"))
	vbox.add_child(title)

	# Name section
	var name_label := Label.new()
	name_label.text = "Name"
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color("6b3a5c"))
	vbox.add_child(name_label)

	_name_input = LineEdit.new()
	_name_input.placeholder_text = "Enter your name..."
	_name_input.max_length = 20
	_name_input.custom_minimum_size = Vector2(0, 40)
	_name_input.add_theme_font_size_override("font_size", 18)
	_name_input.add_theme_color_override("font_color", Color("6b3a5c"))
	_name_input.add_theme_color_override("font_placeholder_color", Color("a0628a"))
	var input_style := StyleBoxFlat.new()
	input_style.bg_color = Color(1, 1, 1, 0.9)
	input_style.corner_radius_top_left = 10
	input_style.corner_radius_top_right = 10
	input_style.corner_radius_bottom_left = 10
	input_style.corner_radius_bottom_right = 10
	input_style.border_width_bottom = 2
	input_style.border_color = Color("fd79a8")
	input_style.content_margin_left = 12
	input_style.content_margin_right = 12
	_name_input.add_theme_stylebox_override("normal", input_style)
	var focus_style: StyleBoxFlat = input_style.duplicate() as StyleBoxFlat
	focus_style.border_width_bottom = 3
	focus_style.border_color = Color("e84393")
	_name_input.add_theme_stylebox_override("focus", focus_style)
	vbox.add_child(_name_input)

	# Avatar section
	var avatar_label := Label.new()
	avatar_label.text = "Choose Avatar"
	avatar_label.add_theme_font_size_override("font_size", 16)
	avatar_label.add_theme_color_override("font_color", Color("6b3a5c"))
	vbox.add_child(avatar_label)

	var avatar_grid := GridContainer.new()
	avatar_grid.columns = 4
	avatar_grid.add_theme_constant_override("h_separation", 8)
	avatar_grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(avatar_grid)

	for i in range(SaveManager.AVATAR_OPTIONS.size()):
		var btn := Button.new()
		btn.text = SaveManager.AVATAR_OPTIONS[i]
		btn.custom_minimum_size = Vector2(70, 60)
		btn.add_theme_font_size_override("font_size", 28)
		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color(0.92, 0.84, 0.89, 0.7)
		btn_style.corner_radius_top_left = 12
		btn_style.corner_radius_top_right = 12
		btn_style.corner_radius_bottom_left = 12
		btn_style.corner_radius_bottom_right = 12
		btn.add_theme_stylebox_override("normal", btn_style)
		var btn_hover: StyleBoxFlat = btn_style.duplicate() as StyleBoxFlat
		btn_hover.bg_color = Color(0.95, 0.85, 0.92, 0.9)
		btn.add_theme_stylebox_override("hover", btn_hover)
		var idx := i
		btn.pressed.connect(func(): _on_avatar_selected(idx))
		avatar_grid.add_child(btn)
		_avatar_buttons.append(btn)

	# Save button
	var save_btn := Button.new()
	save_btn.text = "Save Profile"
	save_btn.custom_minimum_size = Vector2(0, 45)
	save_btn.add_theme_font_size_override("font_size", 20)
	save_btn.add_theme_color_override("font_color", Color.WHITE)
	var save_style := StyleBoxFlat.new()
	save_style.bg_color = Color("e84393")
	save_style.corner_radius_top_left = 14
	save_style.corner_radius_top_right = 14
	save_style.corner_radius_bottom_left = 14
	save_style.corner_radius_bottom_right = 14
	save_style.border_width_bottom = 4
	save_style.border_color = Color("c0327a")
	save_btn.add_theme_stylebox_override("normal", save_style)
	var save_hover: StyleBoxFlat = save_style.duplicate() as StyleBoxFlat
	save_hover.bg_color = Color("fd79a8")
	save_btn.add_theme_stylebox_override("hover", save_hover)
	save_btn.pressed.connect(_on_save_pressed)
	vbox.add_child(save_btn)


func _on_avatar_selected(idx: int) -> void:
	_selected_avatar = idx
	_highlight_selected_avatar()
	AudioManager.play_sfx("button_click")


func _highlight_selected_avatar() -> void:
	for i in range(_avatar_buttons.size()):
		var btn := _avatar_buttons[i]
		var style := StyleBoxFlat.new()
		if i == _selected_avatar:
			style.bg_color = Color("e84393")
			style.border_width_top = 3
			style.border_width_bottom = 3
			style.border_width_left = 3
			style.border_width_right = 3
			style.border_color = Color("c0327a")
		else:
			style.bg_color = Color(0.92, 0.84, 0.89, 0.7)
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		btn.add_theme_stylebox_override("normal", style)


func _on_save_pressed() -> void:
	var player_name := _name_input.text.strip_edges()
	if player_name.is_empty():
		player_name = "Player"
	SaveManager.set_profile_name(player_name)
	SaveManager.set_profile_avatar(_selected_avatar)
	AudioManager.play_sfx("button_click")
	profile_saved.emit()

	# Animate out
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(queue_free)
