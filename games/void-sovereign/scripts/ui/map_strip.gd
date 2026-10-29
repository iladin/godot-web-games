class_name MapStrip
extends VBoxContainer
## VS-067: pinned command strip at the top of the map side panel (outside the scrolling list):
## raid forecast line, Call Reserve, Repair HQ. Always on screen, buttons >= 44 px.

const BTN_H := 46.0   # >= 44 px touch target
const HIVE := Color("ff3b8d")
const AMBER := Color("ffb347")

var u: Universe
var forecast: Label
var reserve_btn: Button
var repair_btn: Button


func setup(p_u: Universe) -> void:
	u = p_u
	add_theme_constant_override("separation", 4)
	forecast = Label.new()
	forecast.autowrap_mode = TextServer.AUTOWRAP_OFF
	forecast.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	forecast.add_theme_font_size_override("font_size", 13)
	add_child(forecast)
	reserve_btn = DockPanel.make_reserve_button(u, BTN_H)
	reserve_btn.add_theme_font_size_override("font_size", 14)
	add_child(reserve_btn)
	repair_btn = Button.new()
	repair_btn.custom_minimum_size = Vector2(0, BTN_H)
	repair_btn.clip_text = true
	repair_btn.add_theme_font_size_override("font_size", 14)
	repair_btn.pressed.connect(func() -> void: u.repair_station(u.hq))
	add_child(repair_btn)


## Forecast line text: the soonest raid's forecast/label, else a calm status.
static func forecast_line(p_u: Universe) -> String:
	var act := p_u.director.tracker.active()
	if act.is_empty():
		return "No raid inbound"
	var tr := p_u.director.tracker
	return tr.label_for(act[0]) + ("" if act.size() == 1 else " +%d" % (act.size() - 1))


## "Call Reserve: 6 ships, 3 min" then the price (ready) or the refusal reason (disabled, never clipped: own line).
static func reserve_text(p_u: Universe) -> String:
	var why := p_u.reserve_refusal()
	return "Call Reserve: %d ships, %d min\n%s" % [Defs.RESERVE_COUNT, int(Defs.RESERVE_LINGER / 60.0), "%s cr" % Hud._fmt(Defs.RESERVE_COST) if why == "" else why]


## Repair HQ label and the reason it is unavailable ("" when pressable). Hidden at full hull (see refresh).
static func repair_text(p_u: Universe) -> String:
	var hq := p_u.hq
	var cost := p_u.station_repair_cost(hq)
	return "Repair HQ: hull %d%%\n%s" % [int(hq.hull_frac() * 100.0), "%s cr" % Hud._fmt(cost) if p_u.credits >= 1.0 else "No credits to repair"]


func refresh(p_u: Universe) -> void:
	u = p_u   # the map's universe is swapped on load/restart
	var f := forecast_line(u)
	forecast.text = f
	forecast.tooltip_text = f
	forecast.add_theme_color_override("font_color", HIVE if not u.director.tracker.active().is_empty() else Color(1, 1, 1, 0.55))
	reserve_btn.text = reserve_text(u)
	reserve_btn.disabled = u.reserve_refusal() != ""
	var damaged := u.hq != null and u.hq.alive and u.station_repair_cost(u.hq) > 1.0
	repair_btn.visible = damaged
	if damaged:
		repair_btn.text = repair_text(u)
		repair_btn.disabled = u.credits < 1.0


## True when every strip control lies inside the given rect (the visible side panel).
func rects() -> String:
	return "%s %s %s" % [forecast.get_global_rect(), reserve_btn.get_global_rect(), repair_btn.get_global_rect() if repair_btn.visible else "-"]


func on_screen(r: Rect2) -> bool:
	for c: Control in [forecast, reserve_btn, repair_btn]:
		if c.visible and not r.encloses(c.get_global_rect()):
			return false
	return true
