class_name OrbitAudio
extends Node
## Tiny procedural blips. Silent until enable() is called from the first user input.

const MIX := 22050.0
var player: AudioStreamPlayer
var pb: AudioStreamGeneratorPlayback
var phase := 0.0


func enable() -> void:
	if player != null:
		return
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = MIX
	gen.buffer_length = 0.4
	player = AudioStreamPlayer.new()
	player.stream = gen
	player.volume_db = -8.0
	add_child(player)
	player.play()
	pb = player.get_stream_playback() as AudioStreamGeneratorPlayback


func _blip(f0: float, f1: float, dur: float, vol: float) -> void:
	if pb == null:
		return
	var n := int(dur * MIX)
	if pb.get_frames_available() < n:
		return
	var buf := PackedVector2Array()
	buf.resize(n)
	for i in n:
		var k := float(i) / n
		phase += TAU * lerpf(f0, f1, k) / MIX
		var s := sin(phase) * vol * (1.0 - k)
		buf[i] = Vector2(s, s)
	pb.push_buffer(buf)


func shoot() -> void:
	_blip(300.0, 900.0, 0.12, 0.5)


func sink() -> void:
	_blip(520.0, 780.0, 0.12, 0.5)
	_blip(780.0, 1040.0, 0.18, 0.5)


func crash() -> void:
	_blip(220.0, 50.0, 0.22, 0.6)
