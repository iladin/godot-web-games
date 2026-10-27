class_name RunSave
extends RefCounted
## VS-027: file I/O for the run save. The data layer is SaveGame (VS-026); this only reads and writes
## JSON text at a path. Autoplay/screenshot runs use AUTOPLAY_PATH so they never touch a player's real save.

const PATH := "user://run.save"
const AUTOPLAY_PATH := "user://run_autoplay.save"


static func write(u: Universe, path: String = PATH) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(SaveGame.capture(u)))
	f.close()
	return true


## The restored Universe, or null when the file is missing, unreadable, corrupt or from another version.
static func load_universe(path: String = PATH) -> Universe:
	if not FileAccess.file_exists(path):
		return null
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if not parsed is Dictionary:
		return null
	return SaveGame.restore(parsed as Dictionary)


## Run time (seconds) of a valid save, or -1.0 when there is none.
static func peek_time(path: String = PATH) -> float:
	var u := load_universe(path)
	if u == null:
		return -1.0
	var t := u.time
	u.director = null   # break the Universe <-> Director reference cycle
	return t


static func delete(path: String = PATH) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
