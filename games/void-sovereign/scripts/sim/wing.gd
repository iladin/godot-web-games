class_name Wing
extends RefCounted
## Cockpit wing commands (VS-007): the player's armed ships in the player's current sector.
## Pure functions over Universe data; no RNG.

const ATTACK := "attack"
const ESCORT := "escort"
const HOLD := "hold"


## Armed Sovereign ships (not the player's own) in `sector`.
static func members(u: Universe, sector: int) -> Array[ShipData]:
	var out: Array[ShipData] = []
	for e: SimEntity in u.ents_in(sector):
		if e is ShipData and e.alive and e.faction == Defs.Faction.PLAYER and e.armed() and not (e as ShipData).is_player:
			out.append(e as ShipData)
	return out


## Issue `order` to the wing; ATTACK needs a live target id. Returns how many ships obeyed.
static func command(u: Universe, sector: int, order: String, target_id: int = 0) -> int:
	var t := u.get_ent(target_id)
	if order == ATTACK and (t == null or not t.alive):
		return 0
	var n := 0
	for s: ShipData in members(u, sector):
		s.order = order
		s.order_sector = sector
		if order == ATTACK:
			s.order_target = t.id
		n += 1
	return n


## One-line HUD status, e.g. "WING 3 · ESCORT".
static func status(u: Universe, sector: int) -> String:
	var ms := members(u, sector)
	if ms.is_empty():
		return "WING none"
	var first := ms[0].order
	for s: ShipData in ms:
		if s.order != first:
			return "WING %d · MIXED" % ms.size()
	var label := "ESCORT" if first == ESCORT else ("HOLD" if first == HOLD else ("ATTACK" if first == ATTACK else first.to_upper()))
	return "WING %d · %s" % [ms.size(), label]
