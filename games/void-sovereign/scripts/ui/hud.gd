class_name Hud
extends Control
## Flight + surface HUD, drawn by hand. Reads state from the views; never mutates it.

const CYAN_HINT := Color("8fd8ff")
const AMBER := Color("ffb347")
const CYAN := Color("5ee6ff")
const HIVE := Color("ff3b8d")
const DIM := Color(1, 1, 1, 0.55)
const PANEL := Color(0.02, 0.03, 0.08, 0.55)
const SAVE_NOTICE := "Progress is saved when you return to space"
const SAVE_NOTICE_SECS := 8.0
const MSG_LIFE := 7.0
const MAX_MSGS := 6

var u: Universe
var space: SpaceView
var surface: SurfaceView
var mode: String = "flight"     # flight | surface | none
var font: Font = ThemeDB.fallback_font
var msgs: Array[Dictionary] = []
var popups: Array[Dictionary] = []
var hit_flash: float = 0.0
var dmg_flash: float = 0.0
var kill_flash: float = 0.0   ## VS-037: red X + screen tint on a confirmed kill
var _last_credits: float = 0.0
var t: float = 0.0
var surface_t: float = 0.0   ## VS-041: seconds on foot, for the save notice


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func bind(p_u: Universe) -> void:
	u = p_u
	_last_credits = u.credits
	msgs.clear()
	u.message.connect(add_message)


func add_message(text: String, col: Color) -> void:
	msgs.push_front({"text": text, "col": col, "t": 0.0})
	if msgs.size() > MAX_MSGS:
		msgs.resize(MAX_MSGS)


func hit() -> void:
	hit_flash = 0.15


func kill(big: bool = false) -> void:
	kill_flash = 0.6 if big else 0.4


func damaged(_amount: float) -> void:
	dmg_flash = minf(dmg_flash + 0.35, 0.8)


func _process(delta: float) -> void:
	t += delta
	if mode == "surface":
		surface_t += delta
	hit_flash = maxf(hit_flash - delta, 0.0)
	dmg_flash = maxf(dmg_flash - delta * 1.2, 0.0)
	kill_flash = maxf(kill_flash - delta, 0.0)
	for m: Dictionary in msgs:
		m["t"] = float(m["t"]) + delta
	msgs = msgs.filter(func(m: Dictionary) -> bool: return float(m["t"]) < MSG_LIFE)
	if u:
		var dc := u.credits - _last_credits
		if dc >= 50.0:
			popups.append({"text": "+%d cr" % int(dc), "t": 0.0})
		_last_credits = u.credits
	for p: Dictionary in popups:
		p["t"] = float(p["t"]) + delta
	popups = popups.filter(func(p: Dictionary) -> bool: return float(p["t"]) < 1.4)
	queue_redraw()


func _draw() -> void:
	if u == null or mode == "none":
		return
	var sz := size
	if mode == "flight" and space and space.player:
		_draw_markers(sz)
		_draw_flight(sz)
	elif mode == "surface" and surface:
		_draw_surface(sz)
	_draw_top(sz)
	_draw_messages(sz)
	if mode == "flight":
		var tch := space != null and space.touch != null and space.touch.active
		_txt(Vector2(0, sz.y - 14), "OBJECTIVE  " + objective_for(u, tch), 17, Color(AMBER, 0.85), HORIZONTAL_ALIGNMENT_CENTER, sz.x)
		if u.ledger.income_per_min(u.time) <= 0.0:   # VS-032: nudge new players toward income
			_txt(Vector2(0, sz.y - 38), earn_hint(tch), 15, Color(CYAN_HINT, 0.8), HORIZONTAL_ALIGNMENT_CENTER, sz.x)
	if dmg_flash > 0.0:
		var c := Color(1, 0.1, 0.2, dmg_flash * 0.35)
		draw_rect(Rect2(0, 0, sz.x, 18), c)
		draw_rect(Rect2(0, sz.y - 18, sz.x, 18), c)
		draw_rect(Rect2(0, 0, 18, sz.y), c)
		draw_rect(Rect2(sz.x - 18, 0, 18, sz.y), c)


func _txt(p: Vector2, s: String, fs: int, c: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, w: float = -1.0) -> void:
	draw_string_outline(font, p, s, align, w, fs, maxi(2, fs / 6), Color(0, 0, 0, 0.85 * c.a))   # VS-031 dark outline
	draw_string(font, p + Vector2(1, 1), s, align, w, fs, Color(0, 0, 0, 0.7 * c.a))
	draw_string(font, p, s, align, w, fs, c)


func _bar(r: Rect2, frac: float, c: Color) -> void:
	draw_rect(r, Color(0, 0, 0, 0.5))
	draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(frac, 0.0, 1.0), r.size.y)), c)
	draw_rect(r, Color(c, 0.6), false, 1.0)


func _draw_top(sz: Vector2) -> void:
	draw_rect(Rect2(0, 0, 500, 92), PANEL)
	var loc := u.sectors[space.sector_idx].name if space and mode == "flight" else ("Surface of " + u.sectors[surface.sector_idx].planet_name if surface else "")
	var cr := "%s cr" % _fmt(u.credits)
	_txt(Vector2(14, 32), cr, 28, AMBER)
	# VS-024: rolling income rate (CreditLedger.RATE_WINDOW) right of the balance.
	var rate_x := 14.0 + font.get_string_size(cr, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x + 10.0
	var rate := rate_text(u)   # VS-035: hidden for the first MIN_RATE_SPAN seconds (same on touch and desktop)
	if rate != "":
		_txt(Vector2(rate_x, 32), rate, 16, Color(AMBER, 0.75))
	var pop_x := rate_x + font.get_string_size(rate, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 10.0
	_txt(Vector2(14, 58), loc, 20, CYAN)
	var mins := int(u.time / 60.0)
	_txt(Vector2(14, 82), "T+%02d:%02d   Nests %d   Colonies %d   Kills %d" % [mins, int(u.time) % 60, u.alive_nests().size(), u.colonies(), u.kills], 16, DIM)
	_txt(Vector2(340, 32), "HQ", 16, DIM)
	if u.hq:
		_bar(Rect2(370, 20, 115, 10), u.hq.hull_frac(), AMBER if u.hq.hull_frac() > 0.35 else HIVE)
		if u.hq.hull_frac() < 0.995:
			_txt(Vector2(490, 32), "%d%%" % int(u.hq.hull_frac() * 100.0), 14, AMBER if u.hq.hull_frac() > 0.35 else HIVE)
	var raid := u.director.raid_t
	_txt(Vector2(340, 58), "Next raid %ds" % int(raid), 16, HIVE if raid < 20.0 and not u.director.next_raid_likely_deterred() else DIM)
	for p: Dictionary in popups:
		var k := float(p["t"]) / 1.4
		_txt(Vector2(pop_x, 32 - k * 30.0), p["text"], 22, Color(AMBER, 1.0 - k))


func _draw_messages(sz: Vector2) -> void:
	var y := 30.0
	for m: Dictionary in msgs:
		var a := clampf((MSG_LIFE - float(m["t"])) / 1.5, 0.0, 1.0)
		_txt(Vector2(sz.x - 820, y), m["text"], 17, Color(m["col"], a), HORIZONTAL_ALIGNMENT_RIGHT, 800)
		y += 24.0


# --- Flight --------------------------------------------------------------------------------
func _draw_flight(sz: Vector2) -> void:
	var p := space.player
	var ps := u.player_ship
	var c := sz * 0.5
	# Crosshair + steering cursor.
	var cc := AMBER if hit_flash <= 0.0 else Color.WHITE
	draw_arc(c, 14, 0, TAU, 24, Color(cc, 0.8), 1.5)
	if hit_flash > 0.0:
		for a: float in [0.785, 2.356, 3.927, 5.498]:
			var d := Vector2(cos(a), sin(a))
			draw_line(c + d * 10, c + d * 22, Color.WHITE, 2.5)
	var cur := c + p.steer * minf(sz.x, sz.y) * 0.3
	draw_circle(cur, 4, Color(CYAN, 0.8))
	draw_line(c, cur, Color(CYAN, 0.2), 1.0)
	# Bottom-left panel: hull, shield, speed.
	var base := Vector2(20, sz.y - 120) if not space.touch.active else Vector2(20, 130)
	draw_rect(Rect2(base - Vector2(8, 26), Vector2(330, 144)), PANEL)
	_txt(base, "SHIELD", 16, DIM)
	_bar(Rect2(base + Vector2(80, -12), Vector2(230, 12)), ps.shield_frac(), CYAN)
	_txt(base + Vector2(0, 24), "HULL", 16, DIM)
	_bar(Rect2(base + Vector2(80, 12), Vector2(230, 12)), ps.hull_frac(), AMBER if ps.hull_frac() > 0.3 else HIVE)
	_txt(base + Vector2(0, 52), "%d m/s" % int(p.speed()), 24, Color.WHITE)
	_bar(Rect2(base + Vector2(110, 38), Vector2(200, 8)), p.throttle, Color(1, 1, 1, 0.7))
	_bar(Rect2(base + Vector2(110, 50), Vector2(200, 6)), p.boost_meter, AMBER)
	var status := ""
	if p.travel:
		status = "TRAVEL DRIVE" if p.travel_charge >= PlayerFlight.TRAVEL_CHARGE else "TRAVEL charging..."
	elif p.boosting:
		status = "BOOST"
	_txt(base + Vector2(0, 80), status, 18, AMBER)
	var cargo := ""
	for w: String in ps.cargo:
		cargo += "%s %d  " % [Defs.WARE_NAMES[w], int(ps.cargo[w])]
	_txt(base + Vector2(150, 80), cargo, 14, DIM)
	_txt(base + Vector2(0, 106), Wing.status(u, space.sector_idx), 16, Defs.faction_color(Defs.Faction.PLAYER))
	if space.prompt != "" and TutorialHints.on_screen not in ["steer", "throttle"]:
		_txt(Vector2(0, sz.y * 0.72), space.prompt, 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, sz.x)
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not space.touch.active and not space.docked \
			and TutorialHints.on_screen == "" and not TutorialHints.deferred:
		_txt(Vector2(0, sz.y * 0.78), "Click to capture mouse for steering", 18, DIM, HORIZONTAL_ALIGNMENT_CENTER, sz.x)


func _draw_markers(sz: Vector2) -> void:
	var cam := space.cam
	var sidx := space.sector_idx
	var s := u.sectors[sidx]
	var cpos := cam.global_position
	# Gates and planet.
	for gn: Node3D in space.gates:
		_marker(cam, sz, gn.position, CYAN, "> " + String(gn.get_meta("label")), true, cpos)
	var pcol := HIVE if s.planet_state == "hive" else (AMBER if s.planet_state == "colony" else CYAN)
	_marker(cam, sz, s.planet_pos, pcol, s.planet_name, true, cpos)
	for e: SimEntity in u.ents_in(sidx):
		if e == u.player_ship:
			continue
		var col := Defs.faction_color(e.faction)
		if e.is_station:
			_marker(cam, sz, e.pos, col, e.display_name, true, cpos)
		elif e is ShipData and (e as ShipData).sortie and e.alive:
			# VS-038: sortie scouts get a labelled marker with distance, or an edge arrow when off-screen.
			if cam.is_position_behind(e.pos) or not Rect2(Vector2.ZERO, sz).has_point(cam.unproject_position(e.pos)):
				_edge_arrow(sz, cam, e.pos, HIVE, "Scout %dm" % int(e.pos.distance_to(cpos)))
			else:
				_marker(cam, sz, e.pos, col, "", true, cpos)
				# Label above the diamond (station labels sit to the right) so the two don't overprint.
				var spp := cam.unproject_position(e.pos)
				_txt(spp + Vector2(-50, -26), "Scout %dm" % int(e.pos.distance_to(cpos)), 14, Color(col, 0.9), HORIZONTAL_ALIGNMENT_CENTER, 100)
		elif e.pos.distance_to(cpos) < 3500.0:
			_marker(cam, sz, e.pos, col, "", false, cpos)
	var tgt := u.get_ent(space.target_id)
	if tgt and tgt.alive and tgt.sector == sidx:
		var on := not cam.is_position_behind(tgt.pos)
		var sp := cam.unproject_position(tgt.pos)
		if on and Rect2(Vector2.ZERO, sz).has_point(sp):
			var r := 22.0
			draw_rect(Rect2(sp - Vector2(r, r), Vector2(r, r) * 2), HIVE, false, 2.0)
			_txt(sp + Vector2(r + 4, -6), "%s  %dm" % [tgt.display_name, int(tgt.pos.distance_to(space.player.position))], 16, HIVE)
			_bar(Rect2(sp + Vector2(-r, r + 4), Vector2(r * 2, 4)), tgt.shield_frac(), CYAN)
			_bar(Rect2(sp + Vector2(-r, r + 10), Vector2(r * 2, 4)), tgt.hull_frac(), HIVE)
			if not tgt.can_be_damaged():
				_txt(sp + Vector2(-60, -r - 8), "SHIELDED BY CORE", 14, HIVE, HORIZONTAL_ALIGNMENT_CENTER, 120)
			var lead: Variant = space.player.aim_point
			if lead != null and not cam.is_position_behind(lead):
				var lp := cam.unproject_position(lead)
				draw_arc(lp, 7, 0, TAU, 16, AMBER, 2.0)
		else:
			_edge_arrow(sz, cam, tgt.pos, HIVE)


func _marker(cam: Camera3D, sz: Vector2, wp: Vector3, col: Color, label: String, big: bool, cpos: Vector3) -> void:
	if cam.is_position_behind(wp):
		return
	var sp := cam.unproject_position(wp)
	if not Rect2(Vector2.ZERO, sz).has_point(sp):
		return
	var r := 7.0 if big else 4.0
	var pts := PackedVector2Array([sp + Vector2(0, -r), sp + Vector2(r, 0), sp + Vector2(0, r), sp + Vector2(-r, 0), sp + Vector2(0, -r)])
	draw_polyline(pts, Color(col, 0.85), 1.5)
	if label != "":
		var d := wp.distance_to(cpos)
		var ds := "%.1fkm" % (d / 1000.0) if d > 1000.0 else "%dm" % int(d)
		_txt(sp + Vector2(10, 5), "%s  %s" % [label, ds], 14, Color(col, 0.8))


func _edge_arrow(sz: Vector2, cam: Camera3D, wp: Vector3, col: Color, label: String = "") -> void:
	var local := cam.global_transform.basis.inverse() * (wp - cam.global_position)
	var dir := Vector2(local.x, -local.y).normalized()
	if dir == Vector2.ZERO:
		return
	var c := sz * 0.5
	var p := c + dir * minf(sz.x, sz.y) * 0.42
	var n := dir.orthogonal()
	draw_colored_polygon(PackedVector2Array([p + dir * 14, p - dir * 6 + n * 9, p - dir * 6 - n * 9]), col)
	if label != "":
		var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		_txt(Vector2(clampf(p.x - tw * 0.5, 4.0, sz.x - tw - 4.0), p.y + (24.0 if dir.y < 0.0 else -34.0)), label, 14, col)


# --- Surface ---------------------------------------------------------------------------------
func _draw_surface(sz: Vector2) -> void:
	var c := sz * 0.5
	var cc := Color.WHITE if hit_flash <= 0.0 else HIVE
	for d: Vector2 in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		draw_line(c + d * 6, c + d * 16, cc, 2.0)
	if hit_flash > 0.0:
		for a: float in [0.785, 2.356, 3.927, 5.498]:
			var dd := Vector2(cos(a), sin(a))
			draw_line(c + dd * 12, c + dd * 24, Color.WHITE, 2.5)
	if kill_flash > 0.0:
		var k := kill_flash / 0.6
		draw_rect(Rect2(Vector2.ZERO, sz), Color(1, 0.85, 0.5, k * 0.12))
		for a2: float in [0.785, 2.356, 3.927, 5.498]:
			var d2 := Vector2(cos(a2), sin(a2))
			draw_line(c + d2 * (14 + (1.0 - k) * 14), c + d2 * (30 + (1.0 - k) * 18), Color(HIVE, minf(1.0, k * 2.0)), 4.0)
	var base := Vector2(20, sz.y - 90) if not surface.touch.active else Vector2(20, 130)
	draw_rect(Rect2(base - Vector2(8, 26), Vector2(330, 96)), PANEL)
	var fp := surface.fps
	_txt(base, "SHIELD", 16, DIM)
	_bar(Rect2(base + Vector2(80, -12), Vector2(230, 12)), fp.shield / FpsPlayer.MAX_SHIELD, CYAN)
	_txt(base + Vector2(0, 24), "HEALTH", 16, DIM)
	_bar(Rect2(base + Vector2(80, 12), Vector2(230, 12)), fp.hp / FpsPlayer.MAX_HP, AMBER if fp.hp > 30.0 else HIVE)
	var ammo := "RELOADING" if fp.reload_t > 0.0 else "%d / %d" % [fp.ammo, FpsPlayer.MAG]
	var ammo_y := sz.y - 40 if not surface.touch.active else 250.0
	_txt(Vector2(sz.x - 260, ammo_y), ammo, 32, Color.WHITE, HORIZONTAL_ALIGNMENT_RIGHT, 220)
	_txt(Vector2(0, 120), surface.objective_text(), 22, AMBER, HORIZONTAL_ALIGNMENT_CENTER, sz.x)
	if surface_t < SAVE_NOTICE_SECS:
		_txt(Vector2(0, 150), SAVE_NOTICE, 18, Color(CYAN_HINT, 0.9), HORIZONTAL_ALIGNMENT_CENTER, sz.x)
	if surface.prompt != "":
		_txt(Vector2(0, sz.y * 0.7), surface.prompt, 24, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, sz.x)
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not surface.touch.active:
		_txt(Vector2(0, sz.y * 0.78), "Click to capture mouse", 18, DIM, HORIZONTAL_ALIGNMENT_CENTER, sz.x)
	# Objective markers (VS-005: same-label markers that line up are merged, others stacked).
	var cam := surface.cam
	var items: Array[Dictionary] = []
	for m: Dictionary in surface.markers():
		var wp: Vector3 = m["pos"]
		if cam.is_position_behind(wp):
			continue
		items.append({"sp": cam.unproject_position(wp), "col": m["col"], "label": m["label"],
			"dist": wp.distance_to(cam.global_position)})
	for m: Dictionary in layout_markers(items):
		var sp: Vector2 = m["sp"]
		var col: Color = m["col"]
		for q: Vector2 in m["pts"]:
			draw_arc(q, 9, 0, TAU, 16, col, 2.0)
		var tp: Vector2 = m["text_pos"]
		if tp.y != sp.y:
			draw_line(sp + Vector2(9, 0), tp + Vector2(-2, -5), Color(col, 0.5), 1.0)
		_txt(tp, m["text"], 14, col)


const MARKER_MERGE_PX := 70.0   ## same-label markers closer than this on screen merge into one
const MARKER_LINE_H := 17.0     ## vertical step between stacked marker labels
const MARKER_LABEL_W := 150.0   ## approximate label width, for overlap tests


## Pure layout: items {sp: Vector2, col, label, dist} -> {sp, col, pts, text, text_pos}.
## Same-label items within MARKER_MERGE_PX merge ("2x PYLON 380m", nearest distance); labels
## that still overlap are pushed down so each stays readable.
static func layout_markers(items: Array[Dictionary]) -> Array[Dictionary]:
	var groups: Array[Dictionary] = []
	for it: Dictionary in items:
		var g: Dictionary = {}
		for c: Dictionary in groups:
			if c["label"] == it["label"] and (c["sp"] as Vector2).distance_to(it["sp"]) < MARKER_MERGE_PX:
				g = c
				break
		if g.is_empty():
			groups.append({"label": it["label"], "col": it["col"], "sp": it["sp"], "pts": [it["sp"]],
				"n": 1, "dist": it["dist"]})
		else:
			g["n"] = int(g["n"]) + 1
			(g["pts"] as Array).append(it["sp"])
			g["dist"] = minf(float(g["dist"]), float(it["dist"]))
	groups.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return (a["sp"] as Vector2).y < (b["sp"] as Vector2).y)
	var out: Array[Dictionary] = []
	for g: Dictionary in groups:
		var n := int(g["n"])
		var txt := "%s %dm" % [g["label"], int(float(g["dist"]))]
		if n > 1:
			txt = "%d\u00d7 %s" % [n, txt]
		var tp: Vector2 = (g["sp"] as Vector2) + Vector2(12, 5)
		var moved := true
		while moved:
			moved = false
			for o: Dictionary in out:
				var op: Vector2 = o["text_pos"]
				if absf(op.x - tp.x) < MARKER_LABEL_W and absf(op.y - tp.y) < MARKER_LINE_H:
					tp.y = op.y + MARKER_LINE_H
					moved = true
		out.append({"sp": g["sp"], "col": g["col"], "pts": g["pts"], "text": txt, "text_pos": tp})
	return out


func objective() -> String:
	return objective_for(u, false)


## VS-032: touch players have no F or M key; say ACT / MAP instead.
static func earn_hint(touch: bool) -> String:
	return "Need credits? Dock at the Union Trade Hub (%s) and sell wares" % ("tap ACT" if touch else "F")


static func objective_for(u: Universe, touch: bool) -> String:
	if u.sectors[u.hq.sector].planet_state == "hive":
		return "Fly to planet %s, %s to land, and destroy its Hive Core" % [u.sectors[u.hq.sector].planet_name, "tap ACT" if touch else "press F"]
	var shielded: Array[String] = []
	var exposed: Array[String] = []
	for n: StationData in u.alive_nests():
		if n.shield_locked:
			shielded.append("%s (%s)" % [u.sectors[n.sector].planet_name, u.sectors[n.sector].name])
		else:
			exposed.append(u.sectors[n.sector].name)
	if not exposed.is_empty():
		return "Nest exposed in %s — bring your fleet (%s)" % [", ".join(PackedStringArray(exposed)), "tap MAP, Select warships, then Tap-to-order on the Nest" if touch else "M: select warships, right-click the Nest"]
	if not shielded.is_empty():
		return "Kill the Hive Cores on %s to drop the Nest shields" % ", ".join(PackedStringArray(shielded))
	return "Hold the line"


## VS-047: top-bar income: labelled NET cr/min over the ledger's 60 s window (never a last-sale amount).
## Empty for the first MIN_RATE_SPAN seconds. Rounded to RATE_STEP so it reads steady, and it eases to
## "net 0/min" (not blank, not "+0") as income lapses, so the label never flickers in and out.
const RATE_STEP := 10.0
static func rate_text(p_u: Universe) -> String:
	if p_u.time < CreditLedger.MIN_RATE_SPAN:
		return ""
	var net := roundf(p_u.ledger.net_per_min(p_u.time) / RATE_STEP) * RATE_STEP
	if net == 0.0:
		return "net 0/min"
	return "net %s%s/min" % ["+" if net > 0.0 else "-", _fmt(absf(net))]


## VS-024: "last 5 min" credit breakdown for the map (one category per line) and dock (inline).
static func ledger_text(p_u: Universe, max_lines: int = 10, inline: bool = false) -> String:
	var gross := p_u.ledger.income_per_min(p_u.time)
	var sep := "  ·  " if inline else "\n"
	if gross <= 0.0:   # VS-040: nothing earned yet; say where income comes from instead of "+0"
		var src := p_u.income_sources()
		return "No income yet. Ways to earn:" + sep + sep.join(PackedStringArray(src)) if inline else "No income yet. Ways to earn:\n  " + "\n  ".join(PackedStringArray(src))
	var net := p_u.ledger.net_per_min(p_u.time)
	var head := "Income: net %s%s cr/min (gross +%s)%sLast 5 min:" % ["+" if net >= 0.0 else "-", _fmt(absf(net)), _fmt(gross), sep]
	var parts: Array[String] = []
	var rows := p_u.ledger.breakdown(p_u.time)
	for r: Array in rows.slice(0, max_lines):
		var amt := float(r[1])
		parts.append("%s %s%s" % [CreditLedger.LABELS[r[0]], "+" if amt > 0.0 else "-", _fmt(absf(amt))])
	if parts.is_empty():
		parts.append("no credit changes yet")
	if inline:
		return head + "  " + "  ·  ".join(PackedStringArray(parts))
	return head + "\n  " + "\n  ".join(PackedStringArray(parts))


static func _fmt(v: float) -> String:
	var s := str(int(v))
	var out := ""
	var n := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		n += 1
		if n % 3 == 0 and i > 0 and s[i - 1] != "-":
			out = "," + out
	return out
