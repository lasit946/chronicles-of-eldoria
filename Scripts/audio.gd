extends Node
## Global audio (autoload name: Audio).
## Sound effects and background music are generated in code, so the game has
## sound with zero audio files. To use your own sounds, drop files named like
## the effects below into res://Audio/ (e.g. hit.wav, hurt.ogg, music.ogg) and
## they automatically replace the built-in ones.
##
## Usage from any script:
##     Audio.play("hit")
##     Audio.play("step", 1.0, 0.1)   # pitch 1.0, +/-10% random variation
##
## Sounds: click, swing, hit, hurt, enemy_die, step, pickup, portal_open,
##         locked, level_complete, victory, game_over
## Press M in game to mute / unmute everything.

const RATE := 16000
const VOICES := 8
const OVERRIDE_DIR := "res://Audio/"

const SINE := 0
const SQUARE := 1
const TRI := 2
const SAW := 3

var _sfx: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _music: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.volume_db = -4.0
		add_child(p)
		_voices.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -13.0
	add_child(_music)
	_build_sfx()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		var bus := AudioServer.get_bus_index("Master")
		AudioServer.set_bus_mute(bus, not AudioServer.is_bus_mute(bus))


func play(sfx_name: String, pitch: float = 1.0, pitch_variation: float = 0.0) -> void:
	var stream: AudioStream = _sfx.get(sfx_name)
	if stream == null:
		push_warning("Audio: unknown sound '%s'" % sfx_name)
		return
	var voice := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	voice.stream = stream
	voice.pitch_scale = pitch * (1.0 + randf_range(-pitch_variation, pitch_variation))
	voice.play()


func play_music() -> void:
	if _music.stream == null:
		var custom := _load_override("music")
		_music.stream = custom if custom != null else _make_music()
	if not _music.playing:
		_music.play()


func stop_music() -> void:
	_music.stop()


## 1.0 = normal. Lower is slower and spookier, higher is faster and tenser.
func set_music_pitch(pitch: float) -> void:
	_music.pitch_scale = pitch


# ---------------------------------------------------------------- sound list

func _build_sfx() -> void:
	_register("click", _sweep(900, 600, 0.06, SQUARE, 0.25, 6.0))
	_register("heal", _notes([523.25, 659.25, 783.99], 0.08, 0.2, SINE, 0.4, 3.0))
	_register("powerup", _notes([440.0, 554.37, 659.25, 880.0], 0.07, 0.18, SQUARE, 0.25, 3.0))
	_register("shoot", _sweep(700, 250, 0.14, SAW, 0.25, 4.0, 0.2))
	_register("boss_roar", _sweep(130, 55, 0.7, SAW, 0.5, 1.5, 0.5))
	_register("swing", _sweep(900, 250, 0.16, SAW, 0.30, 4.0, 0.75))
	_register("hit", _sweep(260, 60, 0.18, SQUARE, 0.40, 5.0, 0.5))
	_register("hurt", _sweep(520, 120, 0.30, SQUARE, 0.35, 2.5, 0.15))
	_register("enemy_die", _sweep(380, 40, 0.45, SAW, 0.35, 3.0, 0.3))
	_register("step", _sweep(110, 70, 0.05, SINE, 0.35, 7.0, 0.6))
	_register("pickup", _notes([659.25, 880.0, 1174.66], 0.07, 0.12, TRI, 0.4, 4.0))
	_register("portal_open", _notes([392.0, 523.25, 659.25, 783.99, 1046.5], 0.09, 0.35, TRI, 0.35, 2.5))
	_register("locked", _sweep(140, 100, 0.18, SQUARE, 0.30, 3.0))
	_register("level_complete", _notes([523.25, 659.25, 783.99, 1046.5], 0.14, 0.40, SQUARE, 0.25, 2.5))
	_register("victory", _notes([523.25, 523.25, 523.25, 659.25, 783.99, 659.25, 783.99, 1046.5], 0.16, 0.45, SQUARE, 0.25, 2.0))
	_register("game_over", _notes([392.0, 349.23, 311.13, 261.63, 196.0], 0.22, 0.50, SAW, 0.30, 2.5))


func _register(sfx_name: String, samples: PackedFloat32Array) -> void:
	var custom := _load_override(sfx_name)
	_sfx[sfx_name] = custom if custom != null else _wav(samples)


func _load_override(sfx_name: String) -> AudioStream:
	for ext in ["ogg", "wav", "mp3"]:
		var path := "%s%s.%s" % [OVERRIDE_DIR, sfx_name, ext]
		if ResourceLoader.exists(path):
			return load(path) as AudioStream
	return null


# -------------------------------------------------------------------- music

func _make_music() -> AudioStreamWAV:
	var eighth := 60.0 / 92.0 / 2.0
	var steps := 32
	var total := int(round(eighth * steps * RATE))
	var buf := PackedFloat32Array()
	buf.resize(total)

	var semis := [0, 3, 5, 7, 10, 12, 15, 17]  # A minor pentatonic
	var melody := [
		5, -1, 4, -1, 3, -1, 4, 5,
		6, -1, 5, -1, 4, -1, -1, -1,
		5, -1, 7, -1, 6, -1, 5, 4,
		3, -1, 2, -1, 1, -1, -1, -1,
	]
	var bass := [-12, -12, -9, -12, -12, -12, -14, -7]

	for s in steps:
		var pos := int(s * eighth * RATE)
		var m: int = melody[s]
		if m >= 0:
			var f := 220.0 * pow(2.0, semis[m] / 12.0)
			buf = _mix(buf, _sweep(f, f, eighth * 2.2, SQUARE, 0.13, 3.0), pos, true)
		if s % 4 == 0:
			var bf := 220.0 * pow(2.0, bass[int(s / 4.0)] / 12.0)
			buf = _mix(buf, _sweep(bf, bf, eighth * 3.6, TRI, 0.30, 1.5), pos, true)
		if s % 2 == 1:
			buf = _mix(buf, _sweep(1, 1, 0.03, SINE, 0.07, 8.0, 1.0), pos, true)

	var wav := _wav(buf)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = total
	return wav


# --------------------------------------------------------------- synthesis

func _osc(shape: int, phase: float) -> float:
	var p := phase - floorf(phase)
	match shape:
		SQUARE:
			return 1.0 if p < 0.5 else -1.0
		TRI:
			return 4.0 * absf(p - 0.5) - 1.0
		SAW:
			return 2.0 * p - 1.0
	return sin(TAU * p)


## One tone that glides from f0 to f1 and fades out. noise_mix 0..1 blends in noise.
func _sweep(f0: float, f1: float, dur: float, shape: int, vol: float, decay: float = 3.0, noise_mix: float = 0.0) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	var attack := 0.004 * RATE
	for i in n:
		var t := float(i) / n
		phase += lerpf(f0, f1, t) / RATE
		var env := exp(-decay * t) * minf(1.0, i / attack)
		var s := _osc(shape, phase)
		if noise_mix > 0.0:
			s = lerpf(s, randf() * 2.0 - 1.0, noise_mix)
		out[i] = s * env * vol
	return out


## A little run of notes, one every `step` seconds.
func _notes(freqs: Array, step: float, dur: float, shape: int, vol: float, decay: float) -> PackedFloat32Array:
	var total := int((step * (freqs.size() - 1) + dur) * RATE)
	var buf := PackedFloat32Array()
	buf.resize(total)
	for i in freqs.size():
		var f: float = freqs[i]
		buf = _mix(buf, _sweep(f, f, dur, shape, vol, decay), int(i * step * RATE))
	return buf


func _mix(dst: PackedFloat32Array, src: PackedFloat32Array, offset: int, wrap: bool = false) -> PackedFloat32Array:
	for i in src.size():
		var j := offset + i
		if wrap:
			j = j % dst.size()
		elif j >= dst.size():
			break
		dst[j] += src[i]
	return dst


func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav
