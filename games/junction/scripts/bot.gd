extends RefCounted
## Autoplay bot: presses the same flip function a player's taps/keys do.


static func step(m: Node2D) -> void:
	for id in Yard.SWITCH_IDS:
		var best_t: Train = null
		var best_rem: float = 1e9
		for t in m.trains:
			var rem: float = t.length - t.dist
			if t.to_id == id and t.age > m.AUTOPLAY_REACTION and rem < best_rem:
				best_t = t
				best_rem = rem
		if best_t == null or best_rem > m.AUTOPLAY_LOOKAHEAD:
			continue
		var want := Yard.wants_right(id, best_t.bot_target)
		if want >= 0 and bool(m.switches[id]) != (want == 1):
			m._try_flip(id)
