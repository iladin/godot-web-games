class_name SimEntity
extends RefCounted
## Anything that exists in a sector and can be shot: ships and stations.

var id: int = 0
var faction: int = Defs.Faction.UNION
var sector: int = 0
var pos: Vector3 = Vector3.ZERO
var vel: Vector3 = Vector3.ZERO
var hull: float = 100.0
var hull_max: float = 100.0
var shield: float = 0.0
var shield_max: float = 0.0
var dps: float = 0.0
var weapon_range: float = 0.0
var radius: float = 10.0
var alive: bool = true
var is_station: bool = false
var display_name: String = ""
var target_id: int = 0
var retarget_cd: float = 0.0
var fire_cd: float = 0.0
var since_hit: float = 99.0
var last_attacker: int = 0


## Applies damage; returns true if this killed the entity.
func take_damage(amount: float, attacker_id: int = 0) -> bool:
	if not alive or not can_be_damaged():
		return false
	since_hit = 0.0
	last_attacker = attacker_id
	var absorbed := minf(shield, amount)
	shield -= absorbed
	hull -= amount - absorbed
	if hull <= 0.0:
		hull = 0.0
		alive = false
		return true
	return false


func can_be_damaged() -> bool:
	return true


func regen(delta: float) -> void:
	since_hit += delta
	if since_hit > Defs.SHIELD_DELAY and shield < shield_max:
		shield = minf(shield_max, shield + shield_max * Defs.SHIELD_REGEN * delta)


func armed() -> bool:
	return dps > 0.0


func hull_frac() -> float:
	return hull / maxf(hull_max, 1.0)


func shield_frac() -> float:
	return shield / maxf(shield_max, 1.0) if shield_max > 0.0 else 0.0
