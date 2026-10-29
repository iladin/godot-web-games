class_name MapPages
extends RefCounted
## VS-076: builds the three map side-panel tab pages (Buy / Build / Orders) and refreshes their button labels,
## so MapView only wires callbacks. Pages are plain VBoxContainers; the caller parents them and hands them to MapTabs.

const ORDER_BTN := Vector2(68, 44)   # VS-076: >= 44 px touch target
const PAGE_BTN := Vector2(140, 40)
const AMBER := Color("ffb347")
const SHORT_NAMES: Dictionary = {"solar": "Solar Array", "refinery": "Refinery", "factory": "Munitions", "defense": "Defense"}
const ORDERS: Array = [["patrol", "Patrol"], ["escort", "Escort"], ["trade", "Trade"], ["mine", "Mine"], ["idle", "Stop"], ["all", "Warships"]]
const ORDER_TIPS: Dictionary = {"patrol": "Patrol this sector", "escort": "Escort your ship", "trade": "Auto-trade (traders)", "mine": "Auto-mine (miners)", "idle": "Stop: cancel orders", "all": "Select every warship here"}

var buy_page: VBoxContainer
var build_page: VBoxContainer
var orders_page: VBoxContainer
var orders_grid: GridContainer
var order_toggle: Button
var info: Label
var sel_label: Label
var order_btns: Dictionary = {}
var buy_btns: Dictionary = {}
var build_btns: Dictionary = {}


static func _page() -> VBoxContainer:
	var p := VBoxContainer.new()
	p.add_theme_constant_override("separation", 4)
	return p


static func _header(s: String) -> Label:
	var l := Label.new()
	l.text = s
	l.add_theme_font_size_override("font_size", 16)
	l.modulate = Color(1, 1, 1, 0.6)
	return l


static func _btn(min_size: Vector2, fs: int) -> Button:
	var b := Button.new()
	b.custom_minimum_size = min_size
	b.clip_text = true
	b.add_theme_font_size_override("font_size", fs)
	return b


## Callbacks: on_order(key: String), on_buy(cls: String), on_build(kind: String), on_tap(on: bool).
func build(on_order: Callable, on_buy: Callable, on_build: Callable, on_tap: Callable) -> void:
	buy_page = _page()
	build_page = _page()
	orders_page = _page()
	orders_grid = GridContainer.new()
	orders_grid.columns = 4   # VS-067: 7 controls (6 orders + tap toggle) in 2 rows
	orders_page.add_child(orders_grid)
	for o: Array in ORDERS:
		var key: String = o[0]
		var b := _btn(ORDER_BTN, 13)
		b.text = o[1]
		b.tooltip_text = ORDER_TIPS[key]
		b.pressed.connect(func() -> void: on_order.call(key))
		orders_grid.add_child(b)
		order_btns[key] = b
	order_toggle = _btn(ORDER_BTN, 13)
	order_toggle.toggle_mode = true
	order_toggle.text = "Tap: OFF"
	order_toggle.tooltip_text = "Tap-to-order (touch): when ON, the next tap on the map issues an order to the selection."
	order_toggle.toggled.connect(func(on: bool) -> void:
		order_toggle.text = "Tap: %s" % ("ON" if on else "OFF")
		on_tap.call(on))
	orders_grid.add_child(order_toggle)
	buy_page.add_child(_header("BUY SHIPS (launch at HQ)"))
	var buys := GridContainer.new()
	buys.columns = 2
	buy_page.add_child(buys)
	for cls: String in Defs.PLAYER_BUYABLE:
		var b2 := _btn(PAGE_BTN, 14)
		b2.pressed.connect(func() -> void: on_buy.call(cls))
		buys.add_child(b2)
		buy_btns[cls] = b2
	build_page.add_child(_header("BUILD STATION (click map to place)"))
	var builds := GridContainer.new()
	builds.columns = 2
	build_page.add_child(builds)
	for kind: String in Defs.PLAYER_BUILDABLE:
		var b3 := _btn(PAGE_BTN, 14)
		b3.pressed.connect(func() -> void: on_build.call(kind))
		builds.add_child(b3)
		build_btns[kind] = b3
	info = Label.new()
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	orders_page.add_child(info)
	sel_label = Label.new()
	sel_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sel_label.add_theme_color_override("font_color", AMBER)
	orders_page.add_child(sel_label)


## Affordability + labels of the Buy and Build buttons.
func refresh_buttons(u: Universe, build_kind: String, view_sector: int) -> void:
	for cls: String in buy_btns:
		var cost := int(Defs.SHIP[cls]["cost"])
		(buy_btns[cls] as Button).text = "%s\n%s" % [Defs.SHIP[cls]["name"], Hud._fmt(cost)]
		(buy_btns[cls] as Button).disabled = u.credits < cost or not u.hq.alive
	for kind: String in build_btns:
		var cost2 := int(Defs.STATION[kind]["cost"])
		var b := build_btns[kind] as Button
		b.text = "%s%s\n%s" % ["> " if build_kind == kind else "", SHORT_NAMES[kind], Hud._fmt(cost2)]
		b.disabled = u.credits < cost2 or u.sector_has_nest(view_sector)


## Orders tab text: sector/fleet/ledger block and the selection list.
func refresh_text(u: Universe, view_sector: int, selected: Array[int]) -> void:
	var s := u.sectors[view_sector]
	var counts: Dictionary = {}
	for e: SimEntity in u.entities.values():
		if e is ShipData and e.faction == Defs.Faction.PLAYER and not (e as ShipData).is_player:
			var c: String = (e as ShipData).display_name
			counts[c] = int(counts.get(c, 0)) + 1
	var fleet := ", ".join(counts.keys().map(func(k: String) -> String: return "%s ×%d" % [k, counts[k]]))
	var pstate := {"hive": "Hive Core (threat %d)" % s.level, "colony": "Your colony", "union": "Union world"}
	info.text = "%s\nPlanet %s: %s\nFleet: %s\n%s" % [s.name, s.planet_name, pstate[s.planet_state], fleet if fleet != "" else "none", Hud.ledger_text(u, 4)]
	if selected.is_empty():
		sel_label.text = "Click or drag-box your ships to select. Right-click to order."
		return
	var lines: Array[String] = []
	for id: int in selected.slice(0, 6):
		var sh := u.get_ent(id) as ShipData
		lines.append("%s — %s%s" % [sh.display_name, sh.order, "" if sh.sector == view_sector else " (%s)" % u.sectors[sh.sector].name])
	sel_label.text = "\n".join(lines)
