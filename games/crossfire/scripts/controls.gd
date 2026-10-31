extends Node
## Crossfire controls: turns touch, mouse and keys into tactics commands. State lives in main.gd (m).

const RESTART_DELAY := 0.8   # same as main.gd
const T := preload("res://scripts/tactics.gd")

var m: Node2D  # main.gd


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		m.hover_hex = m.px_hex(m.layout(), event.position)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_click(event.position)
	elif event is InputEventKey and event.pressed and not event.echo:
		_key(event as InputEventKey)


func _start_if_ready() -> bool:
	if m.paused:
		m.paused = false
		return true
	if m.game.phase == T.Phase.PLAYER:
		return false
	if m.game.phase == T.Phase.TITLE or m.state_time > RESTART_DELAY:
		m.bridge.run_command("start", false)
	return true


func _click(pos: Vector2) -> void:
	if _start_if_ready():
		return
	var L: Dictionary = m.layout()
	m.build_buttons(L)
	for b in m.buttons:
		if (b.rect as Rect2).has_point(pos):
			if b.id == "end":
				m.bridge.run_command("end", false)
			elif b.id == "mode":
				m.shove_mode = not m.shove_mode
			return
	var h: Vector2i = m.px_hex(L, pos)
	if not m.game.tiles.has(h):
		return
	var pp: Vector2i = m.game.player().pos
	var d := T.line_dir(pp, h)
	var j: int = m.game.unit_at(h)
	if d >= 0 and T.hex_dist(pp, h) == 1:
		if j > 0:
			_do("shove", d)
		else:
			_do("move", d)
	elif j > 0:
		var u: Dictionary = m.game.units[j]
		m.bridge.show_message("#%d %s (%d hp): %s" % [j, u.kind, u.hp, m.game.describe_intent(u)], true)
	elif h == m.game.player().pos:
		m.shove_mode = not m.shove_mode


func _do(verb: String, d: int) -> void:
	var res: Dictionary = m.bridge.run_command("%s %s" % [verb, T.DIR_NAMES[d]], false)
	if not res.ok:
		m.bridge.show_message(str(res.msg), false)
	m.shove_mode = false


const KEY_DIRS := {KEY_D: 0, KEY_E: 1, KEY_W: 2, KEY_A: 3, KEY_Z: 4, KEY_X: 5,
	KEY_KP_6: 0, KEY_KP_9: 1, KEY_KP_7: 2, KEY_KP_4: 3, KEY_KP_1: 4, KEY_KP_3: 5}


func _key(k: InputEventKey) -> void:
	if k.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		if _start_if_ready():
			return
		m.bridge.run_command("end", false)
		return
	if m.game.phase != T.Phase.PLAYER:
		return
	if k.keycode == KEY_F or k.keycode == KEY_S:
		m.shove_mode = not m.shove_mode
	elif k.keycode == KEY_ESCAPE:
		m.shove_mode = false
	elif KEY_DIRS.has(k.keycode):
		var d: int = KEY_DIRS[k.keycode]
		_do("shove" if (k.shift_pressed or m.shove_mode) else "move", d)
