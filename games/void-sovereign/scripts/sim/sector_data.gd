class_name SectorData
extends RefCounted
## Static-ish sector info: gates, planet, asteroid fields.

var idx: int = 0
var name: String = ""
var map_pos: Vector2 = Vector2.ZERO
var gates: Array[Dictionary] = []      # {pos: Vector3, to: int}
var fields: Array[Dictionary] = []     # {pos: Vector3, radius: float}
var planet_pos: Vector3 = Vector3.ZERO
var planet_name: String = ""
var planet_state: String = "union"     # union | hive | colony
var level: int = 0
var rng_seed: int = 0


func gate_to(other: int) -> Dictionary:
	for g: Dictionary in gates:
		if int(g["to"]) == other:
			return g
	return {}


func landable() -> bool:
	return planet_state == "hive"
