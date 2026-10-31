class_name LanternBot
extends RefCounted
## Autoplay bot: looks ahead and returns +1 (press jump), -1 (release) or 0.
## Main feeds it through real InputEventAction events, so it exercises the input path.

var holding := false
var press_t := 0.0
var cut_after := -1.0   # release this many seconds after pressing (low hop), -1 = hold to apex


func decide(w: LanternWorld) -> int:
	var px := w.player_x()
	var sp := w.speed
	if holding:
		var age := w.t - press_t
		if (cut_after >= 0.0 and age >= cut_after) or w.vel_y > 0.0:
			holding = false
			return -1
		return 0
	# nearest hazard and pit ahead
	var haz_dx := 1e9
	var low_hop := false
	for h: Dictionary in w.hazards:
		var dx: float = h.x - px
		if dx > -30.0 and dx < haz_dx and h.kind == LanternWorld.STALAG:
			haz_dx = dx
			low_hop = false
			for h2: Dictionary in w.hazards:
				if h2.kind == LanternWorld.SPIKE and absf(h2.x - h.x) < 4.0:
					low_hop = true
	var pit_dx := 1e9
	var pit_w := 0.0
	for i in w.ground.size() - 1:
		var e: float = w.ground[i].y
		if e - px > -10.0:
			pit_dx = e - px
			pit_w = w.ground[i + 1].x - e
			break
	if not w.on_ground:
		if w.jumps_left > 0 and w.vel_y > 150.0 and RunnerLogic.is_over_pit(px + sp * 0.2, w.ground) and w.pos_y > RunnerLogic.GROUND_Y - 60.0:
			return _press(w, -1.0)
		return 0
	var take_off := clampf((0.75 * sp - pit_w) * 0.5, 4.0, 70.0)
	if pit_dx < take_off:
		return _press(w, -1.0)
	var lead := sp * (0.2 if not low_hop else 0.21)
	if haz_dx < lead:
		return _press(w, 0.08 if low_hop else -1.0)
	return 0


func _press(w: LanternWorld, cut: float) -> int:
	holding = true
	press_t = w.t
	cut_after = cut
	return 1
