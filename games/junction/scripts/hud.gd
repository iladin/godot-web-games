extends RefCounted
## Title / HUD / game-over overlays for Junction.

const R := preload("res://scripts/render.gd")


static func draw(m: Node2D, size: Vector2) -> void:
	var cx := size.x * 0.5
	match m.state:
		m.State.TITLE:
			m.draw_rect(Rect2(Vector2.ZERO, size), Color(0.1, 0.12, 0.16, 0.9))
			R.text(m, m.font, "JUNCTION", cx, size.y * 0.30, 88, R.ACCENT)
			R.text(m, m.font, "Flip the points so every train", cx, size.y * 0.37, 32, Color.WHITE)
			R.text(m, m.font, "reaches its matching station", cx, size.y * 0.405, 32, Color.WHITE)
			R.text(m, m.font, "Tap a switch  |  keys 1-4", cx, size.y * 0.50, 30, Color("8a93a6"))
			R.text(m, m.font, "Tap or press Space", cx, size.y * 0.62, 38, R.ACCENT.lerp(Color.WHITE, 0.5 + 0.5 * sin(m.state_time * 4.0)))
			R.text(m, m.font, "Best %d" % m.best, cx, size.y * 0.70, 32, Color.WHITE)
		m.State.PLAYING:
			_playing(m, size)
		m.State.GAME_OVER:
			_playing(m, size)
			m.draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.09, 0.13, 0.82))
			R.text(m, m.font, "DERAILED!", cx, size.y * 0.36, 84, R.DANGER)
			R.text(m, m.font, "Score %d" % m.score, cx, size.y * 0.45, 48, Color.WHITE)
			R.text(m, m.font, "NEW BEST!" if m.new_best else "Best %d" % m.best, cx, size.y * 0.51, 38, R.ACCENT)
			if m.state_time > m.RESTART_DELAY:
				R.text(m, m.font, "Tap or press Space to retry", cx, size.y * 0.64, 32, Color.WHITE)
	if m.paused:
		m.draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.6))
		R.text(m, m.font, "PAUSED - tap to resume", cx, size.y * 0.5, 38, Color.WHITE)


static func _playing(m: Node2D, size: Vector2) -> void:
	R.text(m, m.font, "%d" % m.score, size.x * 0.5, 90.0, 56, Color.WHITE)
	for i in m.lives:
		R.loco_icon(m, Vector2(50.0 + i * 58.0, 60.0), R.DANGER)
	for f in m.fx.falls:
		R.loco_icon(m, f["p"], Color(R.DANGER, 0.8))
	if m.combo > 0:
		R.text(m, m.font, "x%d" % Yard.multiplier(m.combo), size.x - 100.0, 62.0, 44, R.ACCENT, 160.0)
		R.text(m, m.font, "streak %d" % m.combo, size.x - 100.0, 98.0, 30, Color.WHITE, 160.0)
	if m.state == m.State.PLAYING and m.delivered < 6:
		R.text(m, m.font, "Tap switches or press 1-4", size.x * 0.5, size.y - 40.0, 28, Color(1, 1, 1, 0.55))
