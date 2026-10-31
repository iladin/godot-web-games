class_name Fx
extends RefCounted
## Simple particle bursts (dots that drift and fade).

var parts: Array = []


func burst(pos: Vector2, color: Color, n: int, speed: float) -> void:
	for i in n:
		var life := randf_range(0.4, 0.9)
		parts.append({"p": pos, "v": Vector2.from_angle(randf() * TAU) * randf_range(0.3, 1.0) * speed,
			"life": life, "max": life, "c": color, "s": randf_range(2.5, 5.5)})


func update(dt: float) -> void:
	var i := parts.size() - 1
	while i >= 0:
		var q: Dictionary = parts[i]
		q["life"] = float(q["life"]) - dt
		if float(q["life"]) <= 0.0:
			parts.remove_at(i)
		else:
			q["p"] = (q["p"] as Vector2) + (q["v"] as Vector2) * dt
			q["v"] = (q["v"] as Vector2) * (1.0 - 2.0 * dt)
		i -= 1


func draw(ci: CanvasItem) -> void:
	for q in parts:
		var c: Color = q["c"]
		var k: float = float(q["life"]) / float(q["max"])
		c.a = k
		ci.draw_circle(q["p"], float(q["s"]) * (0.5 + 0.5 * k), c)
