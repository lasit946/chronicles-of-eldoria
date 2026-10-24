extends Node
## Game flow (autoload name: Game): controls, starting the game, moving between
## worlds, pause, game over, victory, and the screen fade between scenes.

const LEVEL_SCENES := ["res://world.tscn", "res://world_2.tscn"]
const MENU_SCENE := "res://main_menu.tscn"
const ACCENT := Color(1.0, 0.42, 0.1)

var level_index := 0
var kills := 0
var salt_bonus := 0     # +damage collected from asin (salt); kept between worlds
var play_time := 0.0
var playing := false    # true while inside a world

var _salt_at_level_start := 0
var _busy := false
var _pause_open := false
var _overlay: CanvasLayer
var _fade: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 300
	add_child(fade_layer)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(_fade)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	if playing and not get_tree().paused:
		play_time += delta


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and playing:
		toggle_pause()
		get_viewport().set_input_as_handled()


# ----------------------------------------------------------------- controls

func _setup_input() -> void:
	_bind("move_left", [KEY_A, KEY_LEFT])
	_bind("move_right", [KEY_D, KEY_RIGHT])
	_bind("move_up", [KEY_W, KEY_UP])
	_bind("move_down", [KEY_S, KEY_DOWN])
	_bind("attack", [KEY_SPACE, KEY_J, KEY_Z], true)
	_bind("pause", [KEY_ESCAPE, KEY_P])


func _bind(action: String, keys: Array, with_mouse: bool = false) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	for k in keys:
		var e := InputEventKey.new()
		e.physical_keycode = k
		InputMap.action_add_event(action, e)
	if with_mouse:
		var m := InputEventMouseButton.new()
		m.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event(action, m)


# --------------------------------------------------------------- scene flow

func start_game() -> void:
	kills = 0
	salt_bonus = 0
	play_time = 0.0
	level_index = 0
	_change_scene(LEVEL_SCENES[0])


func go_to_menu() -> void:
	playing = false
	_change_scene(MENU_SCENE)


func retry_level() -> void:
	salt_bonus = _salt_at_level_start
	_change_scene(LEVEL_SCENES[level_index])


## Called by each world when it has finished building.
func begin_level(index: int) -> void:
	level_index = index
	_salt_at_level_start = salt_bonus
	playing = true
	_busy = false


func _change_scene(path: String) -> void:
	_busy = true
	playing = false
	await _fade_to(1.0, 0.35)
	_clear_overlay()
	_pause_open = false
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	await _fade_to(0.0, 0.35)


func _fade_to(alpha: float, time: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", alpha, time)
	await tween.finished


## Called by the portal when the player walks in while it is open.
func level_complete() -> void:
	if _busy:
		return
	_busy = true
	playing = false
	Audio.stop_music()
	Audio.set_music_pitch(1.0)
	get_tree().paused = true
	if level_index + 1 < LEVEL_SCENES.size():
		Audio.play("level_complete")
		_show_overlay("WORLD CLEARED!", "The darkness deepens... on to World %d" % (level_index + 2))
		await get_tree().create_timer(2.6, true).timeout
		level_index += 1
		_change_scene(LEVEL_SCENES[level_index])
	else:
		Audio.play("victory")
		var secs := int(play_time)
		_show_overlay("VICTORY!",
			"The seal is restored. Eldoria is saved!\nMonsters defeated: %d     Time: %d:%02d" % [kills, secs / 60, secs % 60],
			[["Play Again", start_game], ["Main Menu", go_to_menu]])


func game_over() -> void:
	if _busy:
		return
	_busy = true
	playing = false
	Audio.stop_music()
	Audio.set_music_pitch(1.0)
	Audio.play("game_over")
	await get_tree().create_timer(0.9).timeout
	get_tree().paused = true
	_show_overlay("YOU DIED", "The aswang claim another soul...",
		[["Try Again", retry_level], ["Main Menu", go_to_menu]])


func toggle_pause() -> void:
	if _pause_open:
		_resume()
		return
	if _busy or get_tree().paused:
		return
	_pause_open = true
	get_tree().paused = true
	Audio.play("click")
	_show_overlay("PAUSED", "",
		[["Resume", _resume], ["Restart World", retry_level], ["Main Menu", go_to_menu]])


func _resume() -> void:
	_pause_open = false
	_clear_overlay()
	get_tree().paused = false


# ------------------------------------------------------------------ overlay

func _clear_overlay() -> void:
	if _overlay != null:
		_overlay.queue_free()
		_overlay = null


## buttons: an Array of [label, Callable] pairs.
func _show_overlay(title: String, subtitle: String, buttons: Array = []) -> void:
	_clear_overlay()
	_overlay = CanvasLayer.new()
	_overlay.layer = 100
	_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_overlay)

	var root := Control.new()
	_overlay.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.7)
	root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	center.add_child(box)

	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 34)
	title_label.add_theme_color_override("font_color", ACCENT)
	title_label.add_theme_color_override("font_outline_color", Color.BLACK)
	title_label.add_theme_constant_override("outline_size", 8)
	box.add_child(title_label)

	if subtitle != "":
		var sub_label := Label.new()
		sub_label.text = subtitle
		sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sub_label.add_theme_font_size_override("font_size", 13)
		box.add_child(sub_label)

	var first: Button = null
	for entry in buttons:
		var button := Button.new()
		button.text = entry[0]
		button.custom_minimum_size = Vector2(150, 26)
		button.add_theme_font_size_override("font_size", 13)
		var action: Callable = entry[1]
		button.pressed.connect(func():
			Audio.play("click")
			action.call())
		box.add_child(button)
		if first == null:
			first = button
	if first != null:
		first.grab_focus()

	root.modulate.a = 0.0
	create_tween().tween_property(root, "modulate:a", 1.0, 0.35)
