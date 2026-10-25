class_name TestDriver
extends RefCounted
## Headless/automation hooks. `--autoplay` (used by scripts/check.sh) walks every layer
## in ~15 s; `--shot=<scenario> --shotfile=<png>` stages a scenario and saves a screenshot.
## Scenarios: title map dock surface touch touch_surface over win death combat (+ _long variants).

var g: VoidMain
var _ap_step: int = 0


func _init(p_g: VoidMain) -> void:
	g = p_g


func tick() -> void:
	# Exercises every layer in ~15 s: fight -> map orders/buy/build -> dock -> land + FPS.
	var t := g.state_time
	if g.shot_mode != "":
		_shot_script(t)
		return
	if _ap_step == 0 and t > 4.0:
		_ap_step = 1
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
		g.surface.fps.take_damage(1000.0)


func _shot_script(t: float) -> void:
	if _ap_step == 0 and t > 0.2:
		_ap_step = 1
		match g.shot_mode:
			"title":
				g.state = VoidMain.State.TITLE
				g.overlay.screen = "title"
				g.space.flight_enabled = false
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
			"touch_surface":
				g.touch.active = true
				g._on_land(0)
			"over":
				g.u.hq.take_damage(1e9)
				g.u._on_killed(g.u.hq, 0)
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
