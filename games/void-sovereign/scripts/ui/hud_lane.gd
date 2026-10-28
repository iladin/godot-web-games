class_name HudLane
extends RefCounted
## VS-058: the touch HUD's single message lane. One strip along the bottom edge (below every
## touch button) shows ONE of raid forecast / sortie / objective / trade hint / tutorial tip, so
## none of them can overlap each other or the controls. Desktop HUD keeps its own layout.
## Priority: raid forecast > sortie > objective (fresh) > trade hint > tip > objective (idle).
## The objective counts as "fresh" for OBJ_FRESH seconds after it changes (or the run starts);
## after that it only fills the lane when nothing else wants it, so first-run tips still appear.

const LANE_H := 28.0
const LANE_BOTTOM := 2.0
const MARGIN_X := 16.0
const OBJ_FRESH := 10.0
const PRIORITY: Array[String] = ["forecast", "sortie", "objective", "trade", "tip", "objective_idle"]

static var kind: String = ""   ## lane occupant drawn this frame (touch + flight only); TutorialHints draws only on "tip"


static func rect(sz: Vector2) -> Rect2:
	return Rect2(MARGIN_X, sz.y - LANE_H - LANE_BOTTOM, sz.x - MARGIN_X * 2.0, LANE_H)


## cands: kind -> text (empty / missing = no candidate; "tip" just needs any non-empty text).
static func pick(cands: Dictionary) -> String:
	for k: String in PRIORITY:
		if str(cands.get(k, "")) != "":
			return k
	return ""


## True when the lane strip stays clear of a circle (centre, radius) by at least gap px.
static func clear_of(sz: Vector2, c: Vector2, r: float, gap: float = 0.0) -> bool:
	var rc := rect(sz)
	var nearest := Vector2(clampf(c.x, rc.position.x, rc.end.x), clampf(c.y, rc.position.y, rc.end.y))
	return nearest.distance_to(c) >= r + gap
