class_name LanternHud
extends Node2D
## Screen-space overlay: score, light gauge, pause button, title / game-over text, flash.

const AMBER := Color("ffb347")
const FLAME := Color("ffe9a8")
const DANGER := Color("e2493b")
const PAUSE_SIZE := 88.0

var mode := 0               # 0 title, 1 playing, 2 game over
var score := 0
var best := 0
var new_best := false
var dist_m := 0
var light_frac := 1.0
var low_light := false
var out_warn := false
var t := 0.0
var flash := 0.0
var paused := false
var show_retry := false
var font: Font = ThemeDB.fallback_font


func pause_rect() -> Rect2:
	return Rect2(get_viewport_rect().size.x - PAUSE_SIZE - 12.0, 12.0, PAUSE_SIZE, PAUSE_SIZE)


func _process(_dt: float) -> void:
	queue_redraw()


func _draw() -> void:
	var size := get_viewport_rect().size
	match mode:
		0:
			_text("LANTERN RUN", size.y * 0.30, 76, AMBER)
			_text("Outrun the dark.", size.y * 0.36, 34, FLAME)
			_text("Best  %d" % best, size.y * 0.45, 40, FLAME)
			_text("Space / Up / Tap = jump", size.y * 0.55, 30, Color.WHITE)
			_text("Jump again in the air = double jump", size.y * 0.59, 30, Color.WHITE)
			_text("Grab oil to keep your light alive", size.y * 0.63, 30, Color.WHITE)
			_text("Tap or press Space to start", size.y * 0.76, 38, AMBER.lerp(Color.WHITE, 0.5 + 0.5 * sin(t * 4.0)))
		1:
			_text("%d" % score, 80.0, 60, FLAME)
			_text("%d m" % dist_m, 122.0, 30, AMBER)
			var bar := Rect2(24.0, 30.0, 220.0, 22.0)
			draw_rect(bar, Color(0, 0, 0, 0.6))
			var col := DANGER if low_light else AMBER
			draw_rect(Rect2(bar.position, Vector2(bar.size.x * clampf(light_frac, 0.0, 1.0), bar.size.y)), col)
			draw_rect(bar, Color(FLAME, 0.7), false, 2.0)
			draw_string(font, Vector2(24.0, 84.0), "LIGHT", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, col)
			var pr := pause_rect()
			draw_rect(pr, Color(0, 0, 0, 0.45))
			draw_rect(Rect2(pr.position + Vector2(28, 24), Vector2(12, 40)), FLAME)
			draw_rect(Rect2(pr.position + Vector2(48, 24), Vector2(12, 40)), FLAME)
			if out_warn:
				_text("LANTERN DYING - GRAB OIL!", size.y * 0.25, 36, DANGER)
			elif t < 4.0:
				_text("Tap to jump - tap again in the air", size.y * 0.25, 30, Color(FLAME, clampf(4.0 - t, 0.0, 1.0)))
		2:
			_text("THE DARK TAKES YOU", size.y * 0.30, 56, DANGER)
			_text("Score %d" % score, size.y * 0.40, 56, FLAME)
			_text("%d m" % dist_m, size.y * 0.45, 32, AMBER)
			_text("NEW BEST!" if new_best else "Best %d" % best, size.y * 0.52, 40, AMBER)
			if show_retry:
				_text("Tap or press Space to retry", size.y * 0.66, 34, Color.WHITE)
	if flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, clampf(flash, 0.0, 1.0) * 0.8))
	if paused:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.65))
		_text("PAUSED", size.y * 0.48, 64, FLAME)
		_text("Tap or press Esc to resume", size.y * 0.54, 32, Color.WHITE)


func _text(s: String, y: float, fs: int, color: Color) -> void:
	draw_string(font, Vector2(0.0, y), s, HORIZONTAL_ALIGNMENT_CENTER, get_viewport_rect().size.x, fs, color)
