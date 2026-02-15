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

# Animation state
var is_animating: bool = false


func _ready() -> void:
	pass


func _process(delta: float) -> void:
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
	draw_colored_polygon(points, color)
	# Highlight
	var highlight := PackedVector2Array([
		Vector2(0, -radius),
		Vector2(radius * 0.3, -radius * 0.3),
		Vector2(0, 0),
		Vector2(-radius * 0.3, -radius * 0.3),
	])
	draw_colored_polygon(highlight, Color(color, 1.0).lightened(0.3))
	# Outline
	draw_polyline(points + PackedVector2Array([points[0]]), color.darkened(0.3), 2.0)


func _draw_circle_gem(color: Color, radius: float) -> void:
	draw_circle(Vector2.ZERO, radius, color)
	# Inner highlight
	draw_circle(Vector2(-radius * 0.2, -radius * 0.2), radius * 0.5, color.lightened(0.25))
	# Outline
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, color.darkened(0.3), 2.0)


func _draw_hexagon(color: Color, radius: float) -> void:
	var points := PackedVector2Array()
	for i in range(6):
		var angle := i * TAU / 6 - PI / 6
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, color)
	# Highlight
	var highlight := PackedVector2Array()
	for i in range(3):
		var angle := i * TAU / 6 - PI / 6
		highlight.append(Vector2(cos(angle), sin(angle)) * radius * 0.7)
	highlight.append(Vector2.ZERO)
	draw_colored_polygon(highlight, color.lightened(0.2))
	# Outline
	draw_polyline(points + PackedVector2Array([points[0]]), color.darkened(0.3), 2.0)


func _draw_square_gem(color: Color, radius: float) -> void:
	var half := radius * 0.85
	var rect := Rect2(-half, -half, half * 2, half * 2)
	draw_rect(rect, color)
	# Highlight
	var hl_rect := Rect2(-half, -half, half, half)
	draw_rect(hl_rect, color.lightened(0.2))
	# Outline
	draw_rect(rect, color.darkened(0.3), false, 2.0)


func _draw_triangle(color: Color, radius: float) -> void:
	var points := PackedVector2Array([
		Vector2(0, -radius),
		Vector2(radius * 0.87, radius * 0.5),
		Vector2(-radius * 0.87, radius * 0.5),
	])
	draw_colored_polygon(points, color)
	# Highlight
	var highlight := PackedVector2Array([
		Vector2(0, -radius),
		Vector2(radius * 0.3, -radius * 0.1),
		Vector2(-radius * 0.3, -radius * 0.1),
	])
	draw_colored_polygon(highlight, color.lightened(0.3))
	# Outline
	draw_polyline(points + PackedVector2Array([points[0]]), color.darkened(0.3), 2.0)


func _draw_star(color: Color, radius: float) -> void:
	var points := PackedVector2Array()
	for i in range(10):
		var angle := i * TAU / 10 - PI / 2
		var r := radius if i % 2 == 0 else radius * 0.5
		points.append(Vector2(cos(angle), sin(angle)) * r)
	draw_colored_polygon(points, color)
	draw_polyline(points + PackedVector2Array([points[0]]), color.darkened(0.3), 2.0)


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
