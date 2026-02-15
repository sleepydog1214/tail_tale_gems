class_name ParticleEffects
extends Node2D
## Procedural particle effects for board events.
## Phase 3: Gem burst, cascade sparkle, power-up activation, star collection.

const CELL_SIZE := 64.0


static func spawn_gem_burst(parent: Node, board_pos: Vector2, color: Color, count: int = 8) -> void:
	## Burst of particles when a gem is destroyed.
	for i in range(count):
		var p := _create_particle(parent, board_pos, color)
		var angle: float = (float(i) / float(count)) * TAU + randf() * 0.3
		var speed: float = randf_range(60.0, 140.0)
		var vel := Vector2(cos(angle), sin(angle)) * speed
		var lifetime: float = randf_range(0.25, 0.45)
		_animate_particle(parent, p, vel, lifetime)


static func spawn_cascade_sparkle(parent: Node, board_pos: Vector2, cascade_depth: int) -> void:
	## Sparkles that intensify with deeper cascades.
	var count: int = mini(4 + cascade_depth * 2, 16)
	var sparkle_color := Color("f1c40f")  # Gold
	for i in range(count):
		var offset := Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0))
		var p := _create_particle(parent, board_pos + offset, sparkle_color, 3.0)
		var vel := Vector2(randf_range(-30, 30), randf_range(-80, -30))
		var lifetime: float = randf_range(0.3, 0.6)
		_animate_particle(parent, p, vel, lifetime)


static func spawn_powerup_burst(parent: Node, board_pos: Vector2, power_type: GemTypes.PowerUpType) -> void:
	## Dramatic effect when a power-up is created.
	var color: Color
	match power_type:
		GemTypes.PowerUpType.ROCKET_H, GemTypes.PowerUpType.ROCKET_V:
			color = Color("e67e22")
		GemTypes.PowerUpType.BOMB:
			color = Color("e74c3c")
		GemTypes.PowerUpType.PRISM:
			color = Color("f1c40f")
		_:
			color = Color.WHITE

	# Ring burst
	for i in range(12):
		var angle: float = (float(i) / 12.0) * TAU
		var p := _create_particle(parent, board_pos, color, 4.0)
		var vel := Vector2(cos(angle), sin(angle)) * 120.0
		_animate_particle(parent, p, vel, 0.35)

	# Inner glow flash
	var glow := ColorRect.new()
	glow.color = Color(color, 0.6)
	glow.size = Vector2(30, 30)
	glow.position = board_pos - Vector2(15, 15)
	glow.z_index = 90
	parent.add_child(glow)
	var t := parent.create_tween()
	t.tween_property(glow, "scale", Vector2(2.5, 2.5), 0.2).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(glow, "modulate:a", 0.0, 0.25)
	t.tween_callback(glow.queue_free)


static func spawn_rocket_trail(parent: Node, from: Vector2, to: Vector2, color: Color) -> void:
	## Trail effect along a rocket's clear path.
	var dist: float = from.distance_to(to)
	var dir: Vector2 = (to - from).normalized()
	var count: int = int(dist / 16.0)
	for i in range(count):
		var pos: Vector2 = from + dir * float(i) * 16.0
		var p := _create_particle(parent, pos, color, 3.0)
		var perp := Vector2(-dir.y, dir.x) * randf_range(-15.0, 15.0)
		_animate_particle(parent, p, perp, randf_range(0.15, 0.3), float(i) * 0.015)


static func spawn_bomb_explosion(parent: Node, center: Vector2, radius: float = 96.0) -> void:
	## Explosion ring for bomb activation.
	for i in range(20):
		var angle: float = randf() * TAU
		var dist: float = randf_range(0, radius)
		var pos: Vector2 = center + Vector2(cos(angle), sin(angle)) * dist
		var color := Color("e74c3c").lerp(Color("f39c12"), randf())
		var p := _create_particle(parent, pos, color, randf_range(3.0, 6.0))
		var vel := Vector2(cos(angle), sin(angle)) * randf_range(20, 80)
		_animate_particle(parent, p, vel, randf_range(0.2, 0.5))


static func spawn_star_collect(parent: Node, from_pos: Vector2) -> void:
	## Star collection effect — particles fly upward.
	var star_color := Color("f1c40f")
	for i in range(6):
		var offset := Vector2(randf_range(-10, 10), randf_range(-5, 5))
		var p := _create_star_particle(parent, from_pos + offset, star_color)
		var vel := Vector2(randf_range(-20, 20), randf_range(-120, -60))
		_animate_particle(parent, p, vel, randf_range(0.4, 0.7))


# --- Internal helpers ---

static func _create_particle(parent: Node, pos: Vector2, color: Color, size: float = 4.0) -> ColorRect:
	var p := ColorRect.new()
	p.color = color
	p.size = Vector2(size, size)
	p.position = pos - Vector2(size / 2.0, size / 2.0)
	p.z_index = 100
	parent.add_child(p)
	return p


static func _create_star_particle(parent: Node, pos: Vector2, color: Color) -> Label:
	var l := Label.new()
	l.text = "★"
	l.add_theme_font_size_override("font_size", 14)
	l.add_theme_color_override("font_color", color)
	l.position = pos
	l.z_index = 100
	parent.add_child(l)
	return l


static func _animate_particle(parent: Node, node: CanvasItem, velocity: Vector2,
		lifetime: float, delay: float = 0.0) -> void:
	var target_pos: Vector2 = node.position + velocity * lifetime
	var tween := parent.create_tween().set_parallel(true)
	if delay > 0:
		tween.tween_property(node, "position", target_pos, lifetime).set_delay(delay)
		tween.tween_property(node, "modulate:a", 0.0, lifetime * 0.6).set_delay(delay + lifetime * 0.4)
	else:
		tween.tween_property(node, "position", target_pos, lifetime)
		tween.tween_property(node, "modulate:a", 0.0, lifetime * 0.6).set_delay(lifetime * 0.4)
	tween.chain().tween_callback(node.queue_free)
