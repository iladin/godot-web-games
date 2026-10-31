class_name EchoHud
extends Node2D
## Text/HUD overlay drawn above the pads: title, game over, hearts, score, banner, pause.

const HUD_COL := Color("f2f0ff")
const HEART := Color("ff4f5e")
const HEART_EMPTY := Color("2a2645")

var game: Node2D  # main.gd; read-only access to its state
var _font: Font = ThemeDB.fallback_font


func _process(_d: float) -> void:
	queue_redraw()


func _text(s: String, y: float, size: int, col: Color, x: float = 0.0, w: float = 720.0, align: int = HORIZONTAL_ALIGNMENT_CENTER) -> void:
	draw_string(_font, Vector2(x, y), s, align, w, size, col)


func _heart(c: Vector2, s: float, col: Color) -> void:
	draw_circle(c + Vector2(-s * 0.5, -s * 0.3), s * 0.55, col)
	draw_circle(c + Vector2(s * 0.5, -s * 0.3), s * 0.55, col)
	draw_colored_polygon(PackedVector2Array([c + Vector2(-s * 1.03, -s * 0.05), c + Vector2(s * 1.03, -s * 0.05), c + Vector2(0, s)]), col)


func _draw() -> void:
	var accent: Color = game.ACCENT
	var gold: Color = game.GOLD
	var t: float = game.state_time
	match game.state:
		game.State.TITLE:
			_text("ECHO TAP", 420, 96, accent)
			_text("Watch the phrase. Echo it on beat.", 500, 32, HUD_COL)
			_text("Best %d" % game.best, 570, 36, gold)
			_text("Tap or press Space to start", 760, 40, gold.lerp(Color.WHITE, 0.5 + 0.5 * sin(t * 4.0)))
			_text("Arrows / WASD  or  tap the pads", 840, 30, HUD_COL)
			_text("Esc / P to pause", 890, 30, Color(HUD_COL, 0.6))
			for i in 4:
				var a: float = deg_to_rad(-90.0 + 90.0 * float(i))
				draw_circle(Vector2(360, 1050) + Vector2(cos(a), sin(a)) * 60.0, 28.0 + 4.0 * sin(t * 5.0 + i), Pads.COLORS[i])
		game.State.PLAYING:
			for i in game.LIVES:
				_heart(Vector2(40 + i * 56, 56), 14.0, HEART if i < game.lives else HEART_EMPTY)
			_text("%d" % game.score, 78, 52, HUD_COL)
			var mult := EchoLogic.multiplier(game.streak)
			_text("x%.2f" % mult if mult > 1.0 else "", 118, 30, gold)
			_text("R%d  %d BPM" % [game.round_num, int(EchoLogic.bpm_for_round(game.round_num))], 150, 28, accent, 0.0, 700.0, HORIZONTAL_ALIGNMENT_RIGHT)
			var banner := "GET READY"
			var col := HUD_COL
			if game.phase == game.Phase.LISTEN:
				banner = "LISTEN"
				col = accent
			elif game.phase == game.Phase.ECHO:
				banner = "ECHO"
				col = gold
			elif game.phase == game.Phase.RESULT:
				banner = "NICE!" if not game.round_failed else "AGAIN"
				col = HEART if game.round_failed else accent
			_text(banner, 330, 56, col)
			draw_rect(game.PAUSE_RECT, Color(1, 1, 1, 0.12))
			draw_rect(Rect2(game.PAUSE_RECT.position + Vector2(28, 24), Vector2(10, 40)), HUD_COL)
			draw_rect(Rect2(game.PAUSE_RECT.position + Vector2(50, 24), Vector2(10, 40)), HUD_COL)
		game.State.GAME_OVER:
			_text("GAME OVER", 420, 84, HEART)
			_text("Score %d" % game.score, 520, 56, HUD_COL)
			_text("NEW BEST!" if game.new_best else "Best %d" % game.best, 590, 40, gold if game.new_best else accent)
			_text("Reached round %d" % game.round_num, 650, 34, HUD_COL)
			if t > game.RESTART_DELAY:
				_text("Tap or press Space to retry", 800, 36, gold.lerp(Color.WHITE, 0.5 + 0.5 * sin(t * 4.0)))
	if game.paused:
		draw_rect(Rect2(0, 0, 720, 1280), Color(0, 0, 0, 0.65))
		_text("PAUSED", 620, 72, HUD_COL)
		_text("Tap or press Space to resume", 690, 34, HUD_COL)
