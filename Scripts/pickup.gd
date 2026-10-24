extends Area2D
## Items to collect. Set "kind" in the Inspector:
##   garlic (bawang) - heals 2     banana (saging) - heals 1
##   salt (asin)     - +1 damage for the rest of the game (up to +3)

const FX := preload("res://Scripts/fx.gd")
const TEXTURES := {
	"garlic": preload("res://Assets/garlic.png"),
	"salt": preload("res://Assets/salt.png"),
	"banana": preload("res://Assets/banana.png"),
}
const MAX_SALT := 3

@export var kind := "garlic"

var _time := randf() * 6.0

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2   # player
	sprite.texture = TEXTURES.get(kind, TEXTURES["garlic"])


func _process(delta: float) -> void:
	_time += delta
	sprite.position.y = -8.0 + sin(_time * 4.0) * 2.0


func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body.is_in_group("player") and _try_collect(body):
			queue_free()
			return


func _try_collect(player: Node) -> bool:
	var spot := global_position + Vector2(0, -16)
	match kind:
		"garlic", "banana":
			if player.health >= player.max_health:
				return false   # leave it for later
			var amount := 2 if kind == "garlic" else 1
			player.heal(amount)
			Audio.play("heal")
			var label := "Bawang!  +%d HP" if kind == "garlic" else "Saging!  +%d HP"
			FX.popup(get_parent(), spot, label % amount, Color(0.6, 1.0, 0.6))
		"salt":
			if Game.salt_bonus >= MAX_SALT:
				return false
			Game.salt_bonus += 1
			Audio.play("powerup")
			FX.popup(get_parent(), spot, "Asin!  +1 DAMAGE", Color(0.7, 0.9, 1.0))
	return true
