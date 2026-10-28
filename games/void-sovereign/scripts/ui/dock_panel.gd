class_name DockPanel
extends PanelContainer
## Station services while docked: trade wares, repair, buy ships.

signal undock_pressed()

const REPAIR_COST := 3.0   # credits per hull point
const TRADE_STEP := 10

var u: Universe
var st: StationData
var _rows: Dictionary = {}   # ware -> {stock: Label, price: Label, mine: Label}
var _info: Label
var _ledger: Label
var _repair: Button
var _st_repair: Button
var _hull_lbl: Label      # VS-053: status rows replace the repair buttons at 100% hull
var _st_hull_lbl: Label
var _ship_btns: Dictionary = {}


## VS-032: HQ footer; touch wording uses MAP/ACT and points at income.
static func hq_hint(touch: bool) -> String:
	return "Build stations and command your fleet from the Command Map (%s). Earn credits: undock, then %s at the Union Trade Hub to sell wares." % [
		"tap MAP" if touch else "M", "tap ACT" if touch else "press F"]


func open(p_u: Universe, p_st: StationData, touch_active: bool = false) -> void:
	u = p_u
	st = p_st
	for c in get_children():
		c.queue_free()
	_rows.clear()
	_ship_btns.clear()
	custom_minimum_size = Vector2(760, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var title := Label.new()
	title.text = "DOCKED — %s  ·  %s  ·  %s" % [st.display_name, Defs.FACTION_NAMES[st.faction], u.sectors[st.sector].name]
	title.add_theme_color_override("font_color", Defs.faction_color(st.faction))
	title.add_theme_font_size_override("font_size", 26)
	box.add_child(title)
	_info = Label.new()
	box.add_child(_info)
	_ledger = Label.new()
	_ledger.modulate = Color(1, 1, 1, 0.8)
	_ledger.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_ledger)

	var trades := Defs.WARES.any(func(w: String) -> bool: return st.buys(w) or st.sells(w))
	var grid := GridContainer.new()
	grid.visible = trades
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 18)
	box.add_child(grid)
	for h: String in ["Ware", "Station", "Price", "Your hold", "", ""]:
		var l := Label.new()
		l.text = h
		l.modulate = Color(1, 1, 1, 0.6)
		grid.add_child(l)
	for w: String in Defs.WARES:
		if not (st.buys(w) or st.sells(w)):
			continue
		var name_l := Label.new()
		name_l.text = Defs.WARE_NAMES[w]
		grid.add_child(name_l)
		var stock_l := Label.new()
		grid.add_child(stock_l)
		var price_l := Label.new()
		grid.add_child(price_l)
		var mine_l := Label.new()
		grid.add_child(mine_l)
		var buy := Button.new()
		buy.text = "Buy %d" % TRADE_STEP
		buy.disabled = not st.sells(w)
		buy.pressed.connect(func() -> void: u.transact(u.player_ship, st, w, TRADE_STEP, true))
		grid.add_child(buy)
		var sell := Button.new()
		sell.text = "Sell all"
		sell.disabled = not st.buys(w)
		sell.pressed.connect(func() -> void: u.transact(u.player_ship, st, w, int(u.player_ship.cargo.get(w, 0)), false))
		grid.add_child(sell)
		_rows[w] = {"stock": stock_l, "price": price_l, "mine": mine_l}
	if not trades:
		var none := Label.new()
		none.text = "This station does not trade wares."
		none.modulate = Color(1, 1, 1, 0.6)
		box.add_child(none)

	_repair = Button.new()
	_repair.pressed.connect(_do_repair)
	box.add_child(_repair)

	_hull_lbl = _status_label()
	box.add_child(_hull_lbl)

	_st_repair = Button.new()
	_st_repair.pressed.connect(func() -> void: u.repair_station(st))
	_st_repair.visible = st.faction == Defs.Faction.PLAYER
	_st_hull_lbl = _status_label()
	box.add_child(_st_hull_lbl)
	box.add_child(_st_repair)

	if st.kind == "shipyard" or st.kind == "hq":
		var yl := Label.new()
		yl.text = "SHIPYARD — new ships launch here and join your fleet"
		yl.add_theme_color_override("font_color", Defs.faction_color(Defs.Faction.PLAYER))
		box.add_child(yl)
		var row := HBoxContainer.new()
		box.add_child(row)
		for cls: String in Defs.PLAYER_BUYABLE:
			var b := Button.new()
			b.pressed.connect(func() -> void: u.buy_ship(cls, st))
			row.add_child(b)
			_ship_btns[cls] = b
	if st.kind == "hq":
		var hint := Label.new()
		hint.text = hq_hint(touch_active)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.modulate = Color(1, 1, 1, 0.6)
		box.add_child(hint)
	var undock := Button.new()
	undock.text = "Undock"
	undock.custom_minimum_size = Vector2(0, 52)
	undock.pressed.connect(func() -> void: undock_pressed.emit())
	box.add_child(undock)
	visible = true
	_refresh()


func _status_label() -> Label:
	var l := Label.new()
	l.modulate = Color(0.55, 0.9, 0.7, 0.9)
	return l


## VS-053: full-hull rows are plain status text (no button chrome); repair buttons show only when needed.
static func hull_status(label: String, pct: int) -> String:
	return "%s hull %d%% (full)" % [label, pct]


func _process(_delta: float) -> void:
	if visible and st:
		var parent_size := (get_parent() as Control).size
		size = get_combined_minimum_size()
		position = (parent_size - size) * 0.5
		_refresh()
		if not st.alive:
			undock_pressed.emit()


func _refresh() -> void:
	var ps := u.player_ship
	_info.text = "Credits %s   ·   Hold %d / %d" % [Hud._fmt(u.credits), ps.cargo_used(), ps.cargo_cap]
	_ledger.text = Hud.ledger_text(u, 5, true)
	for w: String in _rows:
		var r: Dictionary = _rows[w]
		(r["stock"] as Label).text = "%d / %d" % [int(st.stock[w]), st.capacity]
		(r["price"] as Label).text = "%d cr" % int(st.price(w))
		(r["mine"] as Label).text = str(int(ps.cargo.get(w, 0)))
	var missing := ps.hull_max - ps.hull
	_repair.text = "Hull %d%% — Repair (%d cr)" % [int(ps.hull_frac() * 100.0), int(missing * REPAIR_COST)]
	_repair.visible = missing > 1.0
	_hull_lbl.visible = missing <= 1.0
	_hull_lbl.text = hull_status("Ship", 100)
	var sc := u.station_repair_cost(st)
	var pen := st.wound_penalty()
	var pen_txt := "  [DAMAGED: -%d%% income & shield regen]" % int(round(pen * 100.0)) if pen > 0.0 else ""
	var own := st.faction == Defs.Faction.PLAYER
	_st_repair.text = "Station hull %d%%%s — Repair (%s cr)" % [int(st.hull_frac() * 100.0), pen_txt, Hud._fmt(sc)]
	_st_repair.visible = own and sc > 1.0
	_st_repair.disabled = u.credits < 1.0
	_st_hull_lbl.visible = own and sc <= 1.0
	_st_hull_lbl.text = hull_status("Station", 100)
	for cls: String in _ship_btns:
		var b := _ship_btns[cls] as Button
		var cost := int(Defs.SHIP[cls]["cost"])
		b.text = "%s\n%s cr" % [Defs.SHIP[cls]["name"], Hud._fmt(cost)]
		b.disabled = u.credits < cost


func _do_repair() -> void:
	var ps := u.player_ship
	var missing := ps.hull_max - ps.hull
	var afford := minf(missing, u.credits / REPAIR_COST)
	u.add_credits(-afford * REPAIR_COST, "repair")
	ps.hull += afford
	ps.shield = ps.shield_max
