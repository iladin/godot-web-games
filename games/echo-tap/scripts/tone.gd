class_name EchoTone
extends Node
## Tiny synth: enveloped sine/saw bursts pushed into an AudioStreamGenerator (no threads).
## Does nothing until unlock() is called from a user input (browser autoplay policy).

const MIX_RATE := 22050.0
const TONE_LEN := 0.18

var unlocked := false
var _pb: AudioStreamGeneratorPlayback
var _voices: Array[Dictionary] = []


func unlock() -> void:
	if unlocked:
		return
	unlocked = true
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = MIX_RATE
	gen.buffer_length = 0.25
	var p := AudioStreamPlayer.new()
	p.stream = gen
	add_child(p)
	p.play()
	_pb = p.get_stream_playback() as AudioStreamGeneratorPlayback


func play(freq: float, length: float = TONE_LEN, vol: float = 0.3, saw: bool = false) -> void:
	if _pb == null or _voices.size() > 12:
		return
	_voices.append({"f": freq, "ph": 0.0, "t": 0, "total": int(length * MIX_RATE), "vol": vol, "saw": saw})


func _process(_delta: float) -> void:
	if _pb == null:
		return
	var n: int = _pb.get_frames_available()
	if n <= 0:
		return
	var buf := PackedVector2Array()
	buf.resize(n)
	for vi in range(_voices.size() - 1, -1, -1):
		var v: Dictionary = _voices[vi]
		var ph: float = v["ph"]
		var t: int = v["t"]
		var total: int = v["total"]
		var step: float = float(v["f"]) / MIX_RATE
		var vol: float = v["vol"]
		var saw: bool = v["saw"]
		var i := 0
		while i < n and t < total:
			var env: float = minf(float(t) / 110.0, 1.0) * (1.0 - float(t) / float(total))
			var s: float = (2.0 * ph - 1.0) if saw else sin(TAU * ph)
			buf[i] += Vector2.ONE * (s * env * vol)
			ph = fmod(ph + step, 1.0)
			t += 1
			i += 1
		if t >= total:
			_voices.remove_at(vi)
		else:
			v["ph"] = ph
			v["t"] = t
	_pb.push_buffer(buf)
