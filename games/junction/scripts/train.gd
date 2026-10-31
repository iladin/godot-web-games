class_name Train
extends RefCounted
## A 3-car consist following edge polylines. Main picks each next edge from live switch state.

const CARS := 3
const CAR_GAP := 34.0

var colour: int = 0
var bot_target: int = 0
var from_id: String = "entry"
var to_id: String = "S1"
var path := PackedVector2Array()
var length: float = 0.0
var dist: float = 0.0
var prev_path := PackedVector2Array()
var prev_length: float = 0.0
var age: float = 0.0
var smoke_t: float = 0.0


static func path_length(p: PackedVector2Array) -> float:
	var l := 0.0
	for i in p.size() - 1:
		l += p[i].distance_to(p[i + 1])
	return l


## Returns [position, tangent] at distance d along p (clamped).
static func sample(p: PackedVector2Array, d: float) -> Array:
	d = maxf(d, 0.0)
	for i in p.size() - 1:
		var seg := p[i].distance_to(p[i + 1])
		if d <= seg or i == p.size() - 2:
			var dir := (p[i + 1] - p[i]).normalized()
			return [p[i] + dir * minf(d, seg), dir]
		d -= seg
	return [p[0], Vector2.DOWN]


func set_edge(a: String, b: String) -> void:
	prev_path = path
	prev_length = length
	from_id = a
	to_id = b
	path = Yard.edge_points(a, b)
	length = path_length(path)
	dist = 0.0


func advance(delta: float, speed: float) -> bool:
	dist += speed * delta
	age += delta
	return dist >= length


## [position, tangent, visible] for car i (0 = loco).
func car(i: int) -> Array:
	var d := dist - i * CAR_GAP
	if d >= 0.0:
		var s := sample(path, d)
		return [s[0], s[1], true]
	if prev_path.size() > 1:
		var s2 := sample(prev_path, prev_length + d)
		return [s2[0], s2[1], true]
	return [path[0], Vector2.DOWN, false]
