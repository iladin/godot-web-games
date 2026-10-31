extends RefCounted

const PATH := "user://save.cfg"


# --- Save --------------------------------------------------------------------------
static func load_best() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return 0
	return int(cfg.get_value("score", "best", 0))


static func save_best(value: int) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("score", "best", value)
	cfg.save(PATH)
