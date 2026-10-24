extends Node2D
## Builds one world from the map in levels_data.gd and runs it: spawns the hero,
## monsters and items, locks the portal until every monster is defeated.
## world.tscn is level_index 0, world_2.tscn is level_index 1.

signal enemies_changed(left: int)

const LevelsData := preload("res://Scripts/levels_data.gd")
const HudScript := preload("res://Scripts/hud.gd")
const PortalScript := preload("res://Scripts/portal.gd")
const FX := preload("res://Scripts/fx.gd")

const TILES := preload("res://Assets/tiles.png")
const HUT_TEX := preload("res://Assets/hut.png")
const TREE_TEX := preload("res://Assets/tree.png")
const BANANA_TREE_TEX := preload("res://Assets/banana_tree.png")
const ROCK_TEX := preload("res://Assets/rock.png")

const PLAYER_SCENE := preload("res://Scenes/player.tscn")
const ASWANG_SCENE := preload("res://Scenes/aswang.tscn")
const TIKBALANG_SCENE := preload("res://Scenes/tikbalang.tscn")
const BOSS_SCENE := preload("res://Scenes/manananggal.tscn")
const PICKUP_SCENE := preload("res://Scenes/pickup.tscn")

const TILE := 16

@export var level_index := 0

var enemies_left := 0
var player: CharacterBody2D
var portal: Area2D

var _grid: Array = []
var _cols := 0
var _rows := 0
var _title := ""
var _night := false
var _objects: Node2D
var _hud: CanvasLayer
var _water_frame := 0
var _water_time := 0.0


func _ready() -> void:
	var data: Dictionary = LevelsData.LEVELS[level_index]
	_title = data["title"]
	_night = data["night"]
	_grid = data["rows"]
	_rows = _grid.size()
	_cols = _grid[0].length()

	# Everything that can stand in front of / behind the hero lives here (sorted by Y).
	_objects = Node2D.new()
	_objects.name = "Objects"
	_objects.y_sort_enabled = true
	add_child(_objects)

	_build_walls()
	_spawn_everything()
	_setup_camera()
	if _night:
		_add_night()

	_hud = HudScript.new()
	_hud.setup(self, player)
	add_child(_hud)

	Game.begin_level(level_index)
	Audio.set_music_pitch(0.82 if _night else 1.0)
	Audio.play_music()
	_hud.banner(_title)
	if enemies_left == 0:
		portal.open()


func toast(text: String) -> void:
	_hud.toast(text)


## Count a monster (also used for monsters summoned by the boss).
func register_enemy(enemy: Node) -> void:
	enemies_left += 1
	enemy.died.connect(_on_enemy_died)
	enemies_changed.emit(enemies_left)


func _on_enemy_died(_enemy: Node) -> void:
	enemies_left -= 1
	enemies_changed.emit(enemies_left)
	if enemies_left <= 0:
		portal.open()
		toast("All monsters defeated!  The portal opens!")


func _process(delta: float) -> void:
	_water_time += delta
	if _water_time >= 0.5:
		_water_time = 0.0
		_water_frame = 1 - _water_frame
		queue_redraw()
	portal.remaining = enemies_left


# ------------------------------------------------------------------- ground

func _draw() -> void:
	for y in _rows:
		for x in _cols:
			var index := 0
			match _grid[y][x]:
				"#":
					index = 7
				"~":
					index = 5 + _water_frame
				"=":
					index = 4
				",":
					index = 3
				_:
					var h: int = absi((x * 73856093) ^ (y * 19349663)) % 10
					index = 0 if h < 5 else (1 if h < 8 else 2)
			draw_texture_rect_region(TILES, Rect2(x * TILE, y * TILE, TILE, TILE), Rect2(index * TILE, 0, TILE, TILE))


func _build_walls() -> void:
	# Walls and water block movement. Each row is merged into long strips.
	var body := StaticBody2D.new()
	body.name = "Solids"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	for y in _rows:
		var x := 0
		while x < _cols:
			if _is_solid_tile(_grid[y][x]):
				var start := x
				while x < _cols and _is_solid_tile(_grid[y][x]):
					x += 1
				var shape := RectangleShape2D.new()
				shape.size = Vector2((x - start) * TILE, TILE)
				var cs := CollisionShape2D.new()
				cs.shape = shape
				cs.position = Vector2((start + x) * TILE / 2.0, y * TILE + TILE / 2.0)
				body.add_child(cs)
			else:
				x += 1


func _is_solid_tile(ch: String) -> bool:
	return ch == "#" or ch == "~"


# ------------------------------------------------------------------ spawning

func _spawn_everything() -> void:
	for y in _rows:
		for x in _cols:
			var ch: String = _grid[y][x]
			var center := Vector2(x * TILE + TILE / 2.0, y * TILE + TILE / 2.0)
			match ch:
				"H":
					_add_prop(HUT_TEX, Vector2(x * TILE + 32, y * TILE + 64), Vector2(-33, -65), Vector2(52, 26), Vector2(0, -13))
				"T":
					_add_prop(TREE_TEX, Vector2(center.x, y * TILE + TILE), Vector2(-20, -47), Vector2(10, 7), Vector2(0, -3.5))
				"B":
					_add_prop(BANANA_TREE_TEX, Vector2(center.x, y * TILE + TILE), Vector2(-20, -55), Vector2(8, 7), Vector2(0, -3.5))
				"R":
					_add_prop(ROCK_TEX, Vector2(center.x, y * TILE + TILE), Vector2(-9, -13), Vector2(12, 7), Vector2(0, -4))
				"P":
					_spawn_player(center + Vector2(0, 4))
				"a":
					_spawn_enemy(ASWANG_SCENE, center + Vector2(0, 4))
				"t":
					_spawn_enemy(TIKBALANG_SCENE, center + Vector2(0, 4))
				"M":
					_spawn_enemy(BOSS_SCENE, center + Vector2(0, 4))
				"g":
					_spawn_pickup("garlic", center + Vector2(0, 4))
				"s":
					_spawn_pickup("salt", center + Vector2(0, 4))
				"n":
					_spawn_pickup("banana", center + Vector2(0, 4))
				"X":
					portal = PortalScript.new()
					portal.position = center + Vector2(0, 6)
					_objects.add_child(portal)
	if portal == null:   # safety: every map should have an X
		portal = PortalScript.new()
		portal.position = Vector2(_cols * TILE - 40, _rows * TILE - 40)
		_objects.add_child(portal)


## A solid object (tree, hut, rock). Its origin is the bottom, so the hero can
## walk behind it when above it and in front of it when below it.
func _add_prop(texture: Texture2D, pos: Vector2, sprite_pos: Vector2, collider_size: Vector2, collider_pos: Vector2) -> void:
	var prop := StaticBody2D.new()
	prop.position = pos
	prop.collision_layer = 1
	prop.collision_mask = 0
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.position = sprite_pos
	prop.add_child(sprite)
	var shape := RectangleShape2D.new()
	shape.size = collider_size
	var cs := CollisionShape2D.new()
	cs.shape = shape
	cs.position = collider_pos
	prop.add_child(cs)
	_objects.add_child(prop)


func _spawn_player(pos: Vector2) -> void:
	player = PLAYER_SCENE.instantiate()
	player.position = pos
	_objects.add_child(player)


func _spawn_enemy(scene: PackedScene, pos: Vector2) -> void:
	var enemy := scene.instantiate()
	enemy.position = pos
	_objects.add_child(enemy)
	register_enemy(enemy)


func _spawn_pickup(kind: String, pos: Vector2) -> void:
	var item := PICKUP_SCENE.instantiate()
	item.kind = kind
	item.position = pos
	_objects.add_child(item)


func _setup_camera() -> void:
	var cam: Camera2D = player.camera
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = _cols * TILE
	cam.limit_bottom = _rows * TILE


func _add_night() -> void:
	var tint := CanvasModulate.new()
	tint.color = Color(0.42, 0.45, 0.78)
	add_child(tint)
	# fireflies drifting around the hero
	var flies := CPUParticles2D.new()
	flies.position = Vector2(0, -10)
	flies.amount = 26
	flies.lifetime = 5.0
	flies.preprocess = 5.0
	flies.local_coords = false
	flies.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	flies.emission_rect_extents = Vector2(330, 190)
	flies.direction = Vector2(0, -1)
	flies.spread = 180.0
	flies.initial_velocity_min = 3.0
	flies.initial_velocity_max = 10.0
	flies.gravity = Vector2.ZERO
	flies.scale_amount_min = 1.2
	flies.scale_amount_max = 2.0
	flies.z_index = 80
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(1, 1, 0.5, 0.0), Color(1, 1, 0.5, 1.0), Color(1, 1, 0.5, 0.0)])
	fade.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	flies.color_ramp = fade
	player.add_child(flies)
