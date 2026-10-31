class_name Fx
extends RefCounted
## Particles (confetti, smoke), floating text popups and falling life icons.

var particles: Array[Dictionary] = []
var popups: Array[Dictionary] = []
var falls: Array[Dictionary] = []


func burst(at: Vector2, col: Color, count: int) -> void:
	for i in count:
		var a := randf() * TAU
		var v := randf_range(80.0, 340.0)
		particles.append({"p": at, "v": Vector2(cos(a), sin(a)) * v, "c": col, "t": 0.0, "life": randf_range(0.5, 0.9), "r": randf_range(3.0, 6.0), "g": 420.0})


func smoke(at: Vector2) -> void:
	particles.append({"p": at, "v": Vector2(randf_range(-14.0, 14.0), -30.0), "c": Color(0.85, 0.88, 0.95), "t": 0.0, "life": 0.7, "r": 6.0, "g": 0.0})


func popup(at: Vector2, text: String, col: Color, size: int = 40) -> void:
	popups.append({"p": at, "s": text, "c": col, "t": 0.0, "size": size})


func fall(at: Vector2) -> void:
	falls.append({"p": at, "v": Vector2(randf_range(-60.0, 60.0), -260.0), "t": 0.0})


func update(delta: float, popup_time: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		var q := particles[i]
		q["t"] += delta
		q["v"] += Vector2(0.0, q["g"] * delta)
		q["p"] += q["v"] * delta
		if q["t"] >= q["life"]:
			particles.remove_at(i)
	for i in range(popups.size() - 1, -1, -1):
		popups[i]["t"] += delta
		if popups[i]["t"] >= popup_time:
			popups.remove_at(i)
	for i in range(falls.size() - 1, -1, -1):
		var f := falls[i]
		f["t"] += delta
		f["v"] += Vector2(0.0, 1500.0 * delta)
		f["p"] += f["v"] * delta
		if f["t"] > 1.2:
			falls.remove_at(i)


func draw(c: CanvasItem, font: Font, ofs: Vector2, popup_time: float) -> void:
	for q in particles:
		var k: float = 1.0 - float(q["t"]) / float(q["life"])
		var col: Color = q["c"]
		col.a = k * (0.5 if q["g"] == 0.0 else 1.0)
		var r: float = q["r"] * (1.0 + (1.0 - k) * 1.5 if q["g"] == 0.0 else 1.0)
		c.draw_circle(ofs + q["p"], r, col)
	for pu in popups:
		var k2: float = float(pu["t"]) / popup_time
		var col2: Color = pu["c"]
		col2.a = 1.0 - k2 * k2
		var pos: Vector2 = pu["p"] + ofs + Vector2(-100.0, -60.0 * (1.0 - pow(1.0 - k2, 2.0)))
		c.draw_string(font, pos, pu["s"], HORIZONTAL_ALIGNMENT_CENTER, 200.0, pu["size"], col2)
