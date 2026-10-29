extends RefCounted
## VS-063: scripted "first raid lands" proof. Scenarios `raid_hit` (3 screenshots: forecast, impact, Reserve arrived)
## and `raid_hit_long` (headless: HQ hull %, Reserve ships alive and credits every 30 s). Shot-only: it never runs in
## normal play, in --autoplay or in the balance harness, so gameplay RNG and balance are untouched.

const LONG_END := 130.0
const LOG_STEP := 30.0
const RAIDER_HULL_MULT := 12.0
const STUCK_FRAMES := 30000   ## frame-based stuck cap: slow machines render fewer frames per second, so wall/state time must not decide

var g: VoidMain
var _stage: int = 0          ## 0 setup, 1 wait forecast, 2 wait impact, 3 wait reserve, 4 done
var _t_mark: float = 0.0
var _next_log: float = 0.0
var _min_hq: float = 1.0
var _reserve_seen: int = 0
var _hq_hit: bool = false
var _retries: int = 0
var _frames: int = 0


func _init(p_g: VoidMain) -> void:
	g = p_g


func _hq_pct() -> float:
	return g.u.hq.hull / g.u.hq.hull_max


func _reserve_alive() -> int:
	var n := 0
	for e: Variant in g.u.entities.values():
		var s := e as ShipData
		if s != null and s.alive and s.expires >= 0.0 and s.faction == Defs.Faction.UNION:
			n += 1
	return n


func _forecasting() -> bool:
	for rd: Dictionary in g.u.director.tracker.active():
		if g.u.director.tracker.forecast_pct(rd) > 0:
			return true
	return false


func _arrived() -> bool:
	for r: Dictionary in g.u.director.tracker.raids:
		if bool(r["arrived"]):
			return true
	return not g.u.director.tracker.history.is_empty() and _hq_pct() < 1.0


func _snap(idx: int) -> void:
	await RenderingServer.frame_post_draw
	var base := g.shot_file if g.shot_file != "" else "user://shot.png"
	var path := base if idx == 1 else base.trim_suffix(".png") + "_%d.png" % idx
	g.get_viewport().get_texture().get_image().save_png(path)
	print("raid_hit frame %d: hq=%d%% reserve=%d credits=%d -> %s" % [idx, int(_hq_pct() * 100.0), _reserve_alive(), int(g.u.credits), path])


func _spawn_raid() -> void:
	var wsec: int = int(g.u.sectors[g.u.hq.sector].gates[0]["to"])   # one hop out, so the real ETA is inside the forecast lead
	var wgate: Vector3 = g.u.sectors[wsec].gate_to(g.u.hq.sector)["pos"]
	var wl: Array[ShipData] = []
	for i in 4:
		var w := g.u.spawn_ship("drone", Defs.Faction.HIVE, wsec, wgate + Vector3(150 + i * 30, 0, 0))
		w.hull_max *= RAIDER_HULL_MULT   # scenario only: Union patrols on the way must not erase the proof raid before it lands
		w.hull = w.hull_max
		w.order = "raid"
		w.order_target = g.u.hq.id
		w.order_sector = g.u.hq.sector
		wl.append(w)
	g.u.director.tracker.raids.clear()
	g.u.director.tracker.add(wl, g.u.hq)


## Called every frame from TestDriver._shot_script with the state time.
func tick(t: float) -> void:
	var is_long := g.shot_mode == "raid_hit_long"
	if _stage == 0 and t > 0.2:
		_stage = 1
		_t_mark = t
		assert(_hq_pct() >= 1.0, "raid_hit starts with an undamaged HQ")
		_spawn_raid()
		g.u.credits = maxf(g.u.credits, Defs.RESERVE_COST + 1500.0)
		g._set_mode("map")
		return
	if _stage == 0:
		return
	_frames += 1
	if g.u.hq != null:
		_min_hq = minf(_min_hq, _hq_pct())
		_hq_hit = _hq_hit or _hq_pct() < 1.0
	var res := _reserve_alive()
	_reserve_seen = maxi(_reserve_seen, res)
	if is_long and t >= _next_log:
		_next_log += LOG_STEP
		print("raid_hit_long t=%d hq_hull=%d%% reserve_alive=%d credits=%d raids_active=%d state=%s mode=%s" % [int(t), int(_hq_pct() * 100.0), res, int(g.u.credits), g.u.director.tracker.raids.size(), str(g.state), g.mode])
	match _stage:
		1:
			if t - _t_mark > 0.6 and _forecasting():
				if not is_long:
					_stage = 2
					_t_mark = t
					await _snap(1)
				else:
					_stage = 2
					_t_mark = t
		2:
			if g.u.director.tracker.raids.is_empty() and _hq_pct() >= 1.0 and _retries < 3:   # patrols erased the raid first: send another
				_retries += 1
				_spawn_raid()
			if _hq_pct() < 1.0 and t - _t_mark > 0.5:
				_stage = 3
				_t_mark = t
				if not is_long:
					await _snap(2)
				var why := g.u.call_reserve()
				assert(why == "", "raid_hit: Reserve call refused: %s" % why)
		3:
			if res > 0 and t - _t_mark > 1.5:
				_stage = 4
				_t_mark = t
				if not is_long:
					await _snap(3)
					g.get_tree().quit()
	if _frames > STUCK_FRAMES and _stage in [1, 2, 3] and not is_long:
		push_error("raid_hit: stuck in stage %d after %d frames (hq=%d%%)" % [_stage, _frames, int(_hq_pct() * 100.0)])
		g.get_tree().quit(1)
	if is_long and t > LONG_END:
		print("raid_hit_long END: min_hq=%d%% hq_hit=%s reserve_peak=%d credits=%d state=%s mode=%s" % [int(_min_hq * 100.0), str(_hq_hit), _reserve_seen, int(g.u.credits), str(g.state), g.mode])
		assert(_hq_hit, "raid_hit_long: HQ hull never dropped below 100%")
		g.get_tree().quit()
