extends SceneTree
## Headless balance telemetry for the AI studio (run via scripts/studio/balance.sh).
## Simulates the whole cluster with no rendering and prints one BALANCE_JSON line per seed
## plus a BALANCE_SUMMARY line with medians.
## Args (after --): --minutes=30 --seeds=3 --policy=passive|economic --first=0
## --first=N skips the first N seeds of the fixed list (seed = SEED_BASE + i * 17), so a
## 6-seed run can be split into two calls: --seeds=3 --first=0 and --seeds=3 --first=3.
## A/B and robustness switches (harness-only; game defaults untouched; omitted = identical numbers):
##   --perturb=N  burn N extra draws of the global randf() stream once, right after the step that
##                reaches t = PERTURB_AT (60 s) (same as S0009 QA's balance_nw.gd).
##                The global stream (seeded in Universe.setup) is chaotic: use this to check that
##                a result survives noise, not just one lucky trajectory.
##   --nowave     disable the VS-018 opening wave (marks it CLEARED before the first step).
##   --repair-reserve=N  economic policy repairs the HQ when hull < REPAIR_BELOW (80%) and credits > N
##                (default REPAIR_RESERVE 25000; spends only the credits above N). Passive never repairs.
##   --wound=F    force the HQ to F (0..1) of max hull once at WOUND_AT (300 s), any policy: exercises the
##                repair path and the VS-050 penalty, since wounds do not occur organically yet (VS-051).
## 9-seed medians + IQR: scripts/studio/balance_gate.sh.

const DT := 0.05
const PERTURB_AT := 60.0       # sim seconds; when --perturb=N burns its N global randf() draws
const CHECKPOINTS: Array[int] = [5, 10, 20, 30]
const SEED_BASE := 101
const ECON_TICK := 30.0
const RESERVE := 3000.0
const REPAIR_BELOW := 0.8       # econ policy repairs the HQ below this hull fraction...
const REPAIR_RESERVE := 25000.0 # ...if credits exceed this reserve (--repair-reserve=N overrides)
const WOUND_AT := 300.0         # sim seconds; when --wound=F forces the HQ hull
const DEFENSE_AFTER := 600.0    # econ policy builds a Defense Platform at HQ after 10 min...
const DEFENSE2_AFTER := 1080.0  # ...and a second one after 18 min


func _init() -> void:
	var minutes := 30
	var seeds := 3
	var policy := "passive"
	var first := 0
	var perturb := 0
	var nowave := false
	var wound := -1.0
	var reserve := REPAIR_RESERVE
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--minutes="):
			minutes = int(a.get_slice("=", 1))
		elif a.begins_with("--seeds="):
			seeds = int(a.get_slice("=", 1))
		elif a.begins_with("--policy="):
			policy = a.get_slice("=", 1)
		elif a.begins_with("--first="):
			first = maxi(0, int(a.get_slice("=", 1)))
		elif a.begins_with("--perturb="):
			perturb = maxi(0, int(a.get_slice("=", 1)))
		elif a.begins_with("--wound="):
			wound = clampf(float(a.get_slice("=", 1)), 0.01, 1.0)
		elif a.begins_with("--repair-reserve="):
			reserve = float(a.get_slice("=", 1))
		elif a == "--nowave":
			nowave = true
	var results: Array[Dictionary] = []
	for i in range(first, first + seeds):
		var r := _run(SEED_BASE + i * 17, minutes, policy, perturb, nowave, wound, reserve)
		results.append(r)
		print("BALANCE_JSON " + JSON.stringify(r))
	print("BALANCE_SUMMARY " + JSON.stringify(_summary(results, policy, minutes)))
	quit()


func _run(rng_seed: int, minutes: int, policy: String, perturb: int = 0, nowave: bool = false, wound: float = -1.0, reserve: float = REPAIR_RESERVE) -> Dictionary:
	var u := Universe.new()
	u.setup(rng_seed)
	if nowave:
		u.director.opening.state = OpeningWave.State.CLEARED
	u.player_ship.hidden = true   # the pilot is "away"; only the economy and fleet act
	var r: Dictionary = {"seed": rng_seed, "policy": policy, "hq_lost_at": -1.0, "first_raid_at": -1.0, "union_collapse_at": -1.0, "nests_left": 2}
	var econ_t := 0.0
	var next_cp := 0
	var perturb_done := perturb <= 0
	var wound_done := wound < 0.0
	var repaired := 0.0   # credits spent on HQ repair
	while u.time < float(minutes) * 60.0:
		u.step(DT)
		if not perturb_done and u.time >= PERTURB_AT:
			perturb_done = true
			for k in perturb:
				randf()
		if not wound_done and u.time >= WOUND_AT and u.hq != null and u.hq.alive:
			wound_done = true
			u.hq.hull = minf(u.hq.hull, u.hq.hull_max * wound)
		if policy == "economic":
			econ_t -= DT
			if econ_t <= 0.0:
				econ_t = ECON_TICK
				repaired += repair_policy(u, reserve)
				_economic(u)
		if float(r["first_raid_at"]) < 0.0 and u.director.raid_count > 0:
			r["first_raid_at"] = snappedf(u.time / 60.0, 0.1)
		var c := _counts(u)
		if float(r["union_collapse_at"]) < 0.0 and int(c["union_ships"]) == 0:
			r["union_collapse_at"] = snappedf(u.time / 60.0, 0.1)
		if next_cp < CHECKPOINTS.size() and u.time >= float(CHECKPOINTS[next_cp]) * 60.0:
			var cp := CHECKPOINTS[next_cp]
			r["net_worth_%d" % cp] = int(u.net_worth())
			r["credits_%d" % cp] = int(u.credits)
			r["hive_ships_%d" % cp] = c["hive_ships"]
			r["union_ships_%d" % cp] = c["union_ships"]
			r["union_stations_%d" % cp] = c["union_stations"]
			r["player_ships_%d" % cp] = c["player_ships"]
			next_cp += 1
		if u.over:
			if u.hq == null or not u.hq.alive:
				r["hq_lost_at"] = snappedf(u.time / 60.0, 0.1)
				# A lost HQ ends the run: later checkpoints count as zero net worth, so
				# medians are not biased towards the surviving seeds.
				for k in range(next_cp, CHECKPOINTS.size()):
					if CHECKPOINTS[k] <= minutes:
						r["net_worth_%d" % CHECKPOINTS[k]] = 0
			break
	r["nests_left"] = u.alive_nests().size()
	r["repair_spent"] = int(repaired)
	if u.hq != null and u.hq.alive:
		r["hq_hull_end"] = snappedf(u.hq.hull_frac(), 0.01)
	r["raids"] = u.director.raid_count
	r["kills"] = u.kills
	r["minutes_simulated"] = snappedf(u.time / 60.0, 0.1)
	u.director = null
	return r


## VS-052: the economic player repairs a wounded HQ from the dock (Universe.repair_station): hull below
## REPAIR_BELOW and credits above `reserve`; only the credits above the reserve are spent.
## Returns credits spent. Static so selftest can exercise the exact policy.
static func repair_policy(u: Universe, reserve: float) -> float:
	var hq := u.hq
	if hq == null or not hq.alive or hq.hull_frac() >= REPAIR_BELOW or u.credits <= reserve:
		return 0.0
	var before := u.credits
	u.credits = before - reserve
	u.repair_station(hq)
	var spent := (before - reserve) - u.credits
	u.credits += reserve
	return spent


func _counts(u: Universe) -> Dictionary:
	var c := {"hive_ships": 0, "union_ships": 0, "union_stations": 0, "player_ships": 0}
	for e: SimEntity in u.entities.values():
		if not e.alive:
			continue
		if e is ShipData:
			match e.faction:
				Defs.Faction.HIVE:
					c["hive_ships"] += 1
				Defs.Faction.UNION:
					c["union_ships"] += 1
				_:
					if not (e as ShipData).is_player:
						c["player_ships"] += 1
		elif e.faction == Defs.Faction.UNION:
			c["union_stations"] += 1
	return c


## A modest, rule-based "economic player": miners, traders, one solar, a home-defence wing
## that is topped back up when fighters die, and Defense Platforms at HQ (DEFENSE_AFTER, DEFENSE2_AFTER).
## Everything here is something a human can do from the dock (buy ship / build station).
func _economic(u: Universe) -> void:
	var have: Dictionary = {}
	var solars := 0
	var defenses := 0
	for e: SimEntity in u.entities.values():
		if not e.alive or e.faction != Defs.Faction.PLAYER:
			continue
		if e is ShipData and not (e as ShipData).is_player:
			var cls: String = (e as ShipData).cls
			have[cls] = int(have.get(cls, 0)) + 1
		elif e is StationData and (e as StationData).kind == "solar":
			solars += 1
		elif e is StationData and (e as StationData).kind == "defense":
			defenses += 1
	var defense_cost := float(Defs.STATION["defense"]["cost"])
	var want_def := 0
	if u.time >= DEFENSE2_AFTER:
		want_def = 2
	elif u.time >= DEFENSE_AFTER:
		want_def = 1
	# While saving for a platform, only rebuy fighters when the wing is nearly gone.
	var fighter_cap := 8 if defenses >= want_def else 4
	if int(have.get("miner", 0)) < 4 and u.credits >= 6000.0 + RESERVE:
		u.buy_ship("miner", u.hq)
	elif int(have.get("trader", 0)) < 2 and u.credits >= 7000.0 + RESERVE:
		u.buy_ship("trader", u.hq)
	elif defenses < want_def and u.credits >= defense_cost + RESERVE:
		var off := Vector3(-900, 0, 700) if defenses == 0 else Vector3(900, 0, 900)
		u.build_station("defense", u.hq.sector, u.hq.pos + off)
	elif solars < 1 and (defenses > 0 or u.time < DEFENSE_AFTER) and u.credits >= 28000.0 + RESERVE:
		u.build_station("solar", u.hq.sector, u.hq.pos + Vector3(1200, 0, -900))
	elif int(have.get("fighter", 0)) < fighter_cap and u.credits >= 4500.0 + RESERVE:
		var f := u.buy_ship("fighter", u.hq)
		if f:
			f.order = "patrol"
			f.order_sector = u.hq.sector


func _summary(results: Array[Dictionary], policy: String, minutes: int) -> Dictionary:
	var s := {"policy": policy, "minutes": minutes, "seeds": results.size()}
	for key: String in ["hq_lost_at", "first_raid_at", "union_collapse_at", "net_worth_10", "net_worth_20", "net_worth_30", "hive_ships_20", "union_ships_20"]:
		var vals: Array[float] = []
		for r: Dictionary in results:
			if r.has(key):
				vals.append(float(r[key]))
		vals.sort()
		s[key + "_median"] = vals[vals.size() / 2] if not vals.is_empty() else null
	var survived := 0
	for r: Dictionary in results:
		if float(r["hq_lost_at"]) < 0.0:
			survived += 1
	s["hq_survived"] = "%d/%d" % [survived, results.size()]
	return s
