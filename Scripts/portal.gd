extends Area2D
## The exit portal. Red and locked until every monster is defeated, then green.

var is_open := false
var remaining := 0   # monsters left, shown in the hint

var _hint: Label
var _time := 0.0
var _fired := false
var _was_touching := false


func _ready() -> void:
	z_index = 5
	collision_layer = 0
	collision_mask = 2   # player

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 14.0
	shape.shape = circle
	add_child(shape)

	_hint = Label.new()
	_hint.visible = false
	_hint.custom_minimum_size = Vector2(160, 0)
	_hint.position = Vector2(-80, -34)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 10)
	_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	_hint.add_theme_constant_override("outline_size", 4)
	add_child(_hint)


func open() -> void:
	if is_open:
		return
	is_open = true
	Audio.play("portal_open")


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if _fired:
		return
	var touching := false
	for body in get_overlapping_bodies():
		if body.is_in_group("player"):
			touching = true
			break
	_hint.text = "Defeat all monsters first!  (%d left)" % remaining
	_hint.visible = touching and not is_open
	if touching and is_open:
		_fired = true
		Game.level_complete()
	elif touching and not _was_touching:
		Audio.play("locked")
	_was_touching = touching


func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_time * 4.0)
	var col := Color(0.35, 1.0, 0.55) if is_open else Color(0.9, 0.25, 0.2)
	var a := (0.5 + 0.4 * pulse) if is_open else 0.4
	draw_circle(Vector2(0, -4), 12.0 + 2.5 * pulse, Color(col, a * 0.45))
	draw_arc(Vector2(0, -4), 12.0, 0.0, TAU, 32, Color(col, minf(a + 0.3, 1.0)), 2.0)
	draw_arc(Vector2(0, -4), 7.0, _time * 2.0, _time * 2.0 + PI * 1.5, 24, Color(1, 1, 1, minf(a + 0.2, 1.0)), 1.5)
	draw_arc(Vector2(0, -4), 3.0, -_time * 3.0, -_time * 3.0 + PI, 12, Color(1, 1, 1, 0.8), 1.0)
