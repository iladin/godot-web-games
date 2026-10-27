extends SceneTree
## VS-029 probe: bash: godot --headless --path games/void-sovereign --script res://scripts/tools/breach_probe.gd -- --seeds=9
## Per seed, two scenarios: "idle" (player does nothing) and "bare" (starting wing sold off), "defended" (2 fighters + 1 Defense Platform at the HQ).
## Prints spawn time of the Breach, its size, min HQ hull fraction until t=900 s.

var HORIZON := 700.0

func _init() -> void:
	var seeds := 9
	var first := 0
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--seeds="):
			seeds = int(a.get_slice("=", 1))
		elif a.begins_with("--first="):
			first = int(a.get_slice("=", 1))
	for i in range(first, first + seeds):
		for mode: String in ["idle", "bare", "defended"]:
			print("BREACH " + JSON.stringify(_run(101 + i * 17, mode)))
	quit()


func _run(rng_seed: int, mode: String) -> Dictionary:
	var u := Universe.new()
	u.setup(rng_seed)
	u.player_ship.hidden = true
	if mode == "bare":
		for e: SimEntity in u.entities.values():
			if e is ShipData and e.faction == Defs.Faction.PLAYER and (e as ShipData).role == "combat" and not (e as ShipData).is_player:
				e.alive = false
	if mode == "defended":
		u.spawn_station("defense", Defs.Faction.PLAYER, u.hq.sector, u.hq.pos + Vector3(-900, 0, 700))
	var seen_at := -1.0
	var minf := 1.0
	var size := 0
	var smin := 1.0
	while u.time < HORIZON and not u.over:
		u.step(0.05)
		if seen_at < 0.0 and u.director.breach_count > 0:
			seen_at = u.time
			for e: SimEntity in u.ents_in(u.hq.sector):
				if e is ShipData and e.faction == Defs.Faction.HIVE and e.order == "raid" and e.order_target == u.hq.id:
					size += 1
		minf = minf(minf, u.hq.hull / u.hq.hull_max)
		smin = minf(smin, u.hq.shield_frac())
	return {"seed": rng_seed, "mode": mode, "spawn": snappedf(seen_at, 0.1), "size": size, "hq_min": snappedf(minf, 0.01), "shield_min": snappedf(smin, 0.01), "lost": u.over}
