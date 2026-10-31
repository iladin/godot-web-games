extends Node
## Tiny synthesized SFX (AudioStreamWAV from generated PCM; web-safe). Silent until enable().

var enabled := false
var _players: Dictionary = {}


func _ready() -> void:
	_add("click", _tone([900.0], 0.05, 0.35, 0))
	_add("chime", _tone([660.0, 990.0], 0.22, 0.35, 0))
	_add("buzz", _tone([110.0], 0.28, 0.4, 1))
	_add("unlock", _tone([520.0, 780.0, 1040.0], 0.3, 0.3, 0))


func enable() -> void:
	enabled = true


func play(sfx: String, pitch: float = 1.0) -> void:
	if not enabled or not _players.has(sfx):
		return
	var p: AudioStreamPlayer = _players[sfx]
	p.pitch_scale = pitch
	p.play()


func _add(sfx: String, stream: AudioStreamWAV) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = -8.0
	add_child(p)
	_players[sfx] = p


## wave: 0 = square-ish sine, 1 = saw
func _tone(freqs: Array, secs: float, vol: float, wave: int) -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * secs)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		var t := float(i) / rate
		var env := (1.0 - float(i) / n) * minf(1.0, float(i) / 80.0)
		var f: float = freqs[mini(int(float(i) / n * freqs.size()), freqs.size() - 1)]
		var ph := fposmod(t * f, 1.0)
		var v := signf(sin(TAU * ph)) * 0.6 if wave == 0 else (ph * 2.0 - 1.0)
		bytes.encode_s16(i * 2, int(clampf(v * env * vol, -1.0, 1.0) * 32000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = rate
	s.data = bytes
	return s
