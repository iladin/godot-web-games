class_name MapOverlayDraw
extends RefCounted
## VS-076: stateless draw helpers for the command map's galaxy-inset fleet routes and raid banner.

const AMBER := Color("ffb347")
const HIVE := Color("ff3b8d")
const BANNER_FONT := 16   # VS-074: >= 14 px


## VS-074: every player fleet order that crosses sectors gets an arrowed route line in the galaxy inset,
## with a ship count; hops are drawn along the gate links where the order target is not adjacent.
static func fleet_routes(ci: CanvasItem, u: Universe, r: Rect2, font: Font) -> void:
	var routes: Dictionary = {}   # "from>to" -> count
	for e: SimEntity in u.entities.values():
		var sh := e as ShipData
		if sh == null or sh.faction != Defs.Faction.PLAYER or not sh.alive or sh == u.player_ship:
			continue
		if sh.order in ["goto", "patrol", "escort"] and sh.order_sector != sh.sector and sh.order_sector >= 0 and sh.order_sector < u.sectors.size():
			var k := "%d>%d" % [sh.sector, sh.order_sector]
			routes[k] = int(routes.get(k, 0)) + 1
	for k: String in routes:
		var ft := k.split(">")
		var a := r.position + u.sectors[int(ft[0])].map_pos * r.size
		var b := r.position + u.sectors[int(ft[1])].map_pos * r.size
		if a.distance_to(b) < 4.0:
			continue
		var dir := (b - a).normalized()
		var tip := b - dir * 10.0
		ci.draw_dashed_line(a, tip, Color(AMBER, 0.95), 2.5, 7.0)
		ci.draw_colored_polygon(PackedVector2Array([tip + dir * 7.0, tip - dir * 3.0 + dir.orthogonal() * 5.0, tip - dir * 3.0 - dir.orthogonal() * 5.0]), AMBER)
		var mid := (a + b) * 0.5 + dir.orthogonal() * 8.0
		ci.draw_string(font, mid + Vector2(-20, 4), "×%d" % int(routes[k]), HORIZONTAL_ALIGNMENT_CENTER, 40, 13, AMBER)


## VS-074: raid status as a full-width banner across the top of the main map, 16 px, shrunk only if it would overflow.
static func raid_banner(ci: CanvasItem, text: String, mr: Rect2, font: Font) -> void:
	if text == "":
		return
	var fs := BANNER_FONT
	var w := mr.size.x - 32.0
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var bw := minf(w, tw + 28.0)
	var br := Rect2(mr.position.x + (mr.size.x - bw) * 0.5, mr.position.y + 68.0, bw, fs + 14.0)
	ci.draw_rect(br, Color(0.25, 0.0, 0.1, 0.85))
	ci.draw_rect(br, HIVE, false, 1.5)
	ci.draw_string(font, Vector2(br.position.x, br.position.y + fs + 3.0), text, HORIZONTAL_ALIGNMENT_CENTER, bw, fs, Color(1, 0.85, 0.92))
