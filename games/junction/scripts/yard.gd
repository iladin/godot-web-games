class_name Yard
extends RefCounted
## Pure track graph + rules for Junction. No nodes, no drawing: easy to unit test.

# Ramp tunables (by trains docked / correct deliveries)
const SPEED_START := 110.0
const SPEED_PER_TRAIN := 3.5
const SPEED_MAX := 270.0
const SPAWN_START := 4.2
const SPAWN_PER_TRAIN := 0.07
const SPAWN_MIN := 1.5
const COLOURS_START := 3
const UNLOCK_4_AT := 6
const UNLOCK_5_AT := 16
const COMBO_STEP := 4
const COMBO_MAX := 5
## Order in which stations (= colours) become active; spreads load over all switches.
const UNLOCK_ORDER: Array[int] = [0, 2, 4, 1, 3]
const SWITCH_IDS: Array[String] = ["S1", "S2", "S3", "S4"]

const NODES: Dictionary = {
	"entry": {"pos": Vector2(360, 150), "kind": "entry", "left": "S1", "right": "S1", "station": -1},
	"S1": {"pos": Vector2(360, 330), "kind": "switch", "left": "S2", "right": "S3", "station": -1},
	"S2": {"pos": Vector2(200, 560), "kind": "switch", "left": "st0", "right": "S4", "station": -1},
	"S4": {"pos": Vector2(300, 800), "kind": "switch", "left": "st1", "right": "st2", "station": -1},
	"S3": {"pos": Vector2(520, 560), "kind": "switch", "left": "st3", "right": "st4", "station": -1},
	"st0": {"pos": Vector2(90, 1100), "kind": "station", "left": "", "right": "", "station": 0},
	"st1": {"pos": Vector2(230, 1100), "kind": "station", "left": "", "right": "", "station": 1},
	"st2": {"pos": Vector2(370, 1100), "kind": "station", "left": "", "right": "", "station": 2},
	"st3": {"pos": Vector2(510, 1100), "kind": "station", "left": "", "right": "", "station": 3},
	"st4": {"pos": Vector2(650, 1100), "kind": "station", "left": "", "right": "", "station": 4},
}


static func pos(id: String) -> Vector2:
	return NODES[id]["pos"]


static func kind(id: String) -> String:
	return NODES[id]["kind"]


static func station_pos(station: int) -> Vector2:
	return pos("st%d" % station)


static func edge_points(from_id: String, to_id: String) -> PackedVector2Array:
	var a: Vector2 = pos(from_id)
	return PackedVector2Array([a, Vector2(a.x, a.y + 60.0), pos(to_id)])


static func edges() -> Array:
	var out: Array = []
	for id: String in NODES:
		var n: Dictionary = NODES[id]
		if n["kind"] == "station":
			continue
		out.append([id, n["left"]])
		if n["kind"] == "switch":
			out.append([id, n["right"]])
	return out


static func next_node(node_id: String, switches: Dictionary) -> String:
	var n: Dictionary = NODES[node_id]
	if n["kind"] == "switch":
		return n["right"] if bool(switches.get(node_id, false)) else n["left"]
	if n["kind"] == "entry":
		return "S1"
	return ""


static func destination(switches: Dictionary) -> int:
	var id := "entry"
	while kind(id) != "station":
		id = next_node(id, switches)
	return int(NODES[id]["station"])


## Ordered route from entry to a station: Array of {id: String, right: bool}.
static func route(target: int) -> Array:
	var out: Array = []
	_find("entry", target, out)
	return out


static func _find(id: String, target: int, acc: Array) -> bool:
	var n: Dictionary = NODES[id]
	if n["kind"] == "station":
		return int(n["station"]) == target
	if n["kind"] == "entry":
		return _find("S1", target, acc)
	for side in [false, true]:
		acc.append({"id": id, "right": side})
		if _find(n["right"] if side else n["left"], target, acc):
			return true
		acc.pop_back()
	return false


## Switch ids that must change for a train entering now to reach target.
static func flips_needed(switches: Dictionary, target: int) -> Array[String]:
	var out: Array[String] = []
	for step: Dictionary in route(target):
		if bool(switches.get(step["id"], false)) != bool(step["right"]):
			out.append(step["id"])
	return out


## 1 = switch must be right, 0 = left, -1 = switch is not on the route.
static func wants_right(switch_id: String, target: int) -> int:
	for step: Dictionary in route(target):
		if step["id"] == switch_id:
			return 1 if step["right"] else 0
	return -1


static func spawn_interval(delivered: int) -> float:
	return maxf(SPAWN_MIN, SPAWN_START - SPAWN_PER_TRAIN * delivered)


static func train_speed(delivered: int) -> float:
	return minf(SPEED_MAX, SPEED_START + SPEED_PER_TRAIN * delivered)


static func active_colours(correct: int) -> int:
	if correct >= UNLOCK_5_AT:
		return 5
	if correct >= UNLOCK_4_AT:
		return 4
	return COLOURS_START


static func is_active(station: int, correct: int) -> bool:
	return UNLOCK_ORDER.find(station) < active_colours(correct)


static func active_stations(correct: int) -> Array[int]:
	var out: Array[int] = []
	for i in active_colours(correct):
		out.append(UNLOCK_ORDER[i])
	return out


static func multiplier(combo: int) -> int:
	return mini(1 + combo / COMBO_STEP, COMBO_MAX)


static func pick_colour(correct: int, delivered: int, last_colour: int, repeat_early: float, repeat_late: float, late_at: int) -> int:
	var act := Yard.active_stations(correct)
	var chance := repeat_late if delivered >= late_at else repeat_early
	if last_colour in act and randf() < chance:
		return last_colour
	var pool: Array[int] = []
	for s in act:
		if s != last_colour or act.size() == 1:
			pool.append(s)
	return pool[randi_range(0, pool.size() - 1)]
