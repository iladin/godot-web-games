extends Node
## Falsify controls: turns touch, mouse and keys into lab commands. State lives in main.gd (m).

const RESTART_DELAY := 0.6   # same as main.gd
const Lab := preload("res://scripts/lab.gd")
const Rules := preload("res://scripts/rules.gd")

var m: Node2D  # main.gd
var fresh: bool = false   # the cursor just auto-advanced, so a separator key is already done


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_click(event.position)
	elif event is InputEventKey and event.pressed:
		_key(event as InputEventKey)


func _advance_screen() -> bool:
	if m.paused:
		m.paused = false
		return true
	match m.lab.phase:
		Lab.Phase.TITLE:
			m.bridge.run_command("start", false)
			return true
		Lab.Phase.ROUND_DONE:
			if m.state_time > RESTART_DELAY * 0.5:
				m.bridge.run_command("next", false)
			return true
		Lab.Phase.GAME_OVER, Lab.Phase.WIN:
			if m.state_time > RESTART_DELAY:
				m.bridge.run_command("start", false)
			return true
	return false


func _click(pos: Vector2) -> void:
	if _advance_screen():
		return
	m.build_buttons(m.layout())
	for i in range(m.buttons.size() - 1, -1, -1):
		var b: Dictionary = m.buttons[i]
		if not (b.rect as Rect2).has_point(pos):
			continue
		var id: String = b.id
		if id.begins_with("cand:"):
			var k := int(id.substr(5))
			m.selected = -1 if m.selected == k or not m.lab.alive[k] else k
		elif id == "name":
			_name_selected()
		elif id.begins_with("slot:"):
			m.cur_slot = int(id.substr(5))
			m.pending = false
			fresh = false
		elif id.begins_with("key:"):
			_type_digit(int(id.substr(4)))
		elif id == "del":
			_backspace()
		elif id == "clr":
			m.slots = [-1, -1, -1]
			m.cur_slot = 0
			m.pending = false
		elif id == "test" and b.enabled:
			_submit_test()
		return


func _key(k: InputEventKey) -> void:
	var code := k.keycode
	if m.lab.phase != Lab.Phase.TESTING or m.paused:
		if code in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER] and not k.echo:
			_advance_screen()
		return
	if code >= KEY_0 and code <= KEY_9:
		_type_digit(code - KEY_0)
	elif code >= KEY_KP_0 and code <= KEY_KP_9:
		_type_digit(code - KEY_KP_0)
	elif code in [KEY_SPACE, KEY_COMMA, KEY_TAB]:
		# "3 6 9": digits auto-advance, so a separator right after one is a no-op
		if m.pending or not fresh:
			m.cur_slot = mini(m.cur_slot + 1, 2)
		m.pending = false
		fresh = false
	elif code == KEY_RIGHT:
		m.pending = false
		fresh = false
		m.cur_slot = mini(m.cur_slot + 1, 2)
	elif code == KEY_LEFT:
		m.pending = false
		fresh = false
		m.cur_slot = maxi(m.cur_slot - 1, 0)
	elif code == KEY_UP or code == KEY_DOWN:
		m.pending = false
		var v: int = m.slots[m.cur_slot] + (1 if code == KEY_UP else -1)
		m.slots[m.cur_slot] = clampi(v, Rules.LO, Rules.HI)
	elif code == KEY_BACKSPACE:
		_backspace()
	elif code == KEY_ENTER or code == KEY_KP_ENTER:
		if m.selected >= 0:
			_name_selected()
		else:
			_submit_test()
	elif code == KEY_ESCAPE:
		m.selected = -1
	elif code >= KEY_A and code <= KEY_L and not k.echo:
		var idx := code - KEY_A
		if idx < m.lab.candidates.size() and m.lab.alive[idx]:
			m.selected = -1 if m.selected == idx else idx


func _type_digit(d: int) -> void:
	m.selected = -1
	var before: int = m.cur_slot
	if m.pending and m.slots[m.cur_slot] == 1 and 10 + d <= Rules.HI:
		m.slots[m.cur_slot] = 10 + d
		m.pending = false
		m.cur_slot = mini(m.cur_slot + 1, 2)
		fresh = m.cur_slot != before
		return
	if m.pending and m.cur_slot < 2:
		m.cur_slot += 1
		before = m.cur_slot
	m.pending = false
	m.slots[m.cur_slot] = d
	if d == 1:
		m.pending = true
	else:
		m.cur_slot = mini(m.cur_slot + 1, 2)
	fresh = m.cur_slot != before


func _backspace() -> void:
	m.pending = false
	if m.slots[m.cur_slot] < 0 and m.cur_slot > 0:
		m.cur_slot -= 1
	m.slots[m.cur_slot] = -1


func _submit_test() -> void:
	if m.slots[0] < 0 or m.slots[1] < 0 or m.slots[2] < 0:
		m.bridge.show_message("Fill in all three numbers first.", false)
		return
	m.bridge.run_command("test %d %d %d" % [m.slots[0], m.slots[1], m.slots[2]])


func _name_selected() -> void:
	if m.selected >= 0:
		m.bridge.run_command("name %s" % Lab.LETTERS[m.selected])
