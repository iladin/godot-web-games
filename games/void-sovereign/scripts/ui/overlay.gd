class_name Overlay
extends Control
## Title, pause and end screens.

const AMBER := Color("ffb347")
const CYAN := Color("5ee6ff")
const HIVE := Color("ff3b8d")

var screen: String = "title"     # title | pause | over | none
var won: bool = false
var score: int = 0
var best: int = 0
var new_best: bool = false
var stats: String = ""
var t: float = 0.0
var touch_hint: bool = false
var font: Font = ThemeDB.fallback_font


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	t += delta
	visible = screen != "none"
	if visible:
		queue_redraw()


func _line(y: float, s: String, fs: int, c: Color) -> void:
	draw_string(font, Vector2(2, y + 2), s, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, Color(0, 0, 0, 0.8))
	draw_string(font, Vector2(0, y), s, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, c)


func _draw() -> void:
	var h := size.y
	match screen:
		"title":
			draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.45))
			_line(h * 0.25, "VOID SOVEREIGN", 76, AMBER)
			_line(h * 0.25 + 44, "Trade · Command · Land · Fight", 26, CYAN)
			var lines: Array[String] = [
				"Two Hive Nests are shielded by Cores on their planets.",
				"Land, fight through on foot, kill the Cores — then send your fleet to burn the Nests.",
				"Earn credits trading, mining and with stations. Keep your HQ alive.",
				"",
				"FLIGHT  mouse/arrows steer · W/S throttle · LMB/Space fire · R target · G fleet attack · F dock/land · T travel · M map",
				"FOOT  WASD · mouse look · LMB fire · R reload · Space jump · F board ship · N sound on/off",
				"MAP  LMB select · drag box · RMB order · buy ships & build stations",
			]
			var y := h * 0.25 + 100
			for l: String in lines:
				_line(y, l, 19, Color(1, 1, 1, 0.85))
				y += 28
			if touch_hint:
				_line(y + 6, "Touch: left stick steers/moves · on-screen buttons", 19, CYAN)
			_line(h * 0.86, "Click, tap or press Space to launch", 32, AMBER.lerp(Color.WHITE, 0.5 + 0.5 * sin(t * 4.0)))
			if best > 0:
				_line(h * 0.92, "Best score %d" % best, 20, Color(1, 1, 1, 0.6))
		"pause":
			draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.6))
			_line(h * 0.5, "PAUSED — click or press a key to resume", 36, Color.WHITE)
		"over":
			draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.65))
			_line(h * 0.3, "THE HIVE IS BROKEN" if won else "HQ LOST", 72, AMBER if won else HIVE)
			_line(h * 0.3 + 60, stats, 22, Color(1, 1, 1, 0.85))
			_line(h * 0.5, "Score %d" % score, 48, Color.WHITE)
			_line(h * 0.5 + 46, "NEW BEST!" if new_best else "Best %d" % best, 30, CYAN)
			if t > 0.8:
				_line(h * 0.75, "Click, tap or press Space to play again", 30, AMBER.lerp(Color.WHITE, 0.5 + 0.5 * sin(t * 4.0)))
