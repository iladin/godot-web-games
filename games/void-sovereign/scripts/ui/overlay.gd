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
var continue_time: float = -1.0   # saved run time in seconds; < 0 = no valid save (VS-027)
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


## Screen-space rectangle of the title's Continue button (also used for click/tap hit-testing).
func continue_rect() -> Rect2:
	var w := 380.0
	return Rect2(get_global_rect().position + Vector2((size.x - w) * 0.5, size.y * 0.765), Vector2(w, 44))


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
				"FLIGHT  mouse/arrows steer · W/S throttle · LMB/Space fire · R target · G wing attack · C wing escort · V wing hold · F dock/land · T travel · M map",
				"FOOT  WASD · mouse look · LMB fire · R reload · Space jump · F board ship · N sound on/off",
				"MAP  LMB select · drag box · RMB order · buy ships & build stations",
				"P pause · H skip tips",
			]
			var y := h * 0.25 + 100
			for l: String in lines:
				_line(y, l, 19, Color(1, 1, 1, 0.85))
				y += 28
			if touch_hint:
				_line(y + 6, "Touch: left stick steers/moves · on-screen buttons", 19, CYAN)
			var pulse := AMBER.lerp(Color.WHITE, 0.5 + 0.5 * sin(t * 4.0))
			if continue_time >= 0.0:
				var r := Rect2(Vector2((size.x - 380.0) * 0.5, h * 0.765), Vector2(380, 44))
				draw_rect(r, Color(0.02, 0.1, 0.14, 0.9))
				draw_rect(r, CYAN, false, 2.0)
				_line(r.position.y + 31, "Continue (%d:%02d)  [C]" % [int(continue_time / 60.0), int(continue_time) % 60], 28, CYAN)
			_line(h * 0.86, "Click, tap or press Space to launch" if continue_time < 0.0 else "Or click, tap or press Space for a New Game", 32 if continue_time < 0.0 else 26, pulse)
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
