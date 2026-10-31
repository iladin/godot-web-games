class_name SaveData
extends RefCounted
## Best course total (relative to par, 99 = none) and best hole-in-one count, in user://save.cfg.

const PATH := "user://save.cfg"


static func load_best() -> Vector2i:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return Vector2i(99, 0)
	return Vector2i(int(cfg.get_value("score", "best_rel", 99)), int(cfg.get_value("score", "best_hole_in_ones", 0)))


static func save_best(best_rel: int, best_hios: int) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("score", "best_rel", best_rel)
	cfg.set_value("score", "best_hole_in_ones", best_hios)
	cfg.save(PATH)
