class_name RunSave
extends RefCounted
## VS-027: file I/O for the run save. The data layer is SaveGame (VS-026); this only reads and writes
## JSON text at a path. Autoplay/screenshot runs use AUTOPLAY_PATH so they never touch a player's real save.

const PATH := "user://run.save"
const AUTOPLAY_PATH := "user://run_autoplay.save"
const TMP_EXT := ".tmp"
const BAK_EXT := ".bak"


## Atomic write: JSON goes to <path>.tmp, is read back and parsed, and only then replaces <path>.
## The previous good file is kept as <path>.bak. A bad tmp is discarded and never touches a good save.
static func write(u: Universe, path: String = PATH) -> bool:
	var tmp := path + TMP_EXT
	var bak := path + BAK_EXT
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	var ok := f.store_string(JSON.stringify(SaveGame.capture(u)))
	f.close()
	if not ok or not _parses(tmp):
		_remove(tmp)
		return false
	var main_ok := _parses(path)
	var abs_main := ProjectSettings.globalize_path(path)
	if main_ok:
		_remove(bak)
		if DirAccess.rename_absolute(abs_main, ProjectSettings.globalize_path(bak)) != OK:
			_remove(tmp)
			return false
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), abs_main) != OK:
		if main_ok:   # put the previous save back
			DirAccess.rename_absolute(ProjectSettings.globalize_path(bak), abs_main)
		_remove(tmp)
		return false
	return true


## The restored Universe, or null when neither the file nor its .bak is a valid save.
static func load_universe(path: String = PATH) -> Universe:
	var u := _load_one(path)
	if u == null:
		u = _load_one(path + BAK_EXT)
	return u


static func _load_one(path: String) -> Universe:
	if not FileAccess.file_exists(path):
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		return null
	return SaveGame.restore(parsed as Dictionary)


## True when the file exists and holds a JSON object with a version field.
static func _parses(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed is Dictionary and (parsed as Dictionary).has("version")


static func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## Run time (seconds) of a valid save, or -1.0 when there is none.
static func peek_time(path: String = PATH) -> float:
	var u := load_universe(path)
	if u == null:
		return -1.0
	var t := u.time
	u.director = null   # break the Universe <-> Director reference cycle
	return t


static func delete(path: String = PATH) -> void:
	for p in [path, path + BAK_EXT, path + TMP_EXT]:
		_remove(p)
