class_name LanternSfx
extends Node
## Tiny synthesized one-shot sounds (16-bit WAV built in code; no threads, web safe).

var players: Dictionary = {}
var enabled := false


func _ready() -> void:
	_add(&"jump", 380.0, 760.0, 0.12, 0.35, 0.0)
	_add(&"jump2", 520.0, 980.0, 0.12, 0.35, 0.0)
	_add(&"land", 120.0, 70.0, 0.07, 0.4, 0.2)
	_add(&"step", 200.0, 150.0, 0.03, 0.2, 0.3)
	_add(&"oil", 600.0, 1200.0, 0.22, 0.4, 0.0)
	_add(&"ember", 900.0, 1500.0, 0.3, 0.4, 0.0)
	_add(&"die", 300.0, 40.0, 0.5, 0.5, 0.5)


func _add(id: StringName, f0: float, f1: float, dur: float, vol: float, noise: float) -> void:
	var rate := 22050
	var n := int(dur * rate)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in n:
		var k := float(i) / float(n)
		phase += TAU * lerpf(f0, f1, k) / float(rate)
		var s := sin(phase) * (1.0 - noise) + randf_range(-1.0, 1.0) * noise
		data.encode_s16(i * 2, int(clampf(s * vol * (1.0 - k), -1.0, 1.0) * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	var p := AudioStreamPlayer.new()
	p.stream = wav
	add_child(p)
	players[id] = p


func play(id: StringName) -> void:
	if not enabled or not players.has(id):
		return
	var p: AudioStreamPlayer = players[id]
	p.pitch_scale = randf_range(0.93, 1.07)
	p.play()
