class_name Controls
extends RefCounted
## Registers keyboard actions in code (CLAUDE.md: don't hand-edit [input]).

const KEYS: Dictionary = {
	"thr_up": [KEY_W], "thr_dn": [KEY_S], "roll_l": [KEY_Q], "roll_r": [KEY_E],
	"strafe_l": [KEY_A], "strafe_r": [KEY_D],
	"boost": [KEY_SHIFT], "fire": [KEY_SPACE], "target": [KEY_R], "act": [KEY_F],
	"map": [KEY_M, KEY_TAB], "stop": [KEY_X], "travel": [KEY_T], "fleet_attack": [KEY_G],
	"move_f": [KEY_W], "move_b": [KEY_S], "move_l": [KEY_A], "move_r": [KEY_D],
	"jump": [KEY_SPACE], "sprint": [KEY_SHIFT], "reload": [KEY_R],
	"pitch_up": [KEY_UP], "pitch_dn": [KEY_DOWN], "yaw_l": [KEY_LEFT], "yaw_r": [KEY_RIGHT],
	"pause": [KEY_P], "skip_hints": [KEY_H],
}


static func register() -> void:
	for action: String in KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for k: int in KEYS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k as Key
			InputMap.action_add_event(action, ev)
