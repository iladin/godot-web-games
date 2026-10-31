class_name EchoSupport
extends RefCounted
## Input-action registration and best-score persistence (user:// -> IndexedDB on web).


static func register_actions() -> void:
	var map := {
		"pad_0": [KEY_UP, KEY_W, KEY_I], "pad_1": [KEY_RIGHT, KEY_D, KEY_L],
		"pad_2": [KEY_DOWN, KEY_S, KEY_K], "pad_3": [KEY_LEFT, KEY_A, KEY_J],
		"start": [KEY_SPACE, KEY_ENTER], "pause": [KEY_ESCAPE, KEY_P]}
	for action: String in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key: Key in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)


static func load_best(path: String) -> int:
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return 0
	return int(cfg.get_value("save", "best", 0))


static func save_best(path: String, value: int) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("save", "best", value)
	cfg.save(path)
