extends "res://Scripts/enemy.gd"
## The Manananggal: wakes up when you get close, fires dark orbs, and at half
## health becomes faster and calls two Aswang to help.

const ORB := preload("res://Scenes/projectile.tscn")
const ASWANG := preload("res://Scenes/aswang.tscn")

var _intro_done := false
var _shoot_cooldown := 1.5
var _summoned := false


func _ready() -> void:
	super._ready()
	add_to_group("boss")
	awake = false


func _think(delta: float) -> Vector2:
	if player == null:
		return Vector2.ZERO
	var to_player := player.global_position - global_position
	var dist := to_player.length()

	if not _intro_done:
		if dist < 190.0:
			_intro_done = true
			awake = true
			Audio.play("boss_roar")
			Audio.set_music_pitch(1.15)
			var level := get_tree().current_scene
			if level.has_method("toast"):
				level.toast("The Manananggal awakens!")
		return Vector2.ZERO

	var phase_two := hp <= max_hp / 2
	if phase_two and not _summoned:
		_summoned = true
		_call_helpers()

	_shoot_cooldown -= delta
	if _shoot_cooldown <= 0.0:
		_shoot_cooldown = 1.5 if phase_two else 2.3
		_fire(to_player.normalized(), 5 if phase_two else 3)

	var move_speed := speed * (1.5 if phase_two else 1.0)
	var desired := to_player.normalized() * (move_speed if dist > 85.0 else -move_speed * 0.5)
	desired += to_player.orthogonal().normalized() * sin(_time * 1.6) * move_speed * 0.7
	return desired


func _fire(dir: Vector2, count: int) -> void:
	Audio.play("shoot")
	for i in count:
		var orb := ORB.instantiate()
		orb.direction = dir.rotated((i - (count - 1) / 2.0) * 0.32)
		orb.position = position + Vector2(0, -12)
		get_parent().add_child(orb)


func _call_helpers() -> void:
	var level := get_tree().current_scene
	for offset in [Vector2(-26, 8), Vector2(26, 8)]:
		var helper := ASWANG.instantiate()
		helper.position = position + offset
		get_parent().add_child(helper)
		if level.has_method("register_enemy"):
			level.register_enemy(helper)
	if level.has_method("toast"):
		level.toast("She calls her servants!")


func _die() -> void:
	Audio.set_music_pitch(1.0)
	_drop("garlic", Vector2(-10, 4))
	_drop("salt", Vector2(10, 4))
	super._die()
