class_name AutoBot
extends RefCounted
## --autoplay driver: solves each stroke, then "drags" through the game's own pointer handlers.

var stage := 0
var wait := 0.0
var shot := Vector2.ZERO
var p0 := Vector2.ZERO


func reset() -> void:
	stage = 0


func drive(g: Node2D, delta: float) -> void:
	wait -= delta
	if g.state != g.State.PLAYING:
		if wait <= 0.0 and g.state_time > g.RESTART_DELAY:
			g._tap()
			wait = 0.5
		return
	if g.phase != g.Phase.AIM:
		return
	if stage == 0:
		shot = Solver.best_shot(g.ball_pos, g.bodies, g.t, g.cup, g.cup_r)
		p0 = g.ball_pos
		g._pointer_down(p0)
		stage = 1
		wait = g.AUTOPLAY_AIM_DELAY
	else:
		var k := clampf(1.0 - wait / g.AUTOPLAY_AIM_DELAY, 0.0, 1.0)
		var at: Vector2 = p0 - Vector2.from_angle(shot.x) * shot.y * g.DRAG_FULL * k
		g._pointer_move(at)
		if wait <= 0.0:
			g._pointer_up(at)
			stage = 0
