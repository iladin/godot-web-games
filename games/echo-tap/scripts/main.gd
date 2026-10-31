extends Node2D
## Echo Tap: watch a rhythmic phrase on four pads, echo it back on beat. TITLE -> PLAYING -> GAME_OVER.
## Rules/ramp/scoring tunables live in echo_logic.gd; pad geometry and juice in pads.gd.
## Args: --autoplay (bot plays via real input events), --shotfile=<png> [--shotframe=N] (screenshot + quit).

# --- Tunables ---------------------------------------------------------------
const BG := Color("0d0b1e")
const ACCENT := Color("3fe0ff")
const GOLD := Color("ffd23f")
const RED := Color("ff4f5e")
const HUD_COL := Color("f2f0ff")
const LIVES := 3
const COUNT_IN_LISTEN := 4   # ticks before the phrase
const COUNT_IN_ECHO := 2     # ticks before the echo window
const GAP_BEATS := 1
const LEAD_IN := 0.6         # seconds before the first tick of a round
const INPUT_OFFSET_MS := 0.0 # latency compensation added to input timestamps
const RESULT_PAUSE := 0.8
const RESTART_DELAY := 0.6
const TONE_HZ: Array[float] = [523.25, 659.25, 783.99, 987.77]
const PAUSE_RECT := Rect2(620, 20, 88, 88)
const SAVE_PATH := "user://save.cfg"

enum State { TITLE, PLAYING, GAME_OVER }
enum Phase { COUNT_IN, LISTEN, ECHO, RESULT }

var state: State = State.TITLE
var phase: Phase = Phase.COUNT_IN
var paused := false
var autoplay := false
var audio_unlocked := false
var state_time := 0.0
var song_time := 0.0           # advances only while unpaused
var round_num := 1
var lives := LIVES
var score := 0
var best := 0
var new_best := false
var streak := 0
var phrase: Array = []
var results: Array[int] = []
var next_note := 0
var listen_idx := 0
var tick_idx := 0
var ticks: Array[float] = []
var t0 := 0.0
var phrase_start := 0.0
var listen_end := 0.0
var echo_start := 0.0
var bl := 0.667
var good_win := EchoLogic.GOOD_WINDOW
var result_timer := 0.0
var round_failed := false
var rng := RandomNumberGenerator.new()
var pads: Pads
var hud: EchoHud
var tone: EchoTone
var font: Font = ThemeDB.fallback_font
var bot_sent := -1
var bot_erred := false
var shot_path := ""
var shot_frame := 180
var frames := 0


func _ready() -> void:
	best = EchoSupport.load_best(SAVE_PATH)
	EchoSupport.register_actions()
	hud = EchoHud.new()
	hud.z_index = 1
	hud.game = self
	pads = Pads.new()
	pads.visible = false
	add_child(pads)
	add_child(hud)
	tone = EchoTone.new()
	add_child(tone)
	rng.randomize()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shotfile="):
			shot_path = a.substr(11)
		elif a.begins_with("--shotframe="):
			shot_frame = int(a.substr(12))
	if "--autoplay" in OS.get_cmdline_user_args():
		autoplay = true
		rng.seed = 7
		_unlock_audio()
		_start_game()


func _unlock_audio() -> void:
	audio_unlocked = true
	tone.unlock()


# --- State machine ----------------------------------------------------------
func _start_game() -> void:
	state = State.PLAYING
	state_time = 0.0
	song_time = 0.0
	round_num = 1
	lives = LIVES
	score = 0
	streak = 0
	new_best = false
	bot_erred = false
	paused = false
	pads.visible = true
	pads.reset()
	phrase = EchoLogic.make_phrase(rng, round_num)
	_begin_round()


func _begin_round() -> void:
	bl = EchoLogic.beat_len(EchoLogic.bpm_for_round(round_num))
	good_win = EchoLogic.good_window_for_round(round_num)
	t0 = song_time + LEAD_IN
	phrase_start = t0 + COUNT_IN_LISTEN * bl
	listen_end = phrase_start + (float(phrase[phrase.size() - 1]["beat"]) + 1.0) * bl
	var echo_ticks := listen_end + GAP_BEATS * bl
	echo_start = echo_ticks + COUNT_IN_ECHO * bl
	ticks.clear()
	for i in COUNT_IN_LISTEN:
		ticks.append(t0 + i * bl)
	for i in COUNT_IN_ECHO:
		ticks.append(echo_ticks + i * bl)
	tick_idx = 0
	listen_idx = 0
	next_note = 0
	results.clear()
	round_failed = false
	bot_sent = -1
	phase = Phase.COUNT_IN
	pads.progress = 0.0
	pads.dim = true


func _end_game() -> void:
	state = State.GAME_OVER
	state_time = 0.0
	pads.visible = false
	if score > best:
		best = score
		new_best = true
		EchoSupport.save_best(SAVE_PATH, best)


func _process(delta: float) -> void:
	queue_redraw()
	_shot_tick()
	if paused:
		return
	state_time += delta
	if state != State.PLAYING:
		return
	song_time += delta
	pads.pulse = 1.0 - fposmod((song_time - t0) / bl, 1.0) if song_time >= t0 else 0.0
	while tick_idx < ticks.size() and song_time >= ticks[tick_idx]:
		tone.play(1400.0 if tick_idx % COUNT_IN_LISTEN == 0 else 1000.0, 0.04, 0.12)
		tick_idx += 1
	match phase:
		Phase.COUNT_IN:
			if song_time >= phrase_start:
				phase = Phase.LISTEN
		Phase.LISTEN:
			while listen_idx < phrase.size() and song_time >= phrase_start + float(phrase[listen_idx]["beat"]) * bl:
				_sound_pad(int(phrase[listen_idx]["pad"]))
				listen_idx += 1
			if song_time >= listen_end:
				phase = Phase.ECHO
				pads.dim = false
		Phase.ECHO:
			if autoplay:
				_bot_step()
			if next_note < phrase.size() and song_time > _note_time(next_note) + good_win:
				_fail_round(int(phrase[next_note]["pad"]))
		Phase.RESULT:
			result_timer -= delta
			if result_timer <= 0.0:
				_after_result()


func _after_result() -> void:
	if lives <= 0:
		_end_game()
		return
	if not round_failed:
		round_num += 1
		phrase = EchoLogic.make_phrase(rng, round_num)
	_begin_round()


func _note_time(i: int) -> float:
	return echo_start + float(phrase[i]["beat"]) * bl


func _sound_pad(i: int) -> void:
	pads.light(i)
	tone.play(TONE_HZ[i])


# --- Gameplay -----------------------------------------------------------------
func _press_pad(i: int) -> void:
	if state != State.PLAYING or phase != Phase.ECHO or paused:
		return
	var t := song_time + INPUT_OFFSET_MS / 1000.0
	var err := t - _note_time(next_note)
	if next_note == 0 and err < -good_win:
		return  # still in the count-in: ignore
	_sound_pad(i)
	if absf(err) > good_win or i != int(phrase[next_note]["pad"]):
		_fail_round(i)
		return
	var j := EchoLogic.judge(err, good_win)
	results.append(j)
	var pts := int(EchoLogic.note_points(j) * EchoLogic.multiplier(streak))
	score += pts
	var col := GOLD if j == EchoLogic.JUDGE_PERFECT else HUD_COL
	pads.popup("PERFECT" if j == EchoLogic.JUDGE_PERFECT else "GOOD", col, pads.pad_pos(i))
	pads.burst(pads.pad_pos(i), Pads.COLORS[i], 8 if j == EchoLogic.JUDGE_PERFECT else 4)
	next_note += 1
	pads.progress = float(next_note) / float(phrase.size())
	if next_note >= phrase.size():
		_clear_round()


func _clear_round() -> void:
	var flawless := not results.has(EchoLogic.JUDGE_GOOD)
	score += int(EchoLogic.clear_bonus(phrase.size(), flawless) * EchoLogic.multiplier(streak))
	streak += 1
	if flawless:
		pads.ring_burst(GOLD)
		pads.popup("FLAWLESS!", GOLD, Pads.PAD_CENTER + Vector2(0, -20))
	else:
		pads.popup("CLEAR", ACCENT, Pads.PAD_CENTER + Vector2(0, -20))
	phase = Phase.RESULT
	result_timer = RESULT_PAUSE


func _fail_round(pad: int) -> void:
	lives -= 1
	streak = 0
	round_failed = true
	pads.fail_fx()
	pads.popup("MISS", RED, pads.pad_pos(pad))
	tone.play(90.0, 0.3, 0.35, true)
	phase = Phase.RESULT
	result_timer = RESULT_PAUSE


func _bot_step() -> void:
	# Plays through real input events. Deliberately botches round 2 once to exercise the fail path.
	if next_note >= phrase.size() or bot_sent == next_note:
		return
	if song_time < _note_time(next_note) + 0.02 * sin(float(next_note) * 1.7):
		return
	bot_sent = next_note
	var pad: int = phrase[next_note]["pad"]
	if round_num == 2 and not bot_erred and next_note == 1:
		bot_erred = true
		pad = (pad + 1) % 4
	var ev := InputEventAction.new()
	ev.action = "pad_%d" % pad
	ev.pressed = true
	Input.parse_input_event(ev)


# --- Input -----------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	var tap: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	if not audio_unlocked and (tap or (event is InputEventKey and event.pressed)):
		_unlock_audio()
	var go: bool = tap or event.is_action_pressed("start")
	if state == State.PLAYING:
		if event.is_action_pressed("pause") or (tap and PAUSE_RECT.has_point(event.position)):
			paused = not paused
			pads.set_process(not paused)
			return
		if paused:
			if go:
				paused = false
				pads.set_process(true)
			return
		for i in 4:
			if event.is_action_pressed("pad_%d" % i):
				_press_pad(i)
		if tap:
			var p := pads.pad_at(event.position)
			if p >= 0:
				_press_pad(p)
	elif go:
		if state == State.TITLE or state_time > RESTART_DELAY:
			_start_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == State.PLAYING:
		paused = true
		pads.set_process(false)


func _shot_tick() -> void:
	if shot_path == "":
		return
	frames += 1
	if frames == shot_frame:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(shot_path)
		get_tree().quit()


func _draw() -> void:
	var drift := clampf((EchoLogic.bpm_for_round(round_num) - EchoLogic.BPM_START) / 80.0, 0.0, 1.0) * 0.12 if state == State.PLAYING else 0.0
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color.from_hsv(BG.h + drift, BG.s, BG.v))
