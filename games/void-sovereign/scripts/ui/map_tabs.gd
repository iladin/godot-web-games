class_name MapTabs
extends HBoxContainer
## VS-068: tab bar for the map side panel (Buy / Build / Orders). Owns the tab buttons (>= 44 px, touch and
## keyboard: click/tap, focus + ui_accept, or number keys 1..N) and shows only the active tab's page.

signal tab_changed(idx: int)

const TAB_H := 44.0   # >= 44 px touch target
const AMBER := Color("ffb347")

var current: int = 0
var _btns: Array[Button] = []
var _pages: Array[Control] = []


## Adds a tab and its page (the page is just shown/hidden; the caller parents it).
func add_tab(title: String, page: Control) -> void:
	var idx := _btns.size()
	var b := Button.new()
	b.text = "%d %s" % [idx + 1, title]
	b.toggle_mode = true
	b.custom_minimum_size = Vector2(0, TAB_H)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 14)
	b.tooltip_text = "%s (key %d)" % [title, idx + 1]
	b.pressed.connect(func() -> void: select(idx))
	add_child(b)
	_btns.append(b)
	_pages.append(page)
	select(current)


func count() -> int:
	return _pages.size()


func select(idx: int) -> void:
	if _pages.is_empty():
		return
	current = clampi(idx, 0, _pages.size() - 1)
	for i: int in _pages.size():
		_pages[i].visible = i == current
		_btns[i].set_pressed_no_signal(i == current)
		_btns[i].add_theme_color_override("font_color", AMBER if i == current else Color(1, 1, 1, 0.75))
	tab_changed.emit(current)


## Keyboard: 1..N picks a tab. Returns true when the event was used.
func handle_key(event: InputEvent) -> bool:
	if event is InputEventKey and (event as InputEventKey).pressed and not (event as InputEventKey).echo:
		var k := (event as InputEventKey).keycode
		if k >= KEY_1 and k < KEY_1 + _pages.size():
			select(k - KEY_1)
			return true
	return false


func page_visible(idx: int) -> bool:
	return _pages[idx].visible


func min_tab_height() -> float:
	var m := 9999.0
	for b: Button in _btns:
		m = minf(m, b.size.y)
	return m
