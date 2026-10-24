extends CharacterBody2D
## The hero. Move with WASD / arrow keys, attack with Space / J / Z / left click.

signal health_changed(current: int, maximum: int)
signal died

const FX := preload("res://Scripts/fx.gd")

@export var speed := 88.0
@export var max_health := 6
@export var attack_cooldown := 0.34
@export var base_damage := 1
@export var attack_reach := 15.0
@export var attack_radius := 17.0

var health := 6
var facing := Vector2.DOWN

var _cooldown := 0.0
var _invulnerable := 0.0
var _knock := Vector2.ZERO
var _dead := false
var _time := 0.0
var _step_timer := 0.0

@onready var sprite: Sprite2D = $Sprite
@onready var slash: Sprite2D = $Slash
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2   # player
	collision_mask = 1    # world
	health = max_health
	slash.visible = false
	health_changed.emit.call_deferred(health, max_health)


func damage_now() -> int:
	return base_damage + Game.salt_bonus


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_time += delta
	_cooldown = maxf(0.0, _cooldown - delta)
	_invulnerable = maxf(0.0, _invulnerable - delta)

	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir != Vector2.ZERO:
		facing = dir.normalized()
	velocity = dir * speed + _knock
	_knock = _knock.move_toward(Vector2.ZERO, 700.0 * delta)
	move_and_slide()

	if dir != Vector2.ZERO:
		sprite.offset.y = -absf(sin(_time * 14.0)) * 1.6
		_step_timer -= delta
		if _step_timer <= 0.0:
			_step_timer = 0.3
			Audio.play("step", 1.0, 0.15)
	else:
		sprite.offset.y = 0.0
		_step_timer = 0.0
	if dir.x != 0.0:
		sprite.flip_h = dir.x < 0.0
	# blink while invulnerable
	sprite.visible = _invulnerable <= 0.0 or fmod(_invulnerable, 0.16) > 0.08

	if Input.is_action_pressed("attack") and _cooldown <= 0.0:
		_attack()


func _attack() -> void:
	_cooldown = attack_cooldown
	Audio.play("swing", 1.0, 0.1)

	var shape := CircleShape2D.new()
	shape.radius = attack_radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, global_position + Vector2(0, -6) + facing * attack_reach)
	query.collision_mask = 4   # enemies
	query.collide_with_bodies = true
	var hit := false
	for result in get_world_2d().direct_space_state.intersect_shape(query, 16):
		var target = result.collider
		if target != null and target.has_method("take_damage"):
			target.take_damage(damage_now(), global_position)
			hit = true
	if hit:
		Audio.play("hit", 1.0, 0.1)

	# slash picture
	slash.position = Vector2(0, -6) + facing * (attack_reach + 1.0)
	slash.rotation = facing.angle()
	slash.modulate.a = 1.0
	slash.visible = true
	var tween := create_tween()
	tween.tween_property(slash, "modulate:a", 0.0, 0.16)
	tween.tween_callback(slash.hide)


func take_damage(amount: int, from_pos: Vector2) -> void:
	if _dead or _invulnerable > 0.0:
		return
	health = maxi(0, health - amount)
	_invulnerable = 1.0
	_knock = (global_position - from_pos).normalized() * 170.0
	Audio.play("hurt")
	health_changed.emit(health, max_health)
	if health <= 0:
		_die()


func heal(amount: int) -> void:
	health = mini(max_health, health + amount)
	health_changed.emit(health, max_health)


func _die() -> void:
	_dead = true
	velocity = Vector2.ZERO
	sprite.visible = true
	sprite.modulate = Color(0.6, 0.6, 0.7)
	create_tween().tween_property(sprite, "rotation", PI / 2.0, 0.4)
	died.emit()
	Game.game_over()
