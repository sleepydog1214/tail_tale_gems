class_name GemRenderer
extends Node2D
## Visual representation of a single gem on the board.
## Draws itself using Godot's drawing primitives (no external sprites needed).

const GEM_SIZE := 56.0
const GEM_MARGIN := 4.0
const CELL_SIZE := 64.0

var gem_color: GemTypes.GemColor = GemTypes.GemColor.NONE
var power_up: GemTypes.PowerUpType = GemTypes.PowerUpType.NONE
var board_row: int = 0
var board_col: int = 0
var is_selected: bool = false
var is_hinted: bool = false
var _hint_pulse_time: float = 0.0
var _selected_pulse_time: float = 0.0
var _sparkle_time: float = 0.0

# Animation state
var is_animating: bool = false


func _ready() -> void:
	# Offset sparkle phase randomly for each gem so they don't all pulse in sync
	_sparkle_time = randf() * TAU


func _process(delta: float) -> void:
	_sparkle_time += delta * 1.5
	if is_hinted:
		_hint_pulse_time += delta * 3.0
		queue_redraw()
	elif _hint_pulse_time > 0.0:
		_hint_pulse_time = 0.0
		queue_redraw()

	if is_selected:
		_selected_pulse_time += delta * 4.0
		queue_redraw()
	elif _selected_pulse_time > 0.0:
		_selected_pulse_time = 0.0

	# Subtle idle sparkle redraw (every ~6 frames to save perf)
	if Engine.get_process_frames() % 6 == 0:
		queue_redraw()


func set_selected(val: bool) -> void:
	is_selected = val
	_selected_pulse_time = 0.0
	queue_redraw()


func setup(color: GemTypes.GemColor, pup: GemTypes.PowerUpType, row: int, col: int) -> void:
	gem_color = color
	power_up = pup
	board_row = row
	board_col = col
	position = get_board_position(row, col)
	queue_redraw()


func update_visual(color: GemTypes.GemColor, pup: GemTypes.PowerUpType) -> void:
	gem_color = color
	power_up = pup
	queue_redraw()


static func get_board_position(row: int, col: int) -> Vector2:
	return Vector2(col * CELL_SIZE + CELL_SIZE / 2.0, row * CELL_SIZE + CELL_SIZE / 2.0)


func _draw() -> void:
	if gem_color == GemTypes.GemColor.NONE:
		return

	var base_color: Color = GemTypes.COLOR_HEX.get(gem_color, Color.WHITE)
	var radius := GEM_SIZE / 2.0

	# Soft outer glow for depth (always visible)
	var glow_c := Color(base_color, 0.25)
	draw_circle(Vector2(0, 1), radius + 4, glow_c)

	# Selection pulsing highlight
	if is_selected:
		var pulse := (sin(_selected_pulse_time) + 1.0) / 2.0
		var sel_alpha := 0.6 + pulse * 0.4
		draw_circle(Vector2.ZERO, radius + 5, Color(1, 1, 1, sel_alpha))

	# Hint pulse glow
	if is_hinted:
		var pulse := (sin(_hint_pulse_time) + 1.0) / 2.0
		var glow_color := Color(1, 1, 0.5, 0.3 + pulse * 0.4)
		draw_circle(Vector2.ZERO, radius + 6, glow_color)

	# Draw the gem shape based on color (different shapes for accessibility)
	match gem_color:
		GemTypes.GemColor.RUBY:
			_draw_diamond(base_color, radius)
		GemTypes.GemColor.SAPPHIRE:
			_draw_circle_gem(base_color, radius)
		GemTypes.GemColor.EMERALD:
			_draw_hexagon(base_color, radius)
		GemTypes.GemColor.TOPAZ:
			_draw_square_gem(base_color, radius)
		GemTypes.GemColor.AMETHYST:
			_draw_triangle(base_color, radius)
		GemTypes.GemColor.DIAMOND:
			_draw_star(base_color, radius)

	# Animated sparkle dot
	_draw_sparkle(radius)

	# Draw power-up overlay
	if power_up != GemTypes.PowerUpType.NONE:
		_draw_power_up_overlay()


func _draw_diamond(color: Color, radius: float) -> void:
	var points := PackedVector2Array([
		Vector2(0, -radius),
		Vector2(radius, 0),
		Vector2(0, radius),
		Vector2(-radius, 0),
	])
	# Shadow layer
	var shadow := PackedVector2Array()
	for p in points:
		shadow.append(p + Vector2(1, 2))
	draw_colored_polygon(shadow, color.darkened(0.4))
	# Base shape
	draw_colored_polygon(points, color)
	# Large top highlight
	var highlight := PackedVector2Array([
		Vector2(0, -radius),
		Vector2(radius * 0.4, -radius * 0.3),
		Vector2(0, -radius * 0.05),
		Vector2(-radius * 0.4, -radius * 0.3),
	])
	draw_colored_polygon(highlight, color.lightened(0.35))
	# Small bright accent
	var accent := PackedVector2Array([
		Vector2(0, -radius * 0.85),
		Vector2(radius * 0.15, -radius * 0.55),
		Vector2(-radius * 0.15, -radius * 0.55),
	])
	draw_colored_polygon(accent, color.lightened(0.55))
	# Outline
	draw_polyline(points + PackedVector2Array([points[0]]), color.darkened(0.3), 2.0)


func _draw_circle_gem(color: Color, radius: float) -> void:
	# Shadow
	draw_circle(Vector2(1, 2), radius, color.darkened(0.35))
	# Base
	draw_circle(Vector2.ZERO, radius, color)
	# Large inner highlight (upper-left)
	draw_circle(Vector2(-radius * 0.2, -radius * 0.2), radius * 0.55, color.lightened(0.25))
	# Bright crescent
	draw_circle(Vector2(-radius * 0.25, -radius * 0.3), radius * 0.3, color.lightened(0.45))
	# Outline
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, color.darkened(0.3), 2.0)


func _draw_hexagon(color: Color, radius: float) -> void:
	var points := PackedVector2Array()
	for i in range(6):
		var angle := i * TAU / 6 - PI / 6
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	# Shadow
	var shadow := PackedVector2Array()
	for p in points:
		shadow.append(p + Vector2(1, 2))
	draw_colored_polygon(shadow, color.darkened(0.35))
	# Base
	draw_colored_polygon(points, color)
	# Upper highlight (top 3 verts scaled down)
	var highlight := PackedVector2Array()
	for i in range(3):
		var angle := i * TAU / 6 - PI / 6
		highlight.append(Vector2(cos(angle), sin(angle)) * radius * 0.7)
	highlight.append(Vector2.ZERO)
	draw_colored_polygon(highlight, color.lightened(0.25))
	# Bright center dot
	draw_circle(Vector2(-radius * 0.15, -radius * 0.2), radius * 0.22, color.lightened(0.5))
	# Outline
	draw_polyline(points + PackedVector2Array([points[0]]), color.darkened(0.3), 2.0)


func _draw_square_gem(color: Color, radius: float) -> void:
	var half := radius * 0.85
	var rect := Rect2(-half, -half, half * 2, half * 2)
	# Shadow
	draw_rect(Rect2(-half + 1, -half + 2, half * 2, half * 2), color.darkened(0.35))
	# Base
	draw_rect(rect, color)
	# Upper-left highlight quadrant
	var hl_rect := Rect2(-half, -half, half, half)
	draw_rect(hl_rect, color.lightened(0.2))
	# Bright top-left corner accent
	draw_rect(Rect2(-half + 3, -half + 3, half * 0.4, half * 0.4), color.lightened(0.45))
	# Outline
	draw_rect(rect, color.darkened(0.3), false, 2.0)


func _draw_triangle(color: Color, radius: float) -> void:
	var points := PackedVector2Array([
		Vector2(0, -radius),
		Vector2(radius * 0.87, radius * 0.5),
		Vector2(-radius * 0.87, radius * 0.5),
	])
	# Shadow
	var shadow := PackedVector2Array()
	for p in points:
		shadow.append(p + Vector2(1, 2))
	draw_colored_polygon(shadow, color.darkened(0.35))
	# Base
	draw_colored_polygon(points, color)
	# Upper highlight
	var highlight := PackedVector2Array([
		Vector2(0, -radius),
		Vector2(radius * 0.35, -radius * 0.05),
		Vector2(-radius * 0.35, -radius * 0.05),
	])
	draw_colored_polygon(highlight, color.lightened(0.3))
	# Bright tip accent
	var accent := PackedVector2Array([
		Vector2(0, -radius * 0.9),
		Vector2(radius * 0.12, -radius * 0.5),
		Vector2(-radius * 0.12, -radius * 0.5),
	])
	draw_colored_polygon(accent, color.lightened(0.55))
	# Outline
	draw_polyline(points + PackedVector2Array([points[0]]), color.darkened(0.3), 2.0)


func _draw_star(color: Color, radius: float) -> void:
	var points := PackedVector2Array()
	for i in range(10):
		var angle := i * TAU / 10 - PI / 2
		var r := radius if i % 2 == 0 else radius * 0.5
		points.append(Vector2(cos(angle), sin(angle)) * r)
	# Shadow
	var shadow := PackedVector2Array()
	for p in points:
		shadow.append(p + Vector2(1, 2))
	draw_colored_polygon(shadow, color.darkened(0.35))
	# Base
	draw_colored_polygon(points, color)
	# Inner star highlight
	var inner := PackedVector2Array()
	for i in range(10):
		var angle := i * TAU / 10 - PI / 2
		var r := radius * 0.55 if i % 2 == 0 else radius * 0.3
		inner.append(Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(inner, color.lightened(0.3))
	# Center bright dot
	draw_circle(Vector2.ZERO, radius * 0.18, color.lightened(0.55))
	# Outline
	draw_polyline(points + PackedVector2Array([points[0]]), color.darkened(0.3), 2.0)


func _draw_sparkle(radius: float) -> void:
	# Animated white sparkle that orbits inside the gem
	var sparkle_alpha := (sin(_sparkle_time * 2.0) + 1.0) / 2.0 * 0.7 + 0.1
	var sx := cos(_sparkle_time * 0.7) * radius * 0.25 - radius * 0.15
	var sy := sin(_sparkle_time * 0.5) * radius * 0.25 - radius * 0.2
	var sparkle_pos := Vector2(sx, sy)
	# 4-point star sparkle
	var sparkle_size := 3.0 + sparkle_alpha * 2.0
	var sparkle_color := Color(1, 1, 1, sparkle_alpha)
	draw_line(sparkle_pos + Vector2(-sparkle_size, 0), sparkle_pos + Vector2(sparkle_size, 0), sparkle_color, 1.5)
	draw_line(sparkle_pos + Vector2(0, -sparkle_size), sparkle_pos + Vector2(0, sparkle_size), sparkle_color, 1.5)


func _draw_power_up_overlay() -> void:
	var symbol_color := Color.WHITE
	match power_up:
		GemTypes.PowerUpType.ROCKET_H:
			# Horizontal arrow
			draw_line(Vector2(-16, 0), Vector2(16, 0), symbol_color, 3.0)
			draw_line(Vector2(10, -6), Vector2(16, 0), symbol_color, 3.0)
			draw_line(Vector2(10, 6), Vector2(16, 0), symbol_color, 3.0)
			draw_line(Vector2(-10, -6), Vector2(-16, 0), symbol_color, 3.0)
			draw_line(Vector2(-10, 6), Vector2(-16, 0), symbol_color, 3.0)
		GemTypes.PowerUpType.ROCKET_V:
			# Vertical arrow
			draw_line(Vector2(0, -16), Vector2(0, 16), symbol_color, 3.0)
			draw_line(Vector2(-6, -10), Vector2(0, -16), symbol_color, 3.0)
			draw_line(Vector2(6, -10), Vector2(0, -16), symbol_color, 3.0)
			draw_line(Vector2(-6, 10), Vector2(0, 16), symbol_color, 3.0)
			draw_line(Vector2(6, 10), Vector2(0, 16), symbol_color, 3.0)
		GemTypes.PowerUpType.BOMB:
			# Explosion star
			for i in range(8):
				var angle := i * TAU / 8
				var inner := Vector2(cos(angle), sin(angle)) * 6
				var outer := Vector2(cos(angle), sin(angle)) * 16
				draw_line(inner, outer, symbol_color, 2.5)
		GemTypes.PowerUpType.PRISM:
			# Rainbow circle
			draw_arc(Vector2.ZERO, 14, 0, TAU, 16, Color.WHITE, 3.0)
			draw_arc(Vector2.ZERO, 10, 0, TAU, 16, Color.GOLD, 2.0)
