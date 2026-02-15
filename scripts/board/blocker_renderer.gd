class_name BlockerRenderer
extends Node2D
## Visual representation of a blocker on the board.
## Draws itself using Godot's drawing primitives.

var blocker_type: GemTypes.BlockerType = GemTypes.BlockerType.NONE
var blocker_hp: int = 1
var board_row: int = 0
var board_col: int = 0

const CELL_SIZE := 64.0


func setup(type: GemTypes.BlockerType, hp: int, row: int, col: int) -> void:
	blocker_type = type
	blocker_hp = hp
	board_row = row
	board_col = col
	position = Vector2(col * CELL_SIZE + CELL_SIZE / 2.0, row * CELL_SIZE + CELL_SIZE / 2.0)
	queue_redraw()


func update_hp(new_hp: int) -> void:
	blocker_hp = new_hp
	queue_redraw()


func _draw() -> void:
	match blocker_type:
		GemTypes.BlockerType.CRATE:
			_draw_crate()
		GemTypes.BlockerType.REINFORCED_CRATE:
			_draw_reinforced_crate()
		GemTypes.BlockerType.ICE:
			_draw_ice()
		GemTypes.BlockerType.CHAIN:
			_draw_chain()
		GemTypes.BlockerType.VASE:
			_draw_vase()
		GemTypes.BlockerType.STONE:
			_draw_stone()


func _draw_crate() -> void:
	var half := 28.0
	var rect := Rect2(-half, -half, half * 2, half * 2)
	draw_rect(rect, Color("8B4513"))
	# Wood grain lines
	draw_line(Vector2(-half, -10), Vector2(half, -10), Color("6B3410"), 1.5)
	draw_line(Vector2(-half, 10), Vector2(half, 10), Color("6B3410"), 1.5)
	# Cross
	draw_line(Vector2(-half, -half), Vector2(half, half), Color("A0522D"), 2.0)
	draw_line(Vector2(half, -half), Vector2(-half, half), Color("A0522D"), 2.0)
	# Outline
	draw_rect(rect, Color("5B2C06"), false, 2.0)


func _draw_reinforced_crate() -> void:
	_draw_crate()
	# Metal bands based on HP
	var band_color := Color("888888")
	if blocker_hp >= 2:
		draw_line(Vector2(-28, 0), Vector2(28, 0), band_color, 4.0)
	if blocker_hp >= 3:
		draw_line(Vector2(0, -28), Vector2(0, 28), band_color, 4.0)


func _draw_ice() -> void:
	var alpha := 0.2 + blocker_hp * 0.2  # More opaque with more layers
	var color := Color(0.7, 0.85, 1.0, alpha)
	var half := 28.0
	var rect := Rect2(-half, -half, half * 2, half * 2)
	draw_rect(rect, color)
	# Ice crack pattern
	var crack_color := Color(1, 1, 1, alpha * 0.5)
	draw_line(Vector2(-10, -20), Vector2(5, 0), crack_color, 1.5)
	draw_line(Vector2(5, 0), Vector2(-5, 15), crack_color, 1.5)
	# Outline
	draw_rect(rect, Color(0.6, 0.75, 0.9, alpha), false, 2.0)
	# HP indicator
	if blocker_hp > 1:
		_draw_hp_dots(blocker_hp, Color(0.5, 0.7, 1.0))


func _draw_chain() -> void:
	# Draw chain links around the cell
	var chain_color := Color("888888")
	var link_size := 8.0
	for i in range(4):
		var angle := i * TAU / 4
		var pos := Vector2(cos(angle), sin(angle)) * 22
		draw_circle(pos, link_size, Color("666666"))
		draw_circle(pos, link_size - 2, chain_color)
	# Connecting lines
	draw_arc(Vector2.ZERO, 22, 0, TAU, 16, chain_color, 3.0)


func _draw_vase() -> void:
	var color := Color("C19A6B")
	# Vase body
	var points := PackedVector2Array([
		Vector2(-12, -24),
		Vector2(12, -24),
		Vector2(18, -8),
		Vector2(16, 20),
		Vector2(-16, 20),
		Vector2(-18, -8),
	])
	draw_colored_polygon(points, color)
	# Rim
	draw_line(Vector2(-14, -24), Vector2(14, -24), color.lightened(0.2), 4.0)
	# Outline
	draw_polyline(points + PackedVector2Array([points[0]]), color.darkened(0.3), 2.0)
	if blocker_hp > 1:
		_draw_hp_dots(blocker_hp, Color("A0784B"))


func _draw_stone() -> void:
	var color := Color("666666")
	var half := 28.0
	var rect := Rect2(-half, -half, half * 2, half * 2)
	draw_rect(rect, color)
	# Rough texture
	draw_line(Vector2(-20, -15), Vector2(-5, -18), Color("555555"), 2.0)
	draw_line(Vector2(5, 10), Vector2(20, 8), Color("555555"), 2.0)
	draw_rect(rect, Color("444444"), false, 3.0)


func _draw_hp_dots(hp: int, color: Color) -> void:
	for i in range(hp):
		var x := -6 + i * 6
		draw_circle(Vector2(x, 24), 3, color)
