class_name TestDriver
extends RefCounted
## Headless/automation hooks. `--autoplay` (used by scripts/check.sh) walks every layer
## in ~15 s; `--shot=<scenario> --shotfile=<png>` stages a scenario and saves a screenshot.
## Scenarios: sortie combat_long title title_continue title_continue_touch title_confirm map raid_map raid_map_touch raid_map_damaged raid_hit raid_hit_long dock dock_touch touch_wing ledger ledger_dock ledger_map surface surface_far touch touch_surface over over_map win death combat hints sortie_fight
## hints_touch (+ _long variants).

const TITLE_HOLD_FRAMES := 10   # autoplay idles this long on the title before launching

const RaidHitProof := preload("res://scripts/raid_hit_proof.gd")

var g: VoidMain
var _rh: RefCounted = null
var _ap_step: int = 0
var _delta_shot: bool = false
var _title_frames: int = 0
var _save_checked: bool = false
var _far_set := false
var _cs_set := false   ## VS-073: surface_collapse scenarios kill the base once the bot is on the surface
var _min_hull: float = 1e9
var _min_hp: float = 1e9
var _ms: Dictionary = {}   ## VS-037 milestones (surface_long): first pylon, pylons down, core dead, boarded
var _min_foot: float = 1e9   ## VS-037: lowest on-foot (hp + shield) scaled to ship-hull units (x600/160); ship hull itself is untouched on foot


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
		_exercise_raid_ui()
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
	if g.shot_mode == "raid_hit" or g.shot_mode == "raid_hit_long":   # VS-063: own frame sequencer, quits itself
		if _rh == null:
			_rh = RaidHitProof.new(g)
		_rh.tick(t)
		return
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
			"raid_map", "raid_map_touch", "raid_map_damaged":   # VS-039/043: one raid in flight on the inset + panel, one finished outcome listed
				var nst: StationData = g.u.alive_nests()[0]
				var tr := g.u.director.tracker
				var r1 := g.u.spawn_ship("drone", Defs.Faction.HIVE, nst.sector, nst.pos + Vector3(300, 0, 0))
				r1.order = "raid"
				r1.order_target = g.u.hq.id
				r1.order_sector = g.u.hq.sector
				var rl1: Array[ShipData] = [r1]
				tr.add(rl1, g.u.hq)
				tr.history.append({"t": g.u.time - 40.0, "kind": "intercepted", "text": "Raid intercepted in Argent (3/4 destroyed)"})
				g.touch.active = g.shot_mode == "raid_map_touch"
				if g.shot_mode == "raid_map_damaged":   # VS-069: HQ hurt -> Repair HQ joins the strip
					g.u.hq.hull = g.u.hq.hull_max * 0.6
					g.u.credits = maxf(g.u.credits, 500.0)
				g._set_mode("map")
				g.map._order_button("all")
			"raid_warn", "raid_warn_map":   # VS-054: 3 raiders about to reach the HQ sector; forecast on HUD (flight) or inset + panel (map)
				var wsec: int = int(g.u.sectors[g.u.hq.sector].gates[0]["to"])   # one hop from the HQ, so the real ETA is well inside T-60
				var wgate: Vector3 = g.u.sectors[wsec].gate_to(g.u.hq.sector)["pos"]
				var wl: Array[ShipData] = []
				for i in 3:
					var w := g.u.spawn_ship("drone", Defs.Faction.HIVE, wsec, wgate + Vector3(200 + i * 40, 0, 0))
					w.order = "raid"
					w.order_target = g.u.hq.id
					w.order_sector = g.u.hq.sector
					wl.append(w)
				g.u.director.tracker.raids.clear()
				g.u.director.tracker.add(wl, g.u.hq)
				if g.shot_mode == "raid_warn_map":
					g._set_mode("map")
			"hq_wounded", "hq_wounded_dock":   # VS-051: a Breach just chipped the HQ (-12%); outcome text and hull shown
				g.u.hq.hull = g.u.hq.hull_max * 0.88
				g.u.director.tracker.history.append({"t": g.u.time - 20.0, "kind": "intercepted", "text": "Raid intercepted in %s%s (4/6 destroyed)" % [g.u.sectors[g.u.hq.sector].name, ", hull -12%"]})
				if g.shot_mode == "hq_wounded_dock":
					g._on_dock(g.u.hq)
				else:
					g._set_mode("map")
			"hq_wounded_hud", "dock_wounded":   # VS-055: wounded HQ (30% hull) in the flight HUD / at the dock
				g.u.hq.hull = g.u.hq.hull_max * 0.3
				if g.shot_mode == "dock_wounded":
					g._on_dock(g.u.hq)
			"wound_map", "wound_dock":   # VS-050: wounded HQ quotes penalty + repair price
				g.u.hq.hull = g.u.hq.hull_max * 0.2
				if g.shot_mode == "wound_dock":
					g._on_dock(g.u.hq)
				else:
					g._set_mode("map")
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
			"surface", "surface_long", "surface_collapse", "surface_collapse_long":
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
				g.hud._obj_text = Hud.objective_for(g.u, true)   # VS-058: objective already stale, so the tip gets the lane
				g.hud._obj_t = -100.0
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
			"sortie", "sortie_fight":   # VS-030 (VS-046: _fight shoots at t=16, mid-fight): idle player at home when the scouts arrive; escorts hold fire at first
				g.space.autoplay = false
				g.space.player.autopilot = false
				g.u.director.opening.t = 0.2
			"combat_long":   # home sector: the First Sortie (OPENING_WAVE_TIME = 8 s) lands on the player; first damage ~t=12
				pass
			"combat":
				g.u.player_ship.sector = 3
				g.space.enter_sector(3)
				g.space.player.position = Vector3(800, 0, 800)
	if g.shot_mode.ends_with("_long") and int(t * 60.0) % 60 == 0:
		print("t=%d credits=%d hull=%d sh=%d min_hull=%d foot=%d/%d min_foot=%d min_hp=%d ms=%s ship=%d flank=%d mobs=%d %s" % [int(t), int(g.u.credits), int(g.u.player_ship.hull), int(g.u.player_ship.shield), int(_min_hull), int(g.surface.fps.hp) if g.surface else -1, int(g.surface.fps.shield) if g.surface else -1, int(_min_foot), int(_min_hp), str(_ms), int(g.surface.fps.global_position.distance_to(g.surface.ship_pos)) if g.surface else -1, g.surface.flank_spawned if g.surface else 0, g.surface.mobiles_alive() if g.surface else 0, g.surface.objective_text() if g.surface else "sector %d mode %s" % [g.space.sector_idx, g.mode]])
	if g.shot_mode.ends_with("_long") and g.u.player_ship != null:
		_min_hull = minf(_min_hull, g.u.player_ship.hull)
		if g.surface != null:
			var sv := g.surface
			_min_hp = minf(_min_hp, sv.fps.hp)
			if sv.pylons_left() < sv.level + 1 and not _ms.has("pylon1"):
				_ms["pylon1"] = t
			if sv.pylons_left() == 0 and not _ms.has("pylons"):
				_ms["pylons"] = t
			if sv.core_dead and not _ms.has("core"):
				_ms["core"] = t
		elif _ms.has("core") and not _ms.has("boarded"):
			_ms["boarded"] = t
		if g.surface != null:
			_min_foot = minf(_min_foot, (g.surface.fps.hp + g.surface.fps.shield) * 600.0 / (FpsPlayer.MAX_HP + FpsPlayer.MAX_SHIELD))
	if g.shot_mode.begins_with("surface_collapse") and g.surface != null and not _cs_set and t > 3.0:
		_cs_set = true   # VS-073: skip the fight; drop the player at the base, kill pylons + Core, let the bot run the beat
		var sv2 := g.surface
		sv2.fps.global_position = sv2.core_pos + Vector3(30, 3, 0)
		for f: SurfaceView.Foe in sv2.foes.duplicate():
			if f.alive and f.kind == "pylon":
				sv2._kill(f)
		sv2._kill(sv2.core)
	if g.shot_mode == "surface_far" and g.surface != null and not _far_set:
		_far_set = true   # VS-031: view the base from the far map corner
		var sv := g.surface
		sv.autoplay = false
		sv.fps.autopilot = false
		sv.fps.position = Vector3(-sv.half * 0.95, sv.height(-sv.half * 0.95, sv.half * 0.95) + 2.0, sv.half * 0.95)
		sv.fps.look_at(Vector3(sv.core_pos.x, sv.fps.position.y, sv.core_pos.z), Vector3.UP)
		sv.fps.rotation.x = 0.0
		sv.fps.rotation.z = 0.0
	if g.shot_mode.begins_with("raid_map") or g.shot_mode == "map":   # VS-065: cue tracks clipping
		if g.map._scroll_cue != null and t > 2.5:
			assert(g.map._scroll_cue.visible == g.map.scroll_clipped(), "map side panel: scroll cue matches clipped state")
	if g.shot_mode == "map" and _ap_step == 1 and t > 2.5:   # VS-032: buy/build buttons visible without scrolling
		assert(g.map.fold_ok(), "map side panel: Buy/Build tab below the fold at %s (%s)" % [str(g.map.size), g.map.fold_report()])
	if (g.shot_mode == "map" or g.shot_mode.begins_with("raid_map")) and _ap_step == 1 and t > 2.5:   # VS-067
		var st: MapStrip = g.map._strip
		assert(st.reserve_btn.size.y >= 44.0, "map strip: Call Reserve is a >= 44 px target")
		assert(st.on_screen(Rect2(Vector2.ZERO, g.map.size)), "map strip: forecast / Reserve / Repair on screen at %s: %s" % [str(g.map.size), st.rects()])
	if (g.shot_mode == "map" or g.shot_mode.begins_with("raid_map")) and _ap_step == 1 and t > 2.5:   # VS-068
		assert(g.map._tabs.count() == 3 and g.map._tabs.min_tab_height() >= 44.0, "map tabs: Buy/Build/Orders, each >= 44 px")
		g.map._tabs.select(0)
		var only := 0
		for i: int in 3:
			only += 1 if g.map._tabs.page_visible(i) else 0
		assert(only == 1 and g.map._tabs.page_visible(0), "map tabs: only the active tab's list shows")
		var kev := InputEventKey.new()
		kev.keycode = KEY_3
		kev.pressed = true
		assert(g.map._tabs.handle_key(kev) and g.map._tabs.current == 2, "map tabs: key 3 selects Orders")
		g.map._tabs.select(0)
	if g.shot_mode == "raid_map_damaged" and _ap_step == 1 and t > 2.5:   # VS-069
		var dst: MapStrip = g.map._strip
		assert(dst.repair_btn.visible and dst.repair_btn.size.y >= 44.0, "damaged HQ: Repair HQ visible and >= 44 px (%s)" % dst.rects())
	if g.shot_mode.begins_with("raid_map") and _ap_step == 1 and t > 2.5:   # VS-043
		assert(g.map.fold_ok(), "raid map: BUY/BUILD pushed below the fold at %s (%s)" % [str(g.map.size), g.map.fold_report()])
		assert(g.map._defend_btn.visible and g.map._defend_btn.size.y >= 44.0, "Defend button is a >= 44 px target")
		assert(g.map._defend_btn.get_global_rect().end.y <= g.map._scroll.get_global_rect().end.y, "Defend button is on screen")
	if g.shot_mode == "touch_wing" and _ap_step == 1 and t > 2.4 and not _delta_shot:   # VS-053: deltas live at capture
		_delta_shot = true
		g.u.add_credits(150.0, "bounty")
		g.u.add_credits(-420.0, "repair")
	var wait := 6.0 if g.shot_mode == "surface" or g.shot_mode == "surface_far" else 3.0
	if g.shot_mode == "sortie":
		wait = 9.0
	if g.shot_mode == "sortie_fight":
		wait = 16.0
	if g.shot_mode == "surface_collapse":
		wait = 11.0   # ~7 s into the collapse
	if g.shot_mode.ends_with("_long"):
		wait = 120.0 if g.shot_mode == "surface_long" else (40.0 if g.shot_mode == "surface_collapse_long" else 90.0)   # surface_long: leave time to walk back and board
	if _ap_step == 1 and t > wait:
		_ap_step = 2
		if g.shot_mode == "sortie_fight":
			assert(g.hints.threatened and g.hints.current() == "", "VS-046: no tip while the opening fight is on")
		await RenderingServer.frame_post_draw
		var img := g.get_viewport().get_texture().get_image()
		img.save_png(g.shot_file if g.shot_file != "" else "user://shot.png")
		g.get_tree().quit()


## VS-039: a fake raid shows in the map panel and "Defend" sends the warships to patrol its target in one click.
func _exercise_raid_ui() -> void:
	var u := g.u
	var nest: StationData = u.alive_nests()[0]
	var rs := u.spawn_ship("drone", Defs.Faction.HIVE, nest.sector, nest.pos + Vector3(300, 0, 0))
	rs.order = "raid"
	var rl: Array[ShipData] = [rs]
	u.director.tracker.raids.clear()
	u.director.tracker.add(rl, u.hq)
	g.map._raid_panel()
	assert(g.map._defend_btn.visible and "Defend" in g.map._defend_btn.text and "ETA" in g.map._defend_btn.text, "raid shows in the map panel (Defend button carries target + ETA)")
	g.map.selected.clear()
	assert(g.map.defend_raid_target() == u.hq.sector, "Defend orders patrol of the raid target")
	for id: int in g.map.selected:
		assert((u.get_ent(id) as ShipData).order == "patrol" and (u.get_ent(id) as ShipData).order_sector == u.hq.sector)
	rs.alive = false
	u.director.tracker.step(Defs.RAID_TRACK_INTERVAL)
	g.map._raid_panel()
	assert(not g.map._defend_btn.visible and "ago" in g.map._raid_label.text, "outcome listed in the map panel")
