class_name WorldDraw
extends RefCounted
## Static drawing helpers for the playfield; `ci` is the CanvasItem to draw on.

const BG := Color("0b1026")
const PLANET := Color("ff8a5c")
const REPULSOR := Color("b48cff")
const BALL := Color("f4f1e8")
const ACCENT := Color("7dffb3")


static func make_stars() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var out: Array = []
	for i in 90:
		out.append(Vector4(rng.randf_range(0.0, 720.0), rng.randf_range(0.0, 1280.0),
			rng.randf_range(1.0, 2.0), rng.randf_range(0.3, 0.8)))
	return out


static func stars(ci: CanvasItem, list: Array) -> void:
	for s in list:
		var v: Vector4 = s
		ci.draw_circle(Vector2(v.x, v.y), v.z, Color(1, 1, 1, v.w))


static func body_color(b: Dictionary) -> Color:
	match int(b["kind"]):
		1: return REPULSOR
		2: return PLANET.lerp(BALL, 0.5)
	return PLANET


static func body(ci: CanvasItem, b: Dictionary, t: float, time: float) -> void:
	var pos := OrbitPhysics.body_pos(b, t)
	var r: float = b["r"]
	var col := body_color(b)
	var kind: int = b["kind"]
	var infl := r * 3.0
	for i in 2:
		var ph := fposmod(time * 0.3 + i * 0.5, 1.0)
		var rad := lerpf(r, infl, ph) if kind != 1 else lerpf(infl, r, ph)
		var a := (1.0 - ph) * 0.35 if kind != 1 else sin(ph * PI) * 0.35
		ci.draw_arc(pos, rad, 0.0, TAU, 64, Color(col.r, col.g, col.b, a), 2.0)
	if kind == 1:
		var pts := PackedVector2Array()
		for i in 12:
			var rr := r * (1.25 if i % 2 == 0 else 0.8)
			pts.append(pos + Vector2.from_angle(time * 0.5 + i * TAU / 12.0) * rr)
		ci.draw_colored_polygon(pts, col.darkened(0.2))
		ci.draw_circle(pos, r * 0.6, col.darkened(0.5))
	else:
		ci.draw_circle(pos, r, col.darkened(0.4))
		ci.draw_circle(pos + Vector2(-0.18, -0.18) * r, r * 0.8, col)


static func cup(ci: CanvasItem, pos: Vector2, r: float) -> void:
	ci.draw_circle(pos, r, Color(0, 0, 0, 0.45))
	ci.draw_arc(pos, r, 0.0, TAU, 48, ACCENT, 4.0)
	var top := pos + Vector2(0, -40)
	ci.draw_line(pos, top, BALL, 3.0)
	ci.draw_colored_polygon(PackedVector2Array([top, top + Vector2(22, 8), top + Vector2(0, 16)]), ACCENT)


static func trail(ci: CanvasItem, pts: PackedVector2Array, tint: float) -> void:
	var n := pts.size()
	var col := BALL.lerp(PLANET, tint)
	for i in n:
		var k := float(i + 1) / n
		ci.draw_circle(pts[i], OrbitPhysics.BALL_RADIUS * k * 0.8, Color(col.r, col.g, col.b, k * 0.5))


static func ball(ci: CanvasItem, pos: Vector2, scale: float = 1.0) -> void:
	ci.draw_circle(pos, OrbitPhysics.BALL_RADIUS * scale + 3.0, Color(1, 1, 1, 0.15))
	ci.draw_circle(pos, OrbitPhysics.BALL_RADIUS * scale, BALL)
