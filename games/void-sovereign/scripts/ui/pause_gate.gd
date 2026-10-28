class_name PauseGate
extends Node
## Input while VoidMain is paused (VS-014). Sits first among main's children, so its _input runs
## after TouchControls' (which keeps SND taps, and swallows other button taps) and before any GUI
## control or _unhandled_input handler (map/dock buttons, space_view/fps_player mouse capture).
## While paused: emulated mouse events (from touch) never resume and never reach the GUI; a real
## click, a tap off the touch buttons, ui_accept or a fresh key press (not N) resumes and is eaten.

var g: VoidMain
var _eat_release: bool = false   # swallow the emulated release of a press eaten while paused


func _init(p_g: VoidMain) -> void:
	g = p_g
	name = "PauseGate"
	process_mode = Node.PROCESS_MODE_ALWAYS


func _input(event: InputEvent) -> void:
	if not g.paused:
		if _eat_release and _is_emulated_button(event) and not (event as InputEventMouseButton).pressed:
			_eat_release = false
			get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		get_viewport().set_input_as_handled()   # nothing under the pause screen may act
	if _is_emulated_button(event):
		_eat_release = (event as InputEventMouseButton).pressed
	if Controls.resumes_from_pause(event):
		resume()
		get_viewport().set_input_as_handled()


func pause() -> void:
	g.paused = true
	g.overlay.screen = "pause"
	g.overlay.on_surface = g.mode == "surface"
	g.touch.paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func resume() -> void:
	g.paused = false
	g.overlay.screen = "none"
	g.touch.paused = false


static func _is_emulated_button(event: InputEvent) -> bool:
	return event is InputEventMouseButton and event.device == InputEvent.DEVICE_ID_EMULATION
