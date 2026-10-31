extends RefCounted
## Static drawing helpers for Junction. Every function draws onto `c` from inside its _draw().

const BG := Color("1b1f2a")
const TRACK := Color("8a93a6")
const SLEEPER := Color("5a6275")
const ACCENT := Color("ffd166")
const DANGER := Color("ff5d73")
const TRAIN_COLOURS: Array[Color] = [Color("4cc9f0"), Color("f72585"), Color("80ed99"), Color("ff9f1c"), Color("b388ff")]
const RAIL_OFFSET := 7.0
const SLEEPER_STEP := 22.0
const CAR_LEN := 30.0
const CAR_W := 22.0
const SWITCH_HIT_R := 64.0
const SW_LEFT := Vector2(-0.6, 0.8)
const SW_RIGHT := Vector2(0.6, 0.8)


static func text(c: CanvasItem, font: Font, s: String, cx: float, y: float, size: int, col: Color, w: float = 700.0) -> void:
	c.draw_string(font, Vector2(cx - w * 0.5, y), s, HORIZONTAL_ALIGNMENT_CENTER, w, size, col)


static func background(c: CanvasItem, size: Vector2) -> void:
	c.draw_rect(Rect2(Vector2.ZERO, size), BG)
	var dot := Color(1, 1, 1, 0.06)
	for x in range(20, int(size.x), 40):
		for y in range(20, int(size.y), 40):
			c.draw_rect(Rect2(x - 1, y - 1, 3, 3), dot)


static func _offset_line(p: PackedVector2Array, d: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in p.size():
		var a := p[maxi(i - 1, 0)]
		var b := p[mini(i + 1, p.size() - 1)]
		var n := (b - a).normalized().orthogonal()
		out.append(p[i] + n * d)
	return out


static func edges(c: CanvasItem, switches: Dictionary, ofs: Vector2) -> void:
	for e: Array in Yard.edges():
		var from_id: String = e[0]
		var node: Dictionary = Yard.NODES[from_id]
		var open := true
		if node["kind"] == "switch":
			var chosen: String = node["right"] if bool(switches.get(from_id, false)) else node["left"]
			open = chosen == e[1]
		var p := Yard.edge_points(from_id, e[1])
		for i in p.size():
			p[i] += ofs
		var col := TRACK if open else TRACK.darkened(0.45)
		var scol := SLEEPER if open else SLEEPER.darkened(0.3)
		var len := 0.0
		for i in p.size() - 1:
			len += p[i].distance_to(p[i + 1])
		var d := 10.0
		while d < len:
			var s := Train.sample(p, d)
			var nrm: Vector2 = (s[1] as Vector2).orthogonal() * (RAIL_OFFSET + 6.0)
			c.draw_line(s[0] - nrm, s[0] + nrm, scol, 4.0)
			d += SLEEPER_STEP
		c.draw_polyline(_offset_line(p, RAIL_OFFSET), col, 3.0)
		c.draw_polyline(_offset_line(p, -RAIL_OFFSET), col, 3.0)


static func glyph(c: CanvasItem, idx: int, at: Vector2, r: float, col: Color) -> void:
	match idx:
		0:
			c.draw_circle(at, r, col)
		1:
			c.draw_rect(Rect2(at - Vector2(r, r) * 0.9, Vector2(r, r) * 1.8), col)
		2:
			c.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -r), at + Vector2(r, r * 0.8), at + Vector2(-r, r * 0.8)]), col)
		3:
			c.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -r * 1.2), at + Vector2(r * 1.2, 0), at + Vector2(0, r * 1.2), at + Vector2(-r * 1.2, 0)]), col)
		_:
			var pts := PackedVector2Array()
			for i in 10:
				var rr := r * 1.15 if i % 2 == 0 else r * 0.5
				var a := -PI / 2.0 + i * PI / 5.0
				pts.append(at + Vector2(cos(a), sin(a)) * rr)
			c.draw_colored_polygon(pts, col)


static func tunnel(c: CanvasItem, font: Font, glow: int, t: float, ofs: Vector2) -> void:
	var at := Yard.pos("entry") + ofs
	c.draw_circle(at, 46.0, Color("0c0e14"))
	if glow >= 0:
		var pulse := 0.5 + 0.5 * sin(t * (22.0 if t < 0.5 else 9.0))
		var col := TRAIN_COLOURS[glow]
		c.draw_circle(at, 40.0, Color(col, 0.25 + 0.3 * pulse))
		glyph(c, glow, at + Vector2(0, -6), 16.0, Color(1, 1, 1, 0.9))
	c.draw_arc(at, 46.0, PI, TAU, 24, ACCENT, 8.0)
	c.draw_rect(Rect2(at.x - 50.0, at.y - 1.0, 100.0, 8.0), BG)


static func station(c: CanvasItem, idx: int, active: bool, flash: float, ofs: Vector2) -> void:
	var at := Yard.station_pos(idx) + ofs
	var col := TRAIN_COLOURS[idx]
	var a := 1.0 if active else 0.3
	c.draw_rect(Rect2(at.x - 50.0, at.y, 100.0, 70.0), Color(col.darkened(0.55), a))
	c.draw_rect(Rect2(at.x - 50.0, at.y, 100.0, 70.0), Color(col, a), false, 3.0)
	c.draw_rect(Rect2(at.x - 56.0, at.y - 6.0, 112.0, 14.0), Color(col, a).lerp(Color.WHITE, flash))
	glyph(c, idx, at + Vector2(0, 38), 17.0, Color(1, 1, 1, a))
	if not active:
		c.draw_rect(Rect2(at.x - 12.0, at.y + 36.0, 24.0, 18.0), Color(0.75, 0.78, 0.85))
		c.draw_arc(at + Vector2(0, 36), 8.0, PI, TAU, 10, Color(0.75, 0.78, 0.85), 3.0)


static func switch_node(c: CanvasItem, font: Font, id: String, num: int, anim: float, pulse: float, shake: float, selected: bool, ofs: Vector2) -> void:
	var at := Yard.pos(id) + ofs + Vector2(sin(shake * 90.0) * shake * 40.0, 0.0)
	c.draw_arc(at, SWITCH_HIT_R, 0.0, TAU, 32, Color(ACCENT, 0.1), 2.0)
	var e := 1.0 - pow(1.0 - anim, 3.0)
	var dir := SW_LEFT.lerp(SW_RIGHT, e).normalized()
	var r := 28.0 * (1.0 + 0.25 * pulse)
	c.draw_circle(at, r, BG)
	c.draw_arc(at, r, 0.0, TAU, 28, ACCENT, 4.0)
	var tip := at + dir * (r + 16.0)
	c.draw_colored_polygon(PackedVector2Array([tip, at + dir * (r + 2.0) + dir.orthogonal() * 10.0, at + dir * (r + 2.0) - dir.orthogonal() * 10.0]), ACCENT)
	c.draw_string(font, at + Vector2(-20.0, 11.0), str(num), HORIZONTAL_ALIGNMENT_CENTER, 40.0, 32, ACCENT)
	if selected:
		c.draw_arc(at, SWITCH_HIT_R - 8.0, 0.0, TAU, 40, ACCENT, 4.0)


static func loco_icon(c: CanvasItem, at: Vector2, col: Color, s: float = 1.0) -> void:
	c.draw_rect(Rect2(at + Vector2(-18, -9) * s, Vector2(36, 18) * s), col)
	c.draw_rect(Rect2(at + Vector2(-18, -17) * s, Vector2(14, 10) * s), col)
	c.draw_circle(at + Vector2(-8, 11) * s, 5.0 * s, col.darkened(0.4))
	c.draw_circle(at + Vector2(10, 11) * s, 5.0 * s, col.darkened(0.4))


static func train(c: CanvasItem, t: Train, ofs: Vector2) -> void:
	var col := TRAIN_COLOURS[t.colour]
	for i in range(Train.CARS - 1, -1, -1):
		var cr := t.car(i)
		if not cr[2]:
			continue
		var tan: Vector2 = cr[1]
		c.draw_set_transform(ofs + (cr[0] as Vector2), tan.angle(), Vector2.ONE)
		var body := col if i == 0 else col.darkened(0.25)
		c.draw_rect(Rect2(-CAR_LEN * 0.5, -CAR_W * 0.5, CAR_LEN, CAR_W), body)
		c.draw_rect(Rect2(-CAR_LEN * 0.5, -CAR_W * 0.5, CAR_LEN, CAR_W), Color(0, 0, 0, 0.5), false, 2.0)
		if i == 0:
			c.draw_rect(Rect2(-CAR_LEN * 0.5, -CAR_W * 0.5, 10.0, CAR_W), col.darkened(0.45))
			c.draw_circle(Vector2(CAR_LEN * 0.5 - 2.0, 0.0), 4.0, Color("fff7c2"))
			glyph(c, t.colour, Vector2(3, 0), 5.5, Color.WHITE)
	c.draw_set_transform(ofs, 0.0, Vector2.ONE)
