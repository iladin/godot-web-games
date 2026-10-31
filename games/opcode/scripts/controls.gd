extends Node
## Opcode controls: turns touch, mouse and keys into game commands. State lives in main.gd (m).

const Game := preload("res://scripts/game.gd")
const VM := preload("res://scripts/vm.gd")
const Puzzles := preload("res://scripts/puzzles.gd")

const SELECT_COLS := 4   # same as main.gd

var m: Node2D  # main.gd


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_click(event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			m.scroll += 1
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			m.scroll = maxi(0, m.scroll - 1)
	elif event is InputEventKey and event.pressed:
		_key(event as InputEventKey)


func _click(pos: Vector2) -> void:
	if m.paused:
		m.paused = false
		return
	if m.show_manual:
		m.show_manual = false
		return
	match m.game.screen:
		Game.Screen.TITLE, Game.Screen.WIN:
			if m.state_time > 0.4:
				m._act("start")
			return
	m.build_buttons(m.layout())
	for b in m.buttons:
		if (b.rect as Rect2).has_point(pos):
			if b.enabled:
				_press(str(b.id))
			return


func _press(id: String) -> void:
	if id.begins_with("open:"):
		m.bridge.run_command("open %d" % (int(id.substr(5)) + 1))
	elif id == "manual":
		m.show_manual = true
	elif id == "menu":
		m._act("menu")
	elif id == "dismiss":
		m._act("ok")
	elif id == "nextpz":
		m._act("ok")
		m.bridge.run_command("next")
	elif id.begins_with("line:"):
		var k := int(id.substr(5))
		m.bridge.run_command("cursor %d" % (mini(k, m.game.program.size() - 1) + 1), false)
	elif id.begins_with("op:"):
		var op := id.substr(3)
		m.pending_num = ""
		if VM.OPS[op] == "":
			m.pending_op = ""
			m.bridge.run_command("insert " + op, false)
		else:
			m.pending_op = "" if m.pending_op == op else op
	elif id == "arg:CANCEL":
		m.pending_op = ""
		m.pending_num = ""
	elif id == "arg:OK":
		_commit_operand(m.pending_num if m.pending_num != "" else "0")
	elif id == "arg:<":
		m.pending_num = m.pending_num.left(m.pending_num.length() - 1)
		if m.pending_num == "-":
			m.pending_num = ""
	elif id == "arg:+/-":
		m.pending_num = m.pending_num.substr(1) if m.pending_num.begins_with("-") else "-" + m.pending_num
	elif id.begins_with("arg:"):
		_commit_operand(id.substr(4))
	elif id.begins_with("digit:"):
		var cand: String = m.pending_num + id.substr(6)
		if absi(int(cand)) <= VM.LIT_MAX:
			m.pending_num = cand
	elif id in ["up", "down"]:
		m._act(id)
	elif id == "del":
		m.bridge.run_command("delete", false)
	elif id == "step":
		m.bridge.run_command("step", false)
	elif id == "run":
		m._act("stop")
		m.bridge.run_command("animate", false)
	elif id == "fast":
		m.bridge.run_command("run")
	elif id == "stop":
		m._act("stop")


func _commit_operand(arg: String) -> void:
	if m.pending_op == "":
		return
	var res: Dictionary = m.bridge.run_command("insert %s %s" % [m.pending_op, arg], false)
	if not res.ok:
		m.bridge.show_message(str(res.msg), false)
	m.pending_op = ""
	m.pending_num = ""


func _key(k: InputEventKey) -> void:
	if m.paused:
		m.paused = false
		return
	if m.show_manual:
		m.show_manual = false
		return
	var code := k.keycode
	match m.game.screen:
		Game.Screen.TITLE, Game.Screen.WIN:
			if code in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER] and m.state_time > 0.4:
				m._act("start")
			return
		Game.Screen.SELECT:
			_select_key(code)
			return
	if not m.game.result.is_empty():
		if code in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] and m.game.result.ok and m.game.puzzle + 1 < Puzzles.count():
			_press("nextpz")
		elif code in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE]:
			m._act("ok")
		return
	match code:
		KEY_ENTER, KEY_KP_ENTER:
			if k.shift_pressed:
				m.bridge.run_command("step", false)
			elif k.ctrl_pressed:
				m.bridge.run_command("run")
			elif m.buffer.strip_edges() != "":
				var res: Dictionary = m.bridge.run_command("insert " + m.buffer, false)
				if res.ok:
					m.buffer = ""
				else:
					m.bridge.show_message(str(res.msg), false)
			else:
				_press("run")
		KEY_BACKSPACE:
			if m.buffer != "":
				m.buffer = m.buffer.left(m.buffer.length() - 1)
			elif m.game.machine.is_empty():
				m.bridge.run_command("delete", false)
		KEY_UP:
			m._act("up")
		KEY_DOWN:
			m._act("down")
		KEY_ESCAPE:
			if m.buffer != "" or m.pending_op != "":
				m.buffer = ""
				m.pending_op = ""
			else:
				m._act("stop")
		_:
			var u := k.unicode
			if u >= 32 and u < 127 and m.buffer.length() < 24 and char(u) != "/":
				m.buffer += char(u).to_upper()


func _select_key(code: Key) -> void:
	match code:
		KEY_LEFT:
			m.select_focus = maxi(0, m.select_focus - 1)
		KEY_RIGHT:
			m.select_focus = mini(Puzzles.count() - 1, m.select_focus + 1)
		KEY_UP:
			m.select_focus = maxi(0, m.select_focus - SELECT_COLS)
		KEY_DOWN:
			m.select_focus = mini(Puzzles.count() - 1, m.select_focus + SELECT_COLS)
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			m.bridge.run_command("open %d" % (m.select_focus + 1))
		KEY_M:
			m.show_manual = true
