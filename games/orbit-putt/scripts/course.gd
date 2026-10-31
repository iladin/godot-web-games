class_name Course
extends RefCounted
## Nine authored holes. Body entries: [x, y, r, kind] (0 planet, 1 repulsor, 2 moon of previous planet).

const HOLES: Array = [
	{"tee": Vector2(360, 1120), "cup": Vector2(360, 240), "par": 2, "bodies": [[360, 700, 70, 0]]},
	{"tee": Vector2(160, 1120), "cup": Vector2(560, 230), "par": 2, "bodies": [[430, 740, 90, 0]]},
	{"tee": Vector2(360, 1120), "cup": Vector2(360, 200), "par": 3, "bodies": [[220, 640, 70, 0], [500, 480, 80, 0]]},
	{"tee": Vector2(600, 1120), "cup": Vector2(120, 300), "par": 3, "bodies": [[360, 700, 110, 0], [140, 880, 40, 1]]},
	{"tee": Vector2(120, 1120), "cup": Vector2(600, 620), "par": 3, "bodies": [[420, 860, 70, 0], [600, 330, 60, 0], [300, 520, 45, 1]]},
	{"tee": Vector2(360, 1120), "cup": Vector2(360, 160), "par": 3, "bodies": [[180, 700, 80, 0], [540, 700, 80, 0], [360, 450, 50, 1]]},
	{"tee": Vector2(600, 1140), "cup": Vector2(140, 180), "par": 3, "bodies": [[380, 640, 90, 0], [380, 640, 22, 2], [150, 560, 45, 1]]},
	{"tee": Vector2(120, 1140), "cup": Vector2(600, 200), "par": 4, "bodies": [[260, 820, 60, 0], [520, 560, 72, 0], [520, 560, 18, 2], [250, 330, 40, 1]]},
	{"tee": Vector2(360, 1140), "cup": Vector2(360, 640), "par": 4, "bodies": [[190, 640, 70, 0], [530, 640, 70, 0], [360, 380, 80, 0], [360, 380, 20, 2], [360, 900, 40, 1]]},
]
const CUP_RADII: Array = [30.0, 27.0, 24.0]
const PREVIEW: Array = [90, 45, 20]


static func count() -> int:
	return HOLES.size()


static func tier(i: int) -> int:
	return clampi(i / 3, 0, 2)


static func preview_steps(i: int) -> int:
	return PREVIEW[tier(i)]


static func cup_radius(i: int) -> float:
	return CUP_RADII[tier(i)]


static func hole(i: int) -> Dictionary:
	var src: Dictionary = HOLES[i]
	var bodies: Array = []
	var parent := Vector2.ZERO
	var parent_r := 0.0
	for e in src["bodies"]:
		var pos := Vector2(float(e[0]), float(e[1]))
		var r := float(e[2])
		var kind: int = e[3]
		var b := {"pos": pos, "r": r, "kind": kind, "moon": false, "strength": 1.0}
		if kind == 1:
			b["strength"] = OrbitPhysics.REPULSOR_STRENGTH
		elif kind == 2:
			b["moon"] = true
			b["strength"] = OrbitPhysics.MOON_STRENGTH
			b["center"] = parent
			b["orbit_r"] = parent_r + OrbitPhysics.MOON_GAP
			b["speed"] = OrbitPhysics.MOON_SPEED
			b["phase"] = 0.0
		else:
			parent = pos
			parent_r = r
		bodies.append(b)
	return {"tee": src["tee"], "cup": src["cup"], "par": src["par"], "bodies": bodies,
		"cup_r": cup_radius(i), "preview": preview_steps(i)}
