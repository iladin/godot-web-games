class_name MapView
extends Control
## Command map (the RTS layer): top-down tactical view of any sector, galaxy overview,
## unit selection and orders, ship purchasing and station construction.

signal close_requested()

const SIDE_W := 320.0
const BG := Color(0.012, 0.016, 0.04, 0.96)
const GRID := Color(0.3, 0.5, 0.8, 0.08)
const AMBER := Color("ffb347")
const CYAN := Color("5ee6ff")
const HIVE := Color("ff3b8d")
const VIEW_EXTENT := 7400.0
const DEFEND_BTN_H := 46.0   # VS-043: >= 44 px touch target
const RAID_OUTCOME_LINES := 1   # VS-043: finished-raid lines under the Defend button
const RAID_EXTRA_LINES := 1     # VS-043: extra (2nd, 3rd..) active raids listed as one-line entries
const PICK_PX := 16.0
const DRAG_PX := 8.0
const SHORT_NAMES: Dictionary = {"solar": "Solar Array", "refinery": "Refinery", "factory": "Munitions", "defense": "Defense"}

var u: Universe
var view_sector: int = 0
var zoom: float = 1.0
var selected: Array[int] = []
var order_mode: bool = false        # touch: next tap issues an order
var build_kind: String = ""         # set while placing a station
var font: Font = ThemeDB.fallback_font
var _drag_start: Vector2 = Vector2.ZERO
var _dragging: bool = false
var _drag_now: Vector2 = Vector2.ZERO
var _side: VBoxContainer
var _info: Label
var _head: Label
var _scroll: ScrollContainer
var _build_grid: GridContainer
var _sel_label: Label
var _raid_label: Label              # VS-039: active raids + last-5-min outcomes
var _defend_btn: Button             # VS-039: patrol the first active raid's target sector
var _order_btns: Dictionary = {}
var _buy_btns: Dictionary = {}
var _build_btns: Dictionary = {}
var _order_toggle: Button
var _reserve_btn: Button            # VS-060: Fleet Reserve call-in
var t: float = 0.0


func setup(p_u: Universe) -> void:
	u = p_u
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_side()


func open(sector_idx: int) -> void:
	view_sector = sector_idx
	selected = selected.filter(func(id: int) -> bool: return u.get_ent(id) != null)
	build_kind = ""
	visible = true


func _map_rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(size.x - SIDE_W, size.y))


## VS-043: inset raid labels sit in a fixed strip along the top of the galaxy inset (clear of the sector names
## and hive counters, which cluster mid-inset), one line.
static func raid_label_rect(r: Rect2) -> Rect2:
	return Rect2(r.position.x + (r.size.x - minf(r.size.x, 230.0)) * 0.5, r.position.y + 2.0, minf(r.size.x, 230.0), 12.0)


func _galaxy_rect() -> Rect2:
	return Rect2(Vector2(size.x - SIDE_W + 12, 12), Vector2(SIDE_W - 24, 190))


func _scale() -> float:
	var r := _map_rect()
	return minf(r.size.x, r.size.y) * 0.5 / VIEW_EXTENT * zoom


func w2s(p: Vector3) -> Vector2:
	return _map_rect().get_center() + Vector2(p.x, p.z) * _scale()


func s2w(p: Vector2) -> Vector3:
	var v := (p - _map_rect().get_center()) / _scale()
	return Vector3(v.x, 0, v.y)


# --- Side panel ------------------------------------------------------------------------------
func _build_side() -> void:
	var scroll := ScrollContainer.new()
	scroll.anchor_left = 1.0
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_left = -SIDE_W + 8
	scroll.offset_top = 212
	scroll.offset_right = -8
	scroll.offset_bottom = -8
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_scroll = scroll
	_side = VBoxContainer.new()
	_side.custom_minimum_size = Vector2(SIDE_W - 30, 0)
	_side.add_theme_constant_override("separation", 4)   # VS-043: tighter so a raid block still leaves BUY/BUILD above the fold
	scroll.add_child(_side)
	# VS-032: one-line status first, details (fleet, ledger, selection) after the buy/build
	# buttons, so BUY SHIPS / BUILD STATION stay on screen at 900x720 without scrolling.
	_head = Label.new()
	_head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_head.add_theme_color_override("font_color", AMBER)
	_head.add_theme_font_size_override("font_size", 15)
	_side.add_child(_head)
	var orders := GridContainer.new()
	orders.columns = 3   # VS-043: 2 rows instead of 3 (frees a row for the Defend button)
	_side.add_child(orders)
	for o: Array in [["patrol", "Patrol"], ["escort", "Escort me"], ["trade", "Auto-trade"], ["mine", "Auto-mine"], ["idle", "Stop"], ["all", "Warships"]]:
		var b := Button.new()
		b.text = o[1]
		b.custom_minimum_size = Vector2(88, 34)
		b.add_theme_font_size_override("font_size", 14)
		var key: String = o[0]
		b.pressed.connect(func() -> void: _order_button(key))
		orders.add_child(b)
		_order_btns[key] = b
	_order_toggle = Button.new()
	_order_toggle.toggle_mode = true
	_order_toggle.text = "Tap-to-order: OFF"
	_order_toggle.toggled.connect(func(on: bool) -> void:
		order_mode = on
		_order_toggle.text = "Tap-to-order: %s" % ("ON" if on else "OFF"))
	_side.add_child(_order_toggle)
	_side.add_child(_header("BUY SHIPS (launch at HQ)"))
	var buys := GridContainer.new()
	buys.columns = 2
	_side.add_child(buys)
	for cls: String in Defs.PLAYER_BUYABLE:
		var b2 := Button.new()
		b2.custom_minimum_size = Vector2(140, 42)
		b2.clip_text = true
		b2.pressed.connect(func() -> void:
			var s := u.buy_ship(cls, u.hq)
			if s:
				selected = [s.id])
		buys.add_child(b2)
		_buy_btns[cls] = b2
	_side.add_child(_header("BUILD STATION (click map to place)"))
	var builds := GridContainer.new()
	builds.columns = 2
	_side.add_child(builds)
	_build_grid = builds
	for kind: String in Defs.PLAYER_BUILDABLE:
		var b3 := Button.new()
		b3.custom_minimum_size = Vector2(140, 42)
		b3.clip_text = true
		b3.pressed.connect(func() -> void: build_kind = kind if build_kind != kind else "")
		builds.add_child(b3)
		_build_btns[kind] = b3
	_reserve_btn = DockPanel.make_reserve_button(u, 40.0)   # VS-060: after the build grid so fold_ok() is unaffected
	_reserve_btn.add_theme_font_size_override("font_size", 14)
	_side.add_child(_reserve_btn)
	_info = Label.new()
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_side.add_child(_info)
	_raid_label = Label.new()
	_raid_label.autowrap_mode = TextServer.AUTOWRAP_OFF   # VS-043: one line per entry, ellipsis instead of wrapping
	_raid_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_raid_label.add_theme_color_override("font_color", HIVE)
	_raid_label.add_theme_font_size_override("font_size", 13)
	_raid_label.visible = false
	_side.add_child(_raid_label)
	_side.move_child(_raid_label, _side.get_child_count() - 2)   # VS-043: outcome lines sit below BUY/BUILD, above the selection text
	_defend_btn = Button.new()
	_defend_btn.custom_minimum_size = Vector2(0, DEFEND_BTN_H)
	_defend_btn.clip_text = true
	_defend_btn.add_theme_font_size_override("font_size", 14)
	_defend_btn.tooltip_text = "Orders your selected warships (or, with nothing selected, ALL armed ships you own, including auto-traders) to patrol the raid's target sector."
	_defend_btn.visible = false
	_defend_btn.pressed.connect(defend_raid_target)
	_side.add_child(_defend_btn)
	_side.move_child(_defend_btn, 1)   # right under the status line: the Defend button is the threat call to action
	_sel_label = Label.new()
	_sel_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sel_label.add_theme_color_override("font_color", AMBER)
	_side.add_child(_sel_label)
	var close := Button.new()
	close.text = "Close map (M)"
	close.custom_minimum_size = Vector2(0, 48)
	close.pressed.connect(func() -> void: close_requested.emit())
	_side.add_child(close)


## VS-032: true when the last BUILD STATION button ends inside the side scroll area (no scrolling needed).
func fold_ok() -> bool:
	return _build_grid.get_global_rect().end.y <= _scroll.get_global_rect().end.y + 0.5


func _header(s: String) -> Label:
	var l := Label.new()
	l.text = s
	l.add_theme_font_size_override("font_size", 16)
	l.modulate = Color(1, 1, 1, 0.6)
	return l


func _order_button(key: String) -> void:
	if key == "all":
		selected.clear()
		for e: SimEntity in u.entities.values():
			if e is ShipData and e.faction == Defs.Faction.PLAYER and e.armed() and e.sector == view_sector and not (e as ShipData).is_player:
				selected.append(e.id)
		return
	for id: int in selected:
		var s := u.get_ent(id) as ShipData
		if s == null:
			continue
		if (key == "trade" and s.role != "trader") or (key == "mine" and s.role != "miner"):
			continue
		if (key == "patrol" or key == "escort") and not s.armed():
			continue
		s.order = key
		s.ai_state = ""
		s.order_sector = view_sector
		s.order_target = 0


## VS-039: sends the selection (or, with nothing selected, every player warship) to patrol the sector of the
## first active raid: one click on the raid button, or two with the selection step. Returns the sector or -1.
func defend_raid_target() -> int:
	var act := u.director.tracker.active()
	if act.is_empty():
		return -1
	var sec := int(act[0]["target_sector"])
	if selected.is_empty():
		for e: SimEntity in u.entities.values():
			if _own_unit(e) and e.faction == Defs.Faction.PLAYER and e.armed():
				selected.append(e.id)
	var n := 0
	for id: int in selected:
		var sh := u.get_ent(id) as ShipData
		if sh == null or not sh.armed():
			continue
		sh.order = "patrol"
		sh.ai_state = ""
		sh.order_sector = sec
		sh.order_target = 0
		n += 1
	if n > 0:
		u.message.emit("%d ships ordered to patrol %s" % [n, u.sectors[sec].name], AMBER)
	return sec


## VS-043: label lines (compact): extra active raids first, then at most RAID_OUTCOME_LINES recent outcomes.
## The first raid itself lives in the Defend button text, so the block costs a button plus a line or two.
func raid_lines(act: Array, rec: Array) -> Array[String]:
	var tr := u.director.tracker
	var lines: Array[String] = []
	if not act.is_empty() and tr.forecast_text(act[0]) != "":   # VS-054: same line as the HUD, above the extras
		lines.append(tr.forecast_text(act[0]))
	for i: int in range(1, mini(act.size(), 1 + RAID_EXTRA_LINES)):
		lines.append(tr.label_for(act[i]))
	for o: Dictionary in rec.slice(0, RAID_OUTCOME_LINES):
		lines.append("%s (%s ago)" % [o["text"], "%ds" % int(float(o["age"])) if float(o["age"]) < 60.0 else "%dm" % int(float(o["age"]) / 60.0)])
	return lines


func _raid_panel() -> void:
	var tr := u.director.tracker
	var act := tr.active()
	var lines := raid_lines(act, tr.recent())
	_raid_label.visible = not lines.is_empty()
	_raid_label.text = "\n".join(lines)
	_raid_label.tooltip_text = _raid_label.text
	_defend_btn.visible = not act.is_empty()
	if not act.is_empty():
		var rd: Dictionary = act[0]
		var more := "" if act.size() == 1 else " +%d" % (act.size() - 1)
		_defend_btn.text = "Defend %s - %s%s" % [u.sectors[int(rd["target_sector"])].name, "ON SITE" if bool(rd["arrived"]) or int(rd["sector"]) == int(rd["target_sector"]) else "ETA %ds" % int(float(rd["eta"])), more]


func _process(delta: float) -> void:
	if not visible:
		return
	t += delta
	_raid_panel()
	selected = selected.filter(func(id: int) -> bool: return u.get_ent(id) != null)
	var s := u.sectors[view_sector]
	var counts: Dictionary = {}
	for e: SimEntity in u.entities.values():
		if e is ShipData and e.faction == Defs.Faction.PLAYER and not (e as ShipData).is_player:
			var c: String = (e as ShipData).display_name
			counts[c] = int(counts.get(c, 0)) + 1
	var fleet := ", ".join(counts.keys().map(func(k: String) -> String: return "%s ×%d" % [k, counts[k]]))
	var pstate := {"hive": "Hive Core (threat %d)" % s.level, "colony": "Your colony", "union": "Union world"}
	_head.text = "Credits %s  ·  %s" % [Hud._fmt(u.credits), "%d selected" % selected.size() if not selected.is_empty() else "none selected"]
	_info.text = "%s\nPlanet %s: %s\nFleet: %s\n%s" % [s.name, s.planet_name, pstate[s.planet_state], fleet if fleet != "" else "none", Hud.ledger_text(u, 4)]
	if selected.is_empty():
		_sel_label.text = "Click or drag-box your ships to select. Right-click to order."
	else:
		var lines: Array[String] = []
		for id: int in selected.slice(0, 6):
			var sh := u.get_ent(id) as ShipData
			lines.append("%s — %s%s" % [sh.display_name, sh.order, "" if sh.sector == view_sector else " (%s)" % u.sectors[sh.sector].name])
		_sel_label.text = "\n".join(lines)
	_reserve_btn.text = DockPanel.reserve_text(u)
	_reserve_btn.disabled = u.reserve_refusal() != ""
	for cls: String in _buy_btns:
		var cost := int(Defs.SHIP[cls]["cost"])
		(_buy_btns[cls] as Button).text = "%s\n%s" % [Defs.SHIP[cls]["name"], Hud._fmt(cost)]
		(_buy_btns[cls] as Button).disabled = u.credits < cost or not u.hq.alive
	for kind: String in _build_btns:
		var cost2 := int(Defs.STATION[kind]["cost"])
		var b := _build_btns[kind] as Button
		b.text = "%s%s\n%s" % ["> " if build_kind == kind else "", SHORT_NAMES[kind], Hud._fmt(cost2)]
		b.disabled = u.credits < cost2 or u.sector_has_nest(view_sector)
	queue_redraw()


# --- Input --------------------------------------------------------------------------------
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			zoom = clampf(zoom * 1.15, 0.6, 6.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			zoom = clampf(zoom / 1.15, 0.6, 6.0)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_drag_start = mb.position
				_drag_now = mb.position
				_dragging = true
			elif _dragging:
				_dragging = false
				_left_release(mb.position, mb.shift_pressed)
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			if _galaxy_rect().has_point(mb.position):
				var gs := _galaxy_pick(mb.position)
				if gs >= 0:
					_order_goto(gs)
			elif _map_rect().has_point(mb.position):
				_issue_order(mb.position)
	elif event is InputEventMouseMotion and _dragging:
		_drag_now = (event as InputEventMouseMotion).position


func _left_release(p: Vector2, additive: bool) -> void:
	if _galaxy_rect().has_point(p):
		var gs := _galaxy_pick(p)
		if gs >= 0:
			if order_mode and not selected.is_empty() and gs != view_sector:
				_order_goto(gs)
			view_sector = gs
		return
	if not _map_rect().has_point(p):
		return
	if build_kind != "":
		var wp := s2w(p)
		wp.y = randf_range(-100, 100)
		if u.build_station(build_kind, view_sector, wp):
			build_kind = ""
		return
	if p.distance_to(_drag_start) > DRAG_PX:
		var r := Rect2(_drag_start, p - _drag_start).abs()
		if not additive:
			selected.clear()
		for e: SimEntity in u.ents_in(view_sector):
			if _own_unit(e) and r.has_point(w2s(e.pos)):
				selected.append(e.id)
		return
	var hit := _pick(p)
	if hit and _own_unit(hit):
		if not additive:
			selected.clear()
		if not (hit.id in selected):
			selected.append(hit.id)
	elif order_mode and not selected.is_empty():
		_issue_order(p)
	elif not additive:
		selected.clear()


func _own_unit(e: SimEntity) -> bool:
	return e is ShipData and e.faction == Defs.Faction.PLAYER and not (e as ShipData).is_player


func _pick(p: Vector2) -> SimEntity:
	var best: SimEntity = null
	var best_d := PICK_PX
	for e: SimEntity in u.ents_in(view_sector):
		var d := w2s(e.pos).distance_to(p)
		if e.is_station:
			d -= 8.0
		if d < best_d:
			best_d = d
			best = e
	return best


func _issue_order(p: Vector2) -> void:
	if selected.is_empty():
		return
	var hit := _pick(p)
	for gd: Dictionary in u.sectors[view_sector].gates:
		if w2s(gd["pos"]).distance_to(p) < PICK_PX * 1.4:
			_order_goto(int(gd["to"]))
			return
	var wp := s2w(p)
	var i := 0
	for id: int in selected:
		var s := u.get_ent(id) as ShipData
		if s == null:
			continue
		s.ai_state = ""
		if hit and Defs.hostile(s.faction, hit.faction) and s.armed():
			s.order = "attack"
			s.order_target = hit.id
		else:
			s.order = "move"
			s.order_sector = view_sector
			var off := Vector3(cos(i * 2.4), 0, sin(i * 2.4)) * 60.0 * sqrt(float(i))
			s.order_pos = (hit.pos + (s.pos - hit.pos).normalized() * (hit.radius + 150.0) if hit else wp) + off
		i += 1


func _order_goto(sector_idx: int) -> void:
	for id: int in selected:
		var s := u.get_ent(id) as ShipData
		if s:
			s.order = "goto"
			s.order_sector = sector_idx
			s.ai_state = ""
	u.message.emit("%d ships ordered to %s" % [selected.size(), u.sectors[sector_idx].name], AMBER)


func _galaxy_pick(p: Vector2) -> int:
	var r := _galaxy_rect()
	for s: SectorData in u.sectors:
		if (r.position + s.map_pos * r.size).distance_to(p) < 18.0:
			return s.idx
	return -1


# --- Drawing ---------------------------------------------------------------------------------
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG)
	var mr := _map_rect()
	var c := mr.get_center()
	var sc := _scale()
	for ring in range(1, 8):
		draw_arc(c, float(ring) * 1000.0 * sc, 0, TAU, 64, GRID, 1.0)
	draw_line(Vector2(c.x, mr.position.y), Vector2(c.x, mr.end.y), GRID)
	draw_line(Vector2(mr.position.x, c.y), Vector2(mr.end.x, c.y), GRID)
	var s := u.sectors[view_sector]
	var pc := HIVE if s.planet_state == "hive" else (AMBER if s.planet_state == "colony" else CYAN)
	draw_circle(w2s(s.planet_pos), Defs.PLANET_RADIUS * sc, Color(pc, 0.18))
	draw_arc(w2s(s.planet_pos), Defs.PLANET_RADIUS * sc, 0, TAU, 48, Color(pc, 0.6), 1.5)
	_text(w2s(s.planet_pos) + Vector2(-80, 4), s.planet_name, 16, pc, 160)
	for f: Dictionary in s.fields:
		draw_arc(w2s(f["pos"]), float(f["radius"]) * sc, 0, TAU, 24, Color(0.7, 0.55, 0.4, 0.5), 1.0)
		_text(w2s(f["pos"]) + Vector2(-40, 4), "ore", 12, Color(0.7, 0.55, 0.4, 0.7), 80)
	for g: Dictionary in s.gates:
		var gp := w2s(g["pos"])
		draw_arc(gp, 12, 0, TAU, 20, CYAN, 2.0)
		_text(gp + Vector2(-80, 30), "> " + u.sectors[int(g["to"])].name, 14, CYAN, 160)
	# Order lines for selected.
	for id: int in selected:
		var sh := u.get_ent(id) as ShipData
		if sh == null or sh.sector != view_sector:
			continue
		var tp: Variant = null
		if sh.order == "move":
			tp = sh.order_pos
		elif sh.order == "attack" and u.get_ent(sh.order_target):
			tp = u.get_ent(sh.order_target).pos
		if tp != null:
			draw_dashed_line(w2s(sh.pos), w2s(tp), Color(AMBER, 0.6), 1.5, 6.0)
	for e: SimEntity in u.ents_in(view_sector):
		_draw_ent(e)
	# VS-035: station names last and above the icon so ships clustered at the HQ never cover them.
	for e: SimEntity in u.ents_in(view_sector):
		if e.is_station:
			var sp := w2s(e.pos)
			var nm := e.display_name
			for o: Vector2 in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
				draw_string(font, sp + Vector2(-90, -22) + o, nm, HORIZONTAL_ALIGNMENT_CENTER, 180, 13, Color(0, 0, 0, 0.85))
			_text(sp + Vector2(-90, -22), nm, 13, Color(Defs.faction_color(e.faction), 1.0), 180)
	if _dragging and _drag_start.distance_to(_drag_now) > DRAG_PX and build_kind == "":
		var r := Rect2(_drag_start, _drag_now - _drag_start).abs()
		draw_rect(r, Color(AMBER, 0.1))
		draw_rect(r, AMBER, false, 1.0)
	var hint := "Wheel zoom · LMB select / drag box · RMB order (enemy = attack, gate = jump)"
	if build_kind != "":
		hint = "Click the map to place: %s" % Defs.STATION[build_kind]["name"]
		var mp := get_local_mouse_position()
		if mr.has_point(mp):
			draw_arc(mp, Defs.station_f(build_kind, "radius") * sc + 6, 0, TAU, 24, AMBER, 2.0)
	_text(Vector2(16, size.y - 18), hint, 16, Color(1, 1, 1, 0.55), mr.size.x - 32)
	_text(Vector2(16, 34), "COMMAND MAP — %s" % s.name, 26, Color.WHITE, 600)
	_draw_galaxy()


func _draw_ent(e: SimEntity) -> void:
	var p := w2s(e.pos)
	var col := Defs.faction_color(e.faction)
	var sel := e.id in selected
	if e.is_station:
		var r := 9.0
		draw_rect(Rect2(p - Vector2(r, r), Vector2(r, r) * 2), Color(col, 0.35))
		draw_rect(Rect2(p - Vector2(r, r), Vector2(r, r) * 2), col, false, 2.0)
		if not e.can_be_damaged():
			draw_arc(p, 18, 0, TAU, 24, Color(HIVE, 0.6 + 0.3 * sin(t * 4.0)), 2.0)
		draw_rect(Rect2(p + Vector2(-14, 13), Vector2(28 * e.hull_frac(), 3)), col)
		if e.faction == Defs.Faction.PLAYER and e.hull_frac() < 0.995:
			# VS-048: wounds stay visible until repaired at a dock.
			var wc := HIVE if e.hull_frac() < 0.5 else AMBER
			var wp := (e as StationData).wound_penalty()
			var lbl := "DAMAGED %d%%" % int(e.hull_frac() * 100.0)
			if wp > 0.0:
				# VS-050: two lines on a dark backdrop above the HQ, wide enough that the price never clips.
				var l2 := "-%d%% income & shield regen · repair %s cr" % [int(round(wp * 100.0)), Hud._fmt(u.station_repair_cost(e as StationData))]
				draw_rect(Rect2(p + Vector2(-165, -66), Vector2(330, 32)), Color(0.02, 0.02, 0.05, 0.85))
				_text(p + Vector2(-165, -52), lbl, 12, wc, 330)
				_text(p + Vector2(-165, -38), l2, 12, wc, 330)
			else:
				_text(p + Vector2(-55, 28), lbl, 12, wc, 110)
		return
	var sh := e as ShipData
	var dir := Vector2(e.vel.x, e.vel.z)
	dir = dir.normalized() if dir.length() > 1.0 else Vector2.UP
	var n := dir.orthogonal()
	var sz := 9.0 if sh.is_player else (7.0 if sh.radius > 20.0 else 5.0)
	if sh.cls == "dreadnought":
		sz = 12.0
	var pts := PackedVector2Array([p + dir * sz, p - dir * sz * 0.7 + n * sz * 0.6, p - dir * sz * 0.7 - n * sz * 0.6])
	draw_colored_polygon(pts, Color.WHITE if sh.is_player else col)
	if sh.is_player:
		draw_arc(p, 14, 0, TAU, 20, Color(1, 1, 1, 0.5 + 0.4 * sin(t * 5.0)), 1.5)
	if sel:
		draw_arc(p, 11, 0, TAU, 16, AMBER, 2.0)


func _draw_galaxy() -> void:
	var r := _galaxy_rect()
	draw_rect(r, Color(0, 0, 0, 0.5))
	draw_rect(r, Color(CYAN, 0.3), false, 1.0)
	for l: Vector2i in Defs.LINKS:
		draw_line(r.position + u.sectors[l.x].map_pos * r.size, r.position + u.sectors[l.y].map_pos * r.size, Color(CYAN, 0.35), 1.5)
	var you := u.player_ship.sector if u.player_ship else -1
	for s: SectorData in u.sectors:
		var p := r.position + s.map_pos * r.size
		var col := CYAN
		if u.sector_has_nest(s.idx):
			col = HIVE
		elif s.idx == u.hq.sector:
			col = AMBER
		draw_circle(p, 8, Color(col, 0.6))
		if s.idx == view_sector:
			draw_arc(p, 13, 0, TAU, 20, Color.WHITE, 2.0)
		if s.idx == you:
			draw_arc(p, 17, 0, TAU, 20, Color(1, 1, 1, 0.5), 1.0)
		var threat := 0
		for e: SimEntity in u.ents_in(s.idx):
			if e.faction == Defs.Faction.HIVE and e is ShipData:
				threat += 1
		_text(p + Vector2(-60, -12), s.name, 12, Color(1, 1, 1, 0.8), 120)
		if threat > 0:
			draw_colored_polygon(PackedVector2Array([p + Vector2(-14, 14), p + Vector2(-8, 4), p + Vector2(-2, 14)]), HIVE)
			_text(p + Vector2(-2, 24), "%d" % threat, 12, HIVE, 24)
	# VS-025/039: every active raid: red ring on its sector, a line to the target sector (ringed), a "x3 > Ember ETA 42s" label.
	var shown := 0
	var first_lbl := ""
	for rd: Dictionary in u.director.tracker.active():
		var rp := r.position + u.sectors[int(rd["sector"])].map_pos * r.size
		var tp := r.position + u.sectors[int(rd["target_sector"])].map_pos * r.size
		if rp != tp:
			draw_dashed_line(rp, tp, Color(HIVE, 0.8), 2.0, 6.0)
			draw_arc(tp, 15, 0, TAU, 20, Color(HIVE, 0.5 + 0.4 * sin(t * 6.0)), 1.5)
		draw_arc(rp, 11, 0, TAU, 16, HIVE, 2.5)
		if shown == 0:
			first_lbl = u.director.tracker.label_for(rd)
		shown += 1
	if shown > 0:   # one label only (the soonest raid); the Defend button and panel carry the rest
		var lr := raid_label_rect(r)
		_text(Vector2(lr.position.x, lr.end.y), first_lbl + ("" if shown == 1 else " +%d" % (shown - 1)), 11, HIVE, lr.size.x)
	_text(r.position + Vector2(6, r.size.y - 6), "Click sector to view · RMB send selection", 11, Color(1, 1, 1, 0.5), r.size.x)


func _text(p: Vector2, s: String, fs: int, c: Color, w: float) -> void:
	draw_string(font, p, s, HORIZONTAL_ALIGNMENT_CENTER if w < 400 else HORIZONTAL_ALIGNMENT_LEFT, w, fs, c)
