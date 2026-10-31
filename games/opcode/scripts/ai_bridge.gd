extends Node2D
## AI-player interface, shared by the "built for AI players" games (Falsify, Opcode, Crossfire).
##
## Three ways in, all driving the same text commands the game understands:
##   1. Keyboard command line — press "/" , type a command, Enter. Stays open for the next
##      command (a leading "/" is ignored, so "/move ne" typed twice works). Esc closes.
##   2. Browser JS — window.aiGame.state() -> state object, window.aiGame.play("cmd") -> result
##      object {ok, msg, state}. observe() / act(cmd) return the same as JSON strings, and
##      window.aiGame.help lists the commands.
##   3. Headless — the game calls run_command() directly (autoplay bot, selftest).
## Also: "--shot=<name> --shotfile=<png>" user args let tools render a scenario to a PNG.

const CONSOLE_BG := Color(0.02, 0.03, 0.07, 0.94)
const CONSOLE_EDGE := Color(1, 1, 1, 0.18)
const TEXT := Color("e8f0ff")
const OK_COLOR := Color("7dffb0")
const ERR_COLOR := Color("ff6b8a")
const FONT_SIZE := 28
const MSG_TIME := 4.0
const MAX_MSG_LINES := 12

var observe_fn: Callable
var act_fn: Callable
var help_text: String = ""
var console_open: bool = false
var buffer: String = ""
var message: String = ""
var message_ok: bool = true
var message_mono: bool = false   # draw with a fixed advance (ASCII maps)
var message_time: float = 0.0
var history: PackedStringArray = []
var history_index: int = -1
var blink: float = 0.0
var font: Font = ThemeDB.fallback_font

var shot_name: String = ""
var shot_file: String = ""
var _shot_frames: int = -1
var _api: Object = null
var _cb_observe: Object = null
var _cb_act: Object = null


func setup(observe: Callable, act: Callable, help: String) -> void:
	observe_fn = observe
	act_fn = act
	help_text = help
	z_index = 100
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			shot_name = a.trim_prefix("--shot=")
		elif a.begins_with("--shotfile="):
			shot_file = a.trim_prefix("--shotfile=")
	if OS.has_feature("web"):
		_setup_js()


func _setup_js() -> void:
	var window: Object = JavaScriptBridge.get_interface("window")
	_cb_observe = JavaScriptBridge.create_callback(_js_observe)
	_cb_act = JavaScriptBridge.create_callback(_js_act)
	_api = JavaScriptBridge.create_object("Object")
	_api.set("_observe", _cb_observe)
	_api.set("_act", _cb_act)
	_api.set("help", help_text)
	window.set("aiGame", _api)
	# Godot callbacks can't hand a value back to JS, but they run synchronously, so thin JS
	# wrappers call them and return what they mirrored into lastObservation / lastResult.
	JavaScriptBridge.eval("""
		window.aiGame.observe = function () { window.aiGame._observe(); return window.aiGame.lastObservation; };
		window.aiGame.act = function (cmd) { window.aiGame._act(String(cmd)); return window.aiGame.lastResult; };
		window.aiGame.state = function () { return JSON.parse(window.aiGame.observe()); };
		window.aiGame.play = function (cmd) { return JSON.parse(window.aiGame.act(cmd)); };
	""", true)
	print("[aiGame] ready - aiGame.state() / aiGame.play(cmd) return objects; observe() / act(cmd) return JSON; aiGame.help")


## Run one text command through the game. Always returns {"ok": bool, "msg": String}.
func run_command(raw: String, show: bool = true) -> Dictionary:
	var cmd := raw.strip_edges()
	while cmd.begins_with("/"):
		cmd = cmd.substr(1).strip_edges()
	var res: Dictionary
	if cmd.to_lower() == "help" or cmd == "?":
		res = {"ok": true, "msg": help_text}
	else:
		res = act_fn.call(cmd)
	if not res.has("ok"):
		res["ok"] = false
	if not res.has("msg"):
		res["msg"] = ""
	if show:
		show_message(str(res.msg), bool(res.ok), bool(res.get("mono", false)))
	return res


func show_message(text: String, ok: bool = true, mono: bool = false) -> void:
	message = text
	message_ok = ok
	message_mono = mono
	message_time = MSG_TIME + 0.04 * text.length()
	queue_redraw()


func _js_observe(_args: Array) -> String:
	var s := JSON.stringify(observe_fn.call())
	if _api != null:
		_api.set("lastObservation", s)
	return s


func _js_act(args: Array) -> String:
	var cmd: String = str(args[0]) if args.size() > 0 else ""
	var res := run_command(cmd)
	res["state"] = observe_fn.call()
	var s := JSON.stringify(res)
	if _api != null:
		_api.set("lastResult", s)
	return s


## Capture the screen this many frames from now, then quit (used with --shot).
func capture_after(frames: int) -> void:
	_shot_frames = frames


func _process(delta: float) -> void:
	blink += delta
	if message_time > 0.0:
		message_time -= delta
		queue_redraw()
	if console_open:
		queue_redraw()
	if _shot_frames > 0:
		_shot_frames -= 1
		if _shot_frames == 0:
			_shot_frames = -1
			_save_shot()


func _save_shot() -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if shot_file != "":
		img.save_png(shot_file)
		print("shot saved ", shot_file)
	get_tree().quit()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and console_open:
		console_open = false
		queue_redraw()
		return
	if not (event is InputEventKey) or not event.pressed:
		return
	var k := event as InputEventKey
	if not console_open:
		if k.unicode == 47 or k.keycode == KEY_SLASH:
			console_open = true
			buffer = ""
			history_index = -1
			get_viewport().set_input_as_handled()
			queue_redraw()
		return
	get_viewport().set_input_as_handled()
	match k.keycode:
		KEY_ESCAPE:
			console_open = false
		KEY_ENTER, KEY_KP_ENTER:
			var cmd := buffer.strip_edges()
			buffer = ""
			history_index = -1
			if cmd != "" and cmd != "/":
				history.append(cmd)
				run_command(cmd)
		KEY_BACKSPACE:
			buffer = buffer.left(buffer.length() - 1)
		KEY_UP:
			if history.size() > 0:
				history_index = history.size() - 1 if history_index < 0 else maxi(history_index - 1, 0)
				buffer = history[history_index]
		KEY_DOWN:
			if history_index >= 0:
				history_index += 1
				if history_index >= history.size():
					history_index = -1
					buffer = ""
				else:
					buffer = history[history_index]
		_:
			if k.unicode >= 32 and k.unicode < 127 and buffer.length() < 120:
				buffer += char(k.unicode)
	queue_redraw()


func _draw() -> void:
	var size := get_viewport_rect().size
	var bar_h := 64.0
	var bottom := size.y
	if console_open:
		draw_rect(Rect2(0.0, size.y - bar_h - 34.0, size.x, bar_h + 34.0), CONSOLE_BG)
		draw_rect(Rect2(0.0, size.y - bar_h, size.x, 2.0), CONSOLE_EDGE)
		var caret := "_" if fmod(blink, 1.0) < 0.6 else " "
		draw_string(font, Vector2(20.0, size.y - 20.0), "> " + buffer + caret, HORIZONTAL_ALIGNMENT_LEFT, size.x - 40.0, FONT_SIZE, TEXT)
		draw_string(font, Vector2(20.0, size.y - bar_h - 10.0), "command line - Enter runs, Esc closes, 'help' lists commands", HORIZONTAL_ALIGNMENT_LEFT, size.x - 40.0, 20, Color(TEXT, 0.6))
		bottom = size.y - bar_h - 34.0
	if message_time > 0.0 and message != "":
		var lines := message.split("\n")
		if lines.size() > MAX_MSG_LINES:
			lines = lines.slice(0, MAX_MSG_LINES)
		var line_h := 30.0
		var h := line_h * lines.size() + 24.0
		var alpha := clampf(message_time, 0.0, 1.0)
		var w := minf(size.x - 24.0, 980.0)
		var box := Rect2((size.x - w) * 0.5, bottom - h - 8.0, w, h)
		draw_rect(box, Color(CONSOLE_BG, 0.94 * alpha))
		draw_rect(Rect2(box.position, Vector2(6.0, box.size.y)), Color(OK_COLOR if message_ok else ERR_COLOR, alpha))
		for i in lines.size():
			var pos := Vector2(box.position.x + 22.0, box.position.y + 34.0 + i * line_h)
			if message_mono:
				for c in lines[i].length():
					draw_char(font, pos + Vector2(c * 15.0, 0.0), lines[i][c], 24, Color(TEXT, alpha))
			else:
				draw_string(font, pos, lines[i], HORIZONTAL_ALIGNMENT_LEFT, w - 34.0, 24, Color(TEXT, alpha))
