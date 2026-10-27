class_name ShipData
extends SimEntity
## A ship: data only. AI lives in ship_ai.gd, rendering in space/proxy_factory.gd.

var cls: String = "fighter"
var role: String = "combat"
var speed: float = 200.0
var cargo_cap: int = 0
var cargo: Dictionary = {}
var is_player: bool = false
var sortie: bool = false          # VS-018 First Sortie scout: only the player's wing fights it (OpeningWave.allows)
var hidden: bool = false          # docked or parked on a planet: untargetable

# Orders: idle | move | attack | patrol | escort | hold | trade | mine | raid | goto
var order: String = "idle"
var order_pos: Vector3 = Vector3.ZERO
var order_sector: int = 0
var order_target: int = 0
var route: Array[int] = []
var ai_state: String = ""
var ai_timer: float = 0.0
var plan: Dictionary = {}         # trade plan / mining target
var orbit_sign: float = 1.0


func setup(p_cls: String, p_faction: int) -> void:
	cls = p_cls
	faction = p_faction
	var d: Dictionary = Defs.SHIP[cls]
	role = String(d["role"])
	hull_max = float(d["hull"])
	hull = hull_max
	shield_max = float(d["shield"])
	shield = shield_max
	speed = float(d["speed"])
	dps = float(d["dps"])
	weapon_range = float(d["range"])
	cargo_cap = int(d["cargo"])
	radius = float(d["radius"])
	display_name = String(d["name"])
	orbit_sign = 1.0 if randf() < 0.5 else -1.0


func can_be_damaged() -> bool:
	return not hidden


func cargo_used() -> int:
	var n: int = 0
	for w: String in cargo:
		n += int(cargo[w])
	return n


func cargo_free() -> int:
	return cargo_cap - cargo_used()


func value() -> float:
	return float(Defs.SHIP[cls]["cost"]) * hull_frac()
