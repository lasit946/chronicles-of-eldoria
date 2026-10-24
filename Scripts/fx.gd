extends RefCounted
## Little visual effects used everywhere (floating text, puffs of smoke).
## Use:  const FX := preload("res://Scripts/fx.gd")   then   FX.popup(...)


## Text that floats up and fades, e.g. "+2 HP".
static func popup(parent: Node, pos: Vector2, text: String, color: Color = Color.WHITE) -> void:
	var label := Label.new()
	label.text = text
	label.z_index = 100
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	label.position = pos - Vector2(40, 0)
	label.custom_minimum_size = Vector2(80, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 20.0, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0).set_delay(0.4)
	tween.chain().tween_callback(label.queue_free)


## A quick burst of particles.
static func puff(parent: Node, pos: Vector2, color: Color, amount: int = 14) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.z_index = 50
	p.amount = amount
	p.lifetime = 0.55
	p.one_shot = true
	p.explosiveness = 1.0
	p.direction = Vector2.UP
	p.spread = 180.0
	p.initial_velocity_min = 25.0
	p.initial_velocity_max = 75.0
	p.gravity = Vector2(0, 80)
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	p.color = color
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
