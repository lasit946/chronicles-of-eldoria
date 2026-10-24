extends Control
## Main menu. Built in code, so main_menu.tscn is just this script on a Control.

const ACCENT := Color(1.0, 0.42, 0.1)
const HUT := preload("res://Assets/hut.png")
const TREE := preload("res://Assets/tree.png")
const BANANA_TREE := preload("res://Assets/banana_tree.png")
const HERO := preload("res://Assets/hero.png")
const ASWANG := preload("res://Assets/aswang.png")
const TIKBALANG := preload("res://Assets/tikbalang.png")

var _help: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().paused = false
	Audio.set_music_pitch(0.82)
	_build_background()
	_build_scenery()
	_build_embers()
	_build_menu()
	Audio.play_music()


func _build_background() -> void:
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color(0.03, 0.03, 0.12), Color(0.22, 0.08, 0.12)])
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	var bg := TextureRect.new()
	bg.texture = tex
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# moon
	var moon := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.95, 0.75)
	style.set_corner_radius_all(30)
	moon.add_theme_stylebox_override("panel", style)
	moon.position = Vector2(500, 30)
	moon.size = Vector2(60, 60)
	add_child(moon)


## Little village scene along the bottom of the screen.
func _build_scenery() -> void:
	var ground := ColorRect.new()
	ground.color = Color(0.07, 0.13, 0.09)
	add_child(ground)
	ground.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	ground.offset_top = -48
	var props := [
		[TREE, Vector2(18, 258), 1.0], [HUT, Vector2(86, 268), 1.0], [BANANA_TREE, Vector2(168, 256), 1.0],
		[TREE, Vector2(470, 254), 1.0], [HUT, Vector2(520, 270), 1.0], [BANANA_TREE, Vector2(590, 262), 1.0],
		[HERO, Vector2(300, 322), 2.0], [ASWANG, Vector2(350, 322), 2.0], [TIKBALANG, Vector2(400, 316), 2.0],
	]
	for p in props:
		var tr := TextureRect.new()
		tr.texture = p[0]
		tr.stretch_mode = TextureRect.STRETCH_KEEP
		tr.scale = Vector2(p[2], p[2])
		tr.position = p[1]
		tr.modulate = Color(0.55, 0.55, 0.8)
		add_child(tr)


## Glowing embers floating up from the bottom of the screen.
func _build_embers() -> void:
	var size := get_viewport_rect().size
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(1.0, 0.65, 0.2, 1.0), Color(1.0, 0.25, 0.05, 0.0)])
	fade.offsets = PackedFloat32Array([0.0, 1.0])
	var embers := CPUParticles2D.new()
	embers.position = Vector2(size.x * 0.5, size.y + 6.0)
	embers.amount = 50
	embers.lifetime = 7.0
	embers.preprocess = 7.0
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(size.x * 0.5, 1.0)
	embers.direction = Vector2(0, -1)
	embers.spread = 20.0
	embers.gravity = Vector2.ZERO
	embers.initial_velocity_min = 12.0
	embers.initial_velocity_max = 35.0
	embers.scale_amount_min = 1.0
	embers.scale_amount_max = 2.2
	embers.color_ramp = fade
	add_child(embers)


func _build_menu() -> void:
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	center.add_child(box)

	var title := Label.new()
	title.text = "CHRONICLES\nOF ELDORIA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", ACCENT)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 10)
	box.add_child(title)

	var pulse := create_tween().set_loops()
	pulse.tween_property(title, "modulate", Color(1.0, 0.85, 0.55), 1.4)
	pulse.tween_property(title, "modulate", Color.WHITE, 1.4)

	var subtitle := Label.new()
	subtitle.text = "A Pinoy folklore adventure"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color(0.85, 0.8, 0.9))
	box.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	box.add_child(spacer)

	var play := _make_button("Play")
	play.pressed.connect(func(): Game.start_game())
	box.add_child(play)

	var how := _make_button("How to Play")
	how.pressed.connect(func(): _help.visible = not _help.visible)
	box.add_child(how)

	var quit := _make_button("Quit")
	quit.pressed.connect(func(): get_tree().quit())
	box.add_child(quit)

	_help = Label.new()
	_help.text = "Defeat every monster to open the glowing portal, then step inside.\nBawang (garlic) and saging (banana) heal you. Asin (salt) makes you hit harder.\n\nWASD / Arrows: Move     Space / J / Click: Attack\nEsc: Pause     M: Mute"
	_help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_help.add_theme_font_size_override("font_size", 10)
	_help.add_theme_color_override("font_outline_color", Color.BLACK)
	_help.add_theme_constant_override("outline_size", 4)
	_help.visible = false
	box.add_child(_help)

	play.grab_focus()


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(150, 26)
	button.add_theme_font_size_override("font_size", 13)
	button.pressed.connect(func(): Audio.play("click"))
	return button
