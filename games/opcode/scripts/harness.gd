extends RefCounted
## Opcode test harness: the autoplay bot (check.sh --autoplay) and --shot screenshot scenarios.

const Game := preload("res://scripts/game.gd")
const Puzzles := preload("res://scripts/puzzles.gd")

var m: Node2D  # main.gd


func bot_step() -> void:
	match m.game.screen:
		Game.Screen.TITLE, Game.Screen.WIN:
			m._act("start")
		Game.Screen.SELECT:
			m._act("open %d" % (m.bot_puzzle % Puzzles.count() + 1))
		Game.Screen.EDIT:
			if not m.game.result.is_empty():
				m._act("ok")
				m.bot_puzzle += 1
				m._act("open %d" % (m.bot_puzzle % Puzzles.count() + 1))
			elif not m.game.animating:
				var ref := str(Puzzles.all()[m.game.puzzle].ref).replace("\n", " | ")
				m._act("program " + ref)
				m._act("animate")
				m.run_speed = 160.0


func run_shot(scenario: String) -> void:
	if scenario == "title":
		m.bridge.capture_after(30)
		return
	m._act("start")
	for i in 9:
		m._act("open %d" % (i + 1))
		m._act("program " + str(Puzzles.all()[i].ref).replace("\n", " | "))
		m._act("run")
		m._act("ok")
	m._act("open 2")
	m._act("program IN | ADD 2 | ADD 3 | OUT")
	m._act("run")
	m._act("ok")
	match scenario:
		"select":
			m._act("menu")
		"edit", "pending":
			m._act("open 10")
			m._act("program IN | JEZ A | JGZ B | LDA -1")
			if scenario == "pending":
				m.pending_op = "ADD"
				m.pending_num = "-12"
				m.buffer = "JMP A"
		"running":
			m._act("open 9")
			m._act("animate")
			for k in 23:
				m.game.tick(1)
			m.game.animating = false
		"solved":
			m._act("open 7")
			m._act("run")
		"fail":
			m._act("open 10")
			m._act("program IN | JGZ A | LDA -1 | LBL A | OUT")
			m._act("run")
		"manual":
			m._act("open 7")
			m.show_manual = true
		"win":
			for i in range(9, Puzzles.count()):
				m._act("open %d" % (i + 1))
				m._act("program " + str(Puzzles.all()[i].ref).replace("\n", " | "))
				m._act("run")
				m._act("ok")
	m.bridge.capture_after(40)
