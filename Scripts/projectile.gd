extends Area2D
## A dark orb shot by the boss. Hurts the hero, disappears on walls.

var direction := Vector2.RIGHT
var speed := 105.0
var damage := 1

var _life := 5.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 3   # world + player
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	rotation += delta * 8.0
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.take_damage(damage, global_position)
		queue_free()
	elif body is StaticBody2D:
		queue_free()
