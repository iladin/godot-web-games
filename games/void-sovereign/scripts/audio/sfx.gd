class_name Sfx
extends Node
## Procedural sound effects. Every sound is synthesised once into an AudioStreamWAV
## (22050 Hz, mono, 16-bit) — no AudioStreamGenerator, no asset files. Owned by main.gd.
## Browser autoplay rule: nothing plays until the first key / click / tap (`unlock()`).
## Mute: N key or the SND touch button (main.gd polls the touch button).

const MIX_RATE := 22050
const POOL_SIZE := 10
const MASTER_DB := -6.0
const VOLUME_DB: Dictionary = {
	"laser": -10.0, "rifle": -7.0, "hit": -9.0, "explosion": -2.0, "gate": -4.0, "click": -12.0, "alert": -6.0, "kill": -5.0,
}
const PITCH_JITTER := 0.08          # +-8 % random pitch per play
const MIN_INTERVAL := 0.045         # same sound re-triggered faster than this is skipped (twin guns)
const NAMES: Array[String] = ["laser", "rifle", "hit", "explosion", "gate", "click", "alert", "kill"]
const MUTE_KEY := KEY_N

signal mute_changed(is_muted: bool)

var streams: Dictionary = {}        # name -> AudioStreamWAV
var unlocked: bool = false          # becomes true on the first user input
var muted: bool = false
var played: int = 0                 # plays that passed the gate (tests read this)
var blocked: int = 0                # plays refused because audio is still locked
var _pool: Array[AudioStreamPlayer] = []
var _next: int = 0
var _last: Dictionary = {}          # name -> ticks msec
var _rng := RandomNumberGenerator.new()   # own RNG: never disturbs the sim's global randomness


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not InputMap.has_action("mute"):
		InputMap.add_action("mute")
		var ev := InputEventKey.new()
		ev.physical_keycode = MUTE_KEY
		InputMap.action_add_event("mute", ev)
	if streams.is_empty():
		streams = generate_all()
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)


func _input(event: InputEvent) -> void:
	var gesture := (event is InputEventKey and (event as InputEventKey).pressed) \
		or (event is InputEventMouseButton and (event as InputEventMouseButton).pressed) \
		or (event is InputEventScreenTouch and (event as InputEventScreenTouch).pressed)
	if gesture:
		unlock()
	if event.is_action_pressed("mute"):
		toggle_mute()


func unlock() -> void:
	unlocked = true


func toggle_mute() -> void:
	unlock()
	muted = not muted
	mute_changed.emit(muted)
	if muted:
		for p: AudioStreamPlayer in _pool:
			p.stop()
	else:
		play("click")


## Returns true when the sound passed the autoplay/mute gate.
func play(sound: String, gain_db: float = 0.0) -> bool:
	if not unlocked:
		blocked += 1
		return false
	if muted or not streams.has(sound):
		return false
	var now := Time.get_ticks_msec()
	if _last.has(sound) and now - int(_last[sound]) < int(MIN_INTERVAL * 1000.0):
		return false
	_last[sound] = now
	played += 1
	if not is_inside_tree() or _pool.is_empty():
		return true
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = streams[sound]
	p.volume_db = MASTER_DB + float(VOLUME_DB.get(sound, 0.0)) + gain_db
	p.pitch_scale = 1.0 + _rng.randf_range(-PITCH_JITTER, PITCH_JITTER)
	p.play()
	return true


# --- Synthesis -------------------------------------------------------------------------------
static func generate_all() -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	var out: Dictionary = {}
	out["laser"] = _laser()
	out["rifle"] = _rifle(rng)
	out["hit"] = _hit(rng)
	out["explosion"] = _explosion(rng)
	out["gate"] = _gate()
	out["click"] = _click()
	out["alert"] = _alert()
	out["kill"] = _kill()
	return out


static func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = MIX_RATE
	w.stereo = false
	w.data = data
	return w


static func _buf(seconds: float) -> PackedFloat32Array:
	var s := PackedFloat32Array()
	s.resize(int(seconds * MIX_RATE))
	return s


## Space laser: square-ish wave sweeping 1400 -> 300 Hz with a fast decay.
static func _laser() -> AudioStreamWAV:
	var s := _buf(0.13)
	var phase := 0.0
	var n := s.size()
	for i in n:
		var t := float(i) / n
		phase += lerpf(1400.0, 300.0, t) / MIX_RATE
		var v := 1.0 if fmod(phase, 1.0) < 0.5 else -1.0
		s[i] = v * 0.45 * pow(1.0 - t, 2.0)
	return _wav(s)


## Surface rifle: noise crack + low thump.
static func _rifle(rng: RandomNumberGenerator) -> AudioStreamWAV:
	var s := _buf(0.14)
	var n := s.size()
	var lp := 0.0
	for i in n:
		var t := float(i) / n
		lp = lerpf(lp, rng.randf_range(-1.0, 1.0), 0.55)
		var thump := sin(TAU * lerpf(160.0, 60.0, t) * float(i) / MIX_RATE)
		s[i] = (lp * 0.8 * exp(-t * 14.0) + thump * 0.6 * exp(-t * 7.0))
	return _wav(s)


## Kill confirm (VS-037): two rising blips, higher than the hit tick.
static func _kill() -> AudioStreamWAV:
	var s := _buf(0.2)
	var n := s.size()
	for i in n:
		var t := float(i) / n
		var f := 1100.0 if t < 0.45 else 1650.0
		var lt := t if t < 0.45 else t - 0.45
		s[i] = sin(TAU * f * float(i) / MIX_RATE) * 0.55 * exp(-lt * 7.0) * minf(1.0, lt * 80.0)
	return _wav(s)


## Hit marker: short bright tick.
static func _hit(rng: RandomNumberGenerator) -> AudioStreamWAV:
	var s := _buf(0.06)
	var n := s.size()
	for i in n:
		var t := float(i) / n
		s[i] = (sin(TAU * 2200.0 * float(i) / MIX_RATE) * 0.5 + rng.randf_range(-0.3, 0.3)) * (1.0 - t)
	return _wav(s)


## Explosion: low-passed noise with a falling cutoff and long tail.
static func _explosion(rng: RandomNumberGenerator) -> AudioStreamWAV:
	var s := _buf(0.7)
	var n := s.size()
	var lp := 0.0
	var lp2 := 0.0
	for i in n:
		var t := float(i) / n
		var k := lerpf(0.35, 0.03, t)
		lp = lerpf(lp, rng.randf_range(-1.0, 1.0), k)
		lp2 = lerpf(lp2, lp, k)
		var env := minf(1.0, t * 60.0) * pow(1.0 - t, 1.6)
		s[i] = lp2 * 3.2 * env
	return _wav(s)


## Gate jump: rising whoosh (sine sweep + filtered noise swell).
static func _gate() -> AudioStreamWAV:
	var s := _buf(0.55)
	var n := s.size()
	var phase := 0.0
	var phase2 := 0.0
	for i in n:
		var t := float(i) / n
		phase += lerpf(180.0, 900.0, t * t) / MIX_RATE
		phase2 += lerpf(183.0, 912.0, t * t) / MIX_RATE
		var env := sin(PI * t)
		s[i] = (sin(TAU * phase) + sin(TAU * phase2)) * 0.3 * env
	return _wav(s)


## UI click: tiny 1 kHz blip.
static func _click() -> AudioStreamWAV:
	var s := _buf(0.035)
	var n := s.size()
	for i in n:
		var t := float(i) / n
		s[i] = sin(TAU * 1000.0 * float(i) / MIX_RATE) * 0.5 * (1.0 - t) * (1.0 - t)
	return _wav(s)


## Sortie alert: two descending square-ish blips.
static func _alert() -> AudioStreamWAV:
	var s := _buf(0.4)
	var n := s.size()
	for i in n:
		var t := float(i) / n
		var f := 880.0 if t < 0.45 else 660.0
		var gate := 1.0 if fmod(t, 0.5) < 0.4 else 0.0
		s[i] = signf(sin(TAU * f * float(i) / MIX_RATE)) * 0.25 * gate * (1.0 - t * 0.5)
	return _wav(s)
