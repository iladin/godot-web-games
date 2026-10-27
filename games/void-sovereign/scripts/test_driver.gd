class_name TestDriver
extends RefCounted
## Headless/automation hooks. `--autoplay` (used by scripts/check.sh) walks every layer
## in ~15 s; `--shot=<scenario> --shotfile=<png>` stages a scenario and saves a screenshot.
## Scenarios: sortie combat_long title title_continue title_continue_touch title_confirm map dock dock_touch touch_wing ledger ledger_dock ledger_map surface surface_far touch touch_surface over over_map win death combat hints
## hints_touch (+ _long variants).

const TITLE_HOLD_FRAMES := 10   # autoplay idles this long on the title before launching

var g: VoidMain
var _ap_step: int = 0
var _title_frames: int = 0
var _save_checked: bool = false
var _far_set := false
var _min_hull: float = 1e9


func _init(p_g: VoidMain) -> void:
	g = p_g


func tick() -> void:
	# Exercises every layer in ~15 s: fight -> map orders/buy/build -> dock -> land + FPS.
	var t := g.state_time
	if g.state == VoidMain.State.TITLE:
		_title_frames += 1
		# The world must be frozen behind the title: no sim time, no raids, no HUD.
		assert(g.u.time == 0.0, "Universe stepped on the title screen (u.time=%.2f)" % g.u.time)
		assert(g.hud.mode == "none" and not g.space.flight_enabled, "flight HUD/input live on the title")
		if g.shot_mode == "" and _title_frames >= TITLE_HOLD_FRAMES:
			print("title: %d frames, u.time %.1f — world frozen" % [_title_frames, g.u.time])
			g._start_game()
		elif g.shot_mode == "":
			return
	if g.shot_mode != "":
		_shot_script(t)
		return
	if not _save_checked and t > 2.0 and g.state == VoidMain.State.PLAYING and g.mode == "flight":
		_save_checked = true
		_exercise_save_continue()
	if _ap_step == 0 and t > 4.0:
		_ap_step = 1
		_exercise_audio()
		g._set_mode("map")
		g.map.selected.clear()
		g.map._order_button("all")
		g.map._order_button("patrol")
		g.u.buy_ship("fighter", g.u.hq)
		g.u.build_station("solar", 0, Vector3(1500, 0, -1500))
		g.map._issue_order(g.map.w2s(Vector3(800, 0, 800)))
	elif _ap_step == 1 and t > 6.0:
		_ap_step = 2
		g._set_mode("flight")
		g._on_dock(g.u.hq)
	elif _ap_step == 2 and t > 7.0:
		_ap_step = 3
		g._set_mode("flight")
		g._on_land(0)
	elif _ap_step == 3 and t > 14.0 and g.surface:
		_ap_step = 4
		print("sfx: played %d, blocked before first input %d, muted %s" % [g.sfx.played, g.sfx.blocked, g.sfx.muted])
		_exercise_hints()
		g.surface.fps.take_damage(1000.0)


func _exercise_save_continue() -> void:
	# VS-027: start -> autosave -> Continue rebuilds the view around the restored Universe.
	var old_u := g.u
	var saved_t := old_u.time
	var credits := old_u.credits
	assert(g.flow.save_path == RunSave.AUTOPLAY_PATH, "autoplay never writes the real save")
	assert(g.flow.autosave(), "autosave writes in flight")
	assert(absf(RunSave.peek_time(g.flow.save_path) - saved_t) < 0.01, "save readable, run time matches")
	var title_wait := g.flow.continue_run()   # same call the title's Continue button makes
	assert(title_wait, "continue restores a valid save")
	assert(g.state == VoidMain.State.PLAYING and g.mode == "flight" and g.u != old_u, "continue enters PLAYING on a new Universe")
	assert(absf(g.u.time - saved_t) < 0.01 and absf(g.u.credits - credits) < 0.01, "restored run matches the save")
	assert(g.hud.u == g.u and g.map.u == g.u and g.space.u == g.u, "views rebound to the restored Universe")
	assert(g.space.player != null and g.space.player.data == g.u.player_ship, "player flight bound to restored ship")
	assert(g.get_child(0) == g.pause_gate, "PauseGate stays main's first child")
	old_u.director = null
	print("save/continue: restored at %.1fs, credits %.0f" % [g.u.time, g.u.credits])


func _exercise_audio() -> void:
	# Autoplay never sends real input: everything played so far must have been blocked.
	assert(g.sfx.played == 0, "sfx played before first input")  # SCRIPT ERROR -> check.sh FAIL
	g.sfx.unlock()   # stands in for the first click/key/tap
	for n: String in Sfx.NAMES:
		g.sfx.play(n)
	g.sfx.toggle_mute()
	g.sfx.play("explosion")   # muted: dropped
	g.sfx.toggle_mute()


func _exercise_hints() -> void:
	# Autoplay visited map, dock and surface: those tips must be latched done; then skip the rest.
	for s: String in ["dock", "map", "land"]:
		assert(g.hints.done.has(s), "tutorial hint '%s' completed by autoplay" % s)
	g.hints.skip()
	assert(g.hints.skipped and g.hints.current() == "", "skipped tips never come back")
	print("hints: done %s, skipped %s" % [", ".join(PackedStringArray(g.hints.done.keys())), g.hints.skipped])


func _shot_script(t: float) -> void:
	if _ap_step == 0 and t > 0.2:
		_ap_step = 1
		match g.shot_mode:
			"title", "title_continue":
				pass   # main stays on the real title screen for this scenario
			"title_continue_touch":   # touch layout of the title with a save present
				g.touch.active = true
				g.overlay.touch_hint = true
			"title_confirm":   # New Game pressed once over a save
				assert(g.overlay.continue_time >= 0.0, "seeded save shows Continue")
				assert(not g.flow.request_new_game(true, 0.0), "first press only asks")
				g.overlay.confirm_new = g.flow.confirming()
			"map":
				g._set_mode("map")
				g.map._order_button("all")
			"dock", "dock_touch":
				g.touch.active = g.shot_mode == "dock_touch"
				g._on_dock(g.u.hq)
			"ledger", "ledger_dock", "ledger_map":   # VS-024: HUD cr/min + last-5-min breakdown
				g.space.autoplay = false
				g.u.add_credits(2400.0, "trade")
				g.u.add_credits(1100.0, "mining")
				g.u.add_credits(450.0, "bounty")
				g.u.add_credits(-6000.0, "ships")
				if g.shot_mode == "ledger_dock":
					for e: SimEntity in g.u.ents_in(g.u.hq.sector):
						if e is StationData and (e as StationData).kind == "trade":
							g._on_dock(e as StationData)
				elif g.shot_mode == "ledger_map":
					g._set_mode("map")
			"surface", "surface_long":
				g._on_land(0)
			"surface_far":
				g._on_land(0)
			"touch", "touch_wing":
				g.touch.active = true
				g.touch.set_layout("none")
				g.touch.set_layout("flight")
				g.u.message.emit("Sound on", Color("8fd8ff"))   # two stacked messages vs top row
			"hints":
				g.space.autoplay = false   # keep the ship still under the first tip
				g.space.target_id = 0
				g.space.player.autopilot = false
			"hints_touch":
				g.touch.active = true
				g.touch.set_layout("none")
				g.touch.set_layout("flight")
				g.hints.update({"steer": true, "throttle": true, "target": true})
			"touch_surface":
				g.touch.active = true
				g._on_land(0)
			"over":
				g.u.hq.take_damage(1e9)
				g.u._on_killed(g.u.hq, 0)
			"over_map":   # run ends while the command map is open: map must close
				g._set_mode("map")
				g.u.hq.take_damage(1e9)
				g.u._on_killed(g.u.hq, 0)
				assert(not g.map.visible and not g.dock.visible and g.mode == "flight", "end screen closes the map")
			"win":
				for n: StationData in g.u.alive_nests():
					n.shield_locked = false
					n.take_damage(1e9)
					g.u._on_killed(n, 0)
			"death":
				g._on_dock(g.u.hq)
				g.u.player_ship.take_damage(1e9)
				g.u._on_killed(g.u.player_ship, 0)
			"sortie":   # VS-030: idle player at home when the scouts arrive; escorts hold fire at first
				g.space.autoplay = false
				g.space.player.autopilot = false
				g.u.director.opening.t = 0.2
			"combat_long":   # home sector: the First Sortie lands on the player at t=60
				pass
			"combat":
				g.u.player_ship.sector = 3
				g.space.enter_sector(3)
				g.space.player.position = Vector3(800, 0, 800)
	if g.shot_mode.ends_with("_long") and int(t * 60.0) % 60 == 0:
		print("t=%d credits=%d hull=%d sh=%d min_hull=%d %s" % [int(t), int(g.u.credits), int(g.u.player_ship.hull), int(g.u.player_ship.shield), int(_min_hull), g.surface.objective_text() if g.surface else "sector %d mode %s" % [g.space.sector_idx, g.mode]])
	if g.shot_mode.ends_with("_long") and g.u.player_ship != null:
		_min_hull = minf(_min_hull, g.u.player_ship.hull)
	if g.shot_mode == "surface_far" and g.surface != null and not _far_set:
		_far_set = true   # VS-031: view the base from the far map corner
		var sv := g.surface
		sv.autoplay = false
		sv.fps.autopilot = false
		sv.fps.position = Vector3(-sv.half * 0.95, sv.height(-sv.half * 0.95, sv.half * 0.95) + 2.0, sv.half * 0.95)
		sv.fps.look_at(Vector3(sv.core_pos.x, sv.fps.position.y, sv.core_pos.z), Vector3.UP)
		sv.fps.rotation.x = 0.0
		sv.fps.rotation.z = 0.0
	if g.shot_mode == "map" and _ap_step == 1 and t > 2.5:   # VS-032: buy/build buttons visible without scrolling
		assert(g.map.fold_ok(), "map side panel: BUILD STATION buttons below the fold at %s" % str(g.map.size))
	var wait := 6.0 if g.shot_mode == "surface" or g.shot_mode == "surface_far" else 3.0
	if g.shot_mode == "sortie":
		wait = 9.0
	if g.shot_mode.ends_with("_long"):
		wait = 90.0
	if _ap_step == 1 and t > wait:
		_ap_step = 2
		await RenderingServer.frame_post_draw
		var img := g.get_viewport().get_texture().get_image()
		img.save_png(g.shot_file if g.shot_file != "" else "user://shot.png")
		g.get_tree().quit()
