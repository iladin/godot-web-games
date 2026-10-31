class_name AimInput
extends RefCounted
## Shared aim state: a slingshot drag (touch/mouse) and the arrow keys both edit angle/power.

const DRAG_FULL := 260.0       # drag length (px) for full power
const DRAG_DEADZONE := 30.0    # shorter drags cancel
const KEY_AIM_SPEED := 2.0     # rad/s
const KEY_AIM_FINE := 0.4      # rad/s with Shift held
const KEY_POWER_SPEED := 0.8   # per second

var angle := 0.0
var power := 0.6
var dragging := false
var start := Vector2.ZERO
var cur := Vector2.ZERO


func begin(p: Vector2) -> void:
	dragging = true
	start = p
	cur = p


func move(p: Vector2) -> void:
	if dragging:
		cur = p
		_apply()


## Ends the drag; returns true when it was long enough to count as a shot.
func release(p: Vector2) -> bool:
	if not dragging:
		return false
	dragging = false
	cur = p
	if cancelling_len() < DRAG_DEADZONE:
		return false
	_apply()
	return true


func cancelling_len() -> float:
	return (start - cur).length()


## True while a drag is in progress but still inside the deadzone (no aim shown).
func in_deadzone() -> bool:
	return dragging and cancelling_len() < DRAG_DEADZONE


func keys(delta: float) -> void:
	var spd := KEY_AIM_FINE if Input.is_key_pressed(KEY_SHIFT) else KEY_AIM_SPEED
	angle = wrapf(angle + Input.get_axis("ui_left", "ui_right") * spd * delta, -PI, PI)
	power = clampf(power + Input.get_axis("ui_down", "ui_up") * KEY_POWER_SPEED * delta, 0.0, 1.0)


func _apply() -> void:
	var v := start - cur
	if v.length() >= DRAG_DEADZONE:
		angle = v.angle()
		power = clampf(v.length() / DRAG_FULL, 0.0, 1.0)
