extends CharacterBody2D
## Base enemy. The Aswang chases the hero. Turn on "charger" for a Tikbalang that
## winds up and then charges. The boss (boss.gd) builds on this script.
## Change max_hp, speed, etc. in the Inspector of each enemy scene.

signal died(enemy)
signal hp_changed(current: int, maximum: int)

const FX := preload("res://Scripts/fx.gd")
const PICKUP := preload("res://Scenes/pickup.tscn")

@export var max_hp := 3
@export var speed := 38.0
@export var touch_damage := 1
@export var aggro_range := 120.0
@export var drop_chance := 0.55
@export var charger := false
@export var charge_speed := 190.0
@export var blood_color := Color(0.75, 0.2, 0.9)

var hp := 3
var player: Node2D
var awake := true

var _knock := Vector2.ZERO
var _flash := 0.0
var _touch_cooldown := 0.6
var _wander_dir := Vector2.ZERO
var _wander_timer := 0.0
var _state := "idle"
var _state_timer := 0.0
var _dash_dir := Vector2.ZERO
var _dead := false
var _time := randf() * 10.0

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4   # enemies
	collision_mask = 1    # world only (enemies pass through each other)
	hp = max_hp
	player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	if _dead:
		return
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	_time += delta
	_touch_cooldown = maxf(0.0, _touch_cooldown - delta)

	velocity = _think(delta) + _knock
	_knock = _knock.move_toward(Vector2.ZERO, 500.0 * delta)
	move_and_slide()

	if absf(velocity.x) > 1.0:
		sprite.flip_h = velocity.x < 0.0
	sprite.offset.y = -absf(sin(_time * 9.0)) * 1.2
	if _flash > 0.0:
		_flash -= delta
		sprite.self_modulate = Color(3, 3, 3)
	elif _state == "windup":
		sprite.self_modulate = Color(1.0, 0.45, 0.45)
	else:
		sprite.self_modulate = Color.WHITE

	if awake and _touch_cooldown <= 0.0 and player != null \
			and global_position.distance_to(player.global_position) < 11.0:
		_touch_cooldown = 0.9
		player.take_damage(touch_damage, global_position)


## Returns the velocity this enemy wants this frame.
func _think(delta: float) -> Vector2:
	if player == null:
		return Vector2.ZERO
	var to_player := player.global_position - global_position
	var dist := to_player.length()
	if charger:
		return _think_charger(delta, to_player, dist)
	if dist < aggro_range:
		return to_player.normalized() * speed
	return _wander(delta, 0.35)


func _wander(delta: float, factor: float) -> Vector2:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(1.0, 2.5)
		_wander_dir = Vector2.from_angle(randf() * TAU) if randf() < 0.65 else Vector2.ZERO
	return _wander_dir * speed * factor


func _think_charger(delta: float, to_player: Vector2, dist: float) -> Vector2:
	_state_timer -= delta
	match _state:
		"idle":
			if dist < aggro_range:
				_state = "windup"
				_state_timer = 0.7
				_dash_dir = to_player.normalized()
			return _wander(delta, 0.5)
		"windup":
			if _state_timer > 0.25:
				_dash_dir = to_player.normalized()
			if _state_timer <= 0.0:
				_state = "dash"
				_state_timer = 0.45
				Audio.play("swing", 0.6)
			return Vector2.ZERO
		"dash":
			if _state_timer <= 0.0:
				_state = "rest"
				_state_timer = 0.9
			return _dash_dir * charge_speed
		_:
			if _state_timer <= 0.0:
				_state = "idle"
			return Vector2.ZERO


func take_damage(amount: int, from_pos: Vector2) -> void:
	if _dead:
		return
	hp -= amount
	hp_changed.emit(maxi(hp, 0), max_hp)
	_flash = 0.12
	_knock = (global_position - from_pos).normalized() * 150.0
	if charger and _state == "windup":
		_state = "rest"
		_state_timer = 0.5
	FX.popup(get_parent(), global_position + Vector2(0, -18), str(amount), Color(1, 0.9, 0.4))
	if hp <= 0:
		_die()


func _die() -> void:
	_dead = true
	collision_layer = 0
	Game.kills += 1
	Audio.play("enemy_die")
	FX.puff(get_parent(), global_position + Vector2(0, -6), blood_color, 18)
	if randf() < drop_chance:
		_drop(_pick_drop())
	died.emit(self)
	queue_free()


func _pick_drop() -> String:
	var roll := randf()
	if roll < 0.4:
		return "garlic"
	if roll < 0.8:
		return "banana"
	return "salt"


func _drop(kind: String, offset: Vector2 = Vector2.ZERO) -> void:
	var item := PICKUP.instantiate()
	item.kind = kind
	item.position = position + offset
	get_parent().add_child.call_deferred(item)
