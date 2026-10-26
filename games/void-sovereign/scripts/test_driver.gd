class_name TestDriver
extends RefCounted
## Headless/automation hooks. `--autoplay` (used by scripts/check.sh) walks every layer
## in ~15 s; `--shot=<scenario> --shotfile=<png>` stages a scenario and saves a screenshot.
## Scenarios: title map dock surface touch touch_surface over over_map win death combat hints
## hints_touch (+ _long variants).

const TITLE_HOLD_FRAMES := 10   # autoplay idles this long on the title before launching

var g: VoidMain
var _ap_step: int = 0
var _title_frames: int = 0


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
			"title":
				pass   # main stays on the real title screen for this scenario
			"map":
				g._set_mode("map")
				g.map._order_button("all")
			"dock":
				g._on_dock(g.u.hq)
			"surface", "surface_long":
				g._on_land(0)
			"touch":
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
			"combat", "combat_long":
				g.u.player_ship.sector = 3
				g.space.enter_sector(3)
				g.space.player.position = Vector3(800, 0, 800)
	if g.shot_mode.ends_with("_long") and int(t * 60.0) % 300 == 0:
		print("t=%d credits=%d hull=%d %s" % [int(t), int(g.u.credits), int(g.u.player_ship.hull), g.surface.objective_text() if g.surface else "sector %d mode %s" % [g.space.sector_idx, g.mode]])
	var wait := 6.0 if g.shot_mode == "surface" else 3.0
	if g.shot_mode.ends_with("_long"):
		wait = 90.0
	if _ap_step == 1 and t > wait:
		_ap_step = 2
		await RenderingServer.frame_post_draw
		var img := g.get_viewport().get_texture().get_image()
		img.save_png(g.shot_file if g.shot_file != "" else "user://shot.png")
		g.get_tree().quit()
