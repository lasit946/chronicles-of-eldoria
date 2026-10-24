extends CanvasLayer
## On-screen display: hearts, monsters left, salt bonus, boss bar, messages.
## Built in code; created by level.gd.

const HEART_FULL := preload("res://Assets/heart_full.png")
const HEART_EMPTY := preload("res://Assets/heart_empty.png")
const SALT_ICON := preload("res://Assets/salt.png")

var _level: Node
var _player: Node
var _hearts: Array[TextureRect] = []
var _enemy_label: Label
var _salt_box: HBoxContainer
var _salt_label: Label
var _toast: Label
var _banner: Label
var _boss_box: Control
var _boss_fill: ColorRect
var _boss: Node
var _controls: Label
var _toast_tween: Tween


func setup(level: Node, player: Node) -> void:
	_level = level
	_player = player


func _ready() -> void:
	layer = 10
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# hearts
	var heart_row := HBoxContainer.new()
	heart_row.position = Vector2(8, 6)
	heart_row.add_theme_constant_override("separation", 2)
	root.add_child(heart_row)
	for i in _player.max_health:
		var heart := TextureRect.new()
		heart.texture = HEART_FULL
		heart.custom_minimum_size = Vector2(14, 13)
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart_row.add_child(heart)
		_hearts.append(heart)

	# salt bonus
	_salt_box = HBoxContainer.new()
	_salt_box.position = Vector2(8, 24)
	_salt_box.visible = false
	root.add_child(_salt_box)
	var icon := TextureRect.new()
	icon.texture = SALT_ICON
	icon.custom_minimum_size = Vector2(14, 14)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_salt_box.add_child(icon)
	_salt_label = _make_label(11)
	_salt_box.add_child(_salt_label)

	# monsters left
	_enemy_label = _make_label(12)
	_enemy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(_enemy_label)
	_enemy_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_enemy_label.offset_left = -200
	_enemy_label.offset_right = -8
	_enemy_label.offset_top = 6

	# toast (short messages)
	_toast = _make_label(13)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0
	root.add_child(_toast)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_left = -200
	_toast.offset_right = 200
	_toast.offset_top = 40

	# big banner at the start of a world
	_banner = _make_label(26)
	_banner.add_theme_color_override("font_color", Color(1.0, 0.42, 0.1))
	_banner.add_theme_constant_override("outline_size", 8)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_banner.modulate.a = 0.0
	root.add_child(_banner)
	_banner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_banner.offset_bottom = -60

	# controls hint
	_controls = _make_label(9)
	_controls.text = "WASD / Arrows: Move     Space / J / Click: Attack     Esc: Pause     M: Mute"
	_controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_controls)
	_controls.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_controls.offset_left = -300
	_controls.offset_right = 300
	_controls.offset_top = -18
	_controls.offset_bottom = -4
	var hint_tween := create_tween()
	hint_tween.tween_interval(9.0)
	hint_tween.tween_property(_controls, "modulate:a", 0.0, 1.0)

	# boss bar
	_boss_box = Control.new()
	_boss_box.visible = false
	root.add_child(_boss_box)
	_boss_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_boss_box.offset_left = -110
	_boss_box.offset_right = 110
	_boss_box.offset_top = -38
	_boss_box.offset_bottom = -22
	var bar_back := ColorRect.new()
	bar_back.color = Color(0, 0, 0, 0.7)
	_boss_box.add_child(bar_back)
	bar_back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_boss_fill = ColorRect.new()
	_boss_fill.color = Color(0.75, 0.15, 0.85)
	_boss_fill.position = Vector2(2, 2)
	_boss_fill.size = Vector2(216, 12)
	_boss_box.add_child(_boss_fill)
	var boss_name := _make_label(9)
	boss_name.text = "MANANANGGAL"
	boss_name.position = Vector2(2, -12)
	_boss_box.add_child(boss_name)

	_player.health_changed.connect(_on_health_changed)
	_level.enemies_changed.connect(_on_enemies_changed)
	_on_health_changed(_player.health, _player.max_health)
	_on_enemies_changed(_level.enemies_left)


func _process(_delta: float) -> void:
	if Game.salt_bonus > 0:
		_salt_box.visible = true
		_salt_label.text = "+%d damage" % Game.salt_bonus
	else:
		_salt_box.visible = false
	if _boss == null or not is_instance_valid(_boss):
		_boss = get_tree().get_first_node_in_group("boss")
		_boss_box.visible = false
		return
	_boss_box.visible = _boss.awake
	_boss_fill.size.x = 216.0 * clampf(float(_boss.hp) / float(_boss.max_hp), 0.0, 1.0)


func toast(text: String) -> void:
	_toast.text = text
	if _toast_tween != null:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(2.2)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)


func banner(text: String) -> void:
	_banner.text = text
	var tween := create_tween()
	tween.tween_property(_banner, "modulate:a", 1.0, 0.6)
	tween.tween_interval(1.8)
	tween.tween_property(_banner, "modulate:a", 0.0, 0.8)


func _on_health_changed(current: int, _maximum: int) -> void:
	for i in _hearts.size():
		_hearts[i].texture = HEART_FULL if i < current else HEART_EMPTY


func _on_enemies_changed(left: int) -> void:
	_enemy_label.text = "Monsters left: %d" % left


func _make_label(font_size: int) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)
	return label
