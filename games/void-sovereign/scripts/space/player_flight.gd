class_name PlayerFlight
extends Node3D
## The player's ship in flight: X4-style mouse steering (virtual cursor = turn rate),
## throttle, boost, travel drive, twin lasers. Writes its transform back to the sim.

signal fired(origin: Vector3, dir: Vector3)

const PITCH_RATE := 1.5
const YAW_RATE := 1.3
const ROLL_RATE := 2.4
const TURN_SMOOTH := 6.0
const VEL_SMOOTH := 1.6
const THROTTLE_RATE := 0.7
const BOOST_MUL := 1.8
const TRAVEL_MUL := 4.5
const TRAVEL_CHARGE := 1.2
const BOOST_DRAIN := 0.35
const BOOST_REGEN := 0.15
const MOUSE_SENS := 0.0025
const STEER_DEADZONE := 0.06
const FIRE_INTERVAL := 0.12
const GUN_OFFSETS: Array[Vector3] = [Vector3(5, -0.5, -4), Vector3(-5, -0.5, -4)]

var data: ShipData
var touch: TouchControls
var input_enabled: bool = true
var autopilot: bool = false        # --autoplay bot
var steer: Vector2 = Vector2.ZERO  # virtual cursor, -1..1
var throttle: float = 0.25
var vel: Vector3 = Vector3.ZERO
var ang: Vector3 = Vector3.ZERO
var boost_meter: float = 1.0
var boosting: bool = false
var travel: bool = false
var travel_charge: float = 0.0
var fire_cd: float = 0.0
var aim_point: Variant = null      # Vector3 lead point for aim assist, set by SpaceView
var bot_goal: Vector3 = Vector3.ZERO


func setup(p_data: ShipData, p_touch: TouchControls) -> void:
	data = p_data
	touch = p_touch
	add_child(ProxyFactory.make_ship("interceptor", Defs.Faction.PLAYER))
	position = data.pos


func max_speed() -> float:
	return data.speed


func speed() -> float:
	return vel.length()


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		steer += (event as InputEventMouseMotion).relative * MOUSE_SENS
		steer = steer.limit_length(1.0)


func tick(delta: float) -> void:
	var roll := 0.0
	var firing := false
	if autopilot:
		var to := (bot_goal - position)
		var local := global_transform.basis.inverse() * to.normalized()
		steer = Vector2(clampf(local.x * 2.0, -1, 1), clampf(-local.y * 2.0, -1, 1))
		throttle = 0.8
		firing = true
	elif input_enabled:
		var kb := Vector2(Input.get_axis("yaw_l", "yaw_r"), Input.get_axis("pitch_up", "pitch_dn"))
		if kb != Vector2.ZERO:
			steer = kb
		elif touch.active and touch.layout == "flight" and (touch.stick != Vector2.ZERO or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED):
			steer = touch.stick
		roll = Input.get_axis("roll_l", "roll_r")
		if Input.is_action_pressed("thr_up") or touch.held("thr_up"):
			throttle = minf(throttle + THROTTLE_RATE * delta, 1.0)
		if Input.is_action_pressed("thr_dn") or touch.held("thr_dn"):
			throttle = maxf(throttle - THROTTLE_RATE * delta, 0.0)
		if Input.is_action_just_pressed("stop"):
			throttle = 0.0
			travel = false
		if Input.is_action_just_pressed("travel") or touch.pressed("travel"):
			_toggle_travel()
		boosting = (Input.is_action_pressed("boost") or touch.held("boost")) and boost_meter > 0.05 and not travel
		firing = Input.is_action_pressed("fire") or touch.held("fire") \
			or (Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
	else:
		steer = steer.lerp(Vector2.ZERO, 1.0 - exp(-4.0 * delta))

	# Rotation: steer offset is a turn *rate*, like X4's mouse steering.
	var s := steer
	if s.length() < STEER_DEADZONE:
		s = Vector2.ZERO
	var turn_mul := 0.45 if travel else 1.0
	var want := Vector3(-s.y * PITCH_RATE, -s.x * YAW_RATE, -roll * ROLL_RATE) * turn_mul
	ang = ang.lerp(want, 1.0 - exp(-TURN_SMOOTH * delta))
	var b := global_transform.basis
	b = b * Basis(Vector3.RIGHT, ang.x * delta) * Basis(Vector3.UP, ang.y * delta) * Basis(Vector3.FORWARD, -ang.z * delta)
	global_transform.basis = b.orthonormalized()

	# Translation: drifty, so turns feel like a ship and not a cursor.
	if travel:
		travel_charge += delta
	boost_meter = clampf(boost_meter + (-BOOST_DRAIN if boosting else BOOST_REGEN) * delta, 0.0, 1.0)
	var mul := BOOST_MUL if boosting else 1.0
	if travel and travel_charge >= TRAVEL_CHARGE:
		mul = TRAVEL_MUL
		throttle = 1.0
	var target_v := -global_transform.basis.z * throttle * max_speed() * mul
	if input_enabled and not travel:
		var strafe := Input.get_axis("strafe_l", "strafe_r")
		target_v += global_transform.basis.x * strafe * max_speed() * 0.5
	vel = vel.lerp(target_v, 1.0 - exp(-VEL_SMOOTH * delta))
	position += vel * delta

	fire_cd -= delta
	if firing and fire_cd <= 0.0 and not travel_engaged():
		fire_cd = FIRE_INTERVAL
		for off: Vector3 in GUN_OFFSETS:
			var origin := global_transform * off
			var dir := -global_transform.basis.z
			if aim_point != null:
				var to_aim: Vector3 = (aim_point as Vector3) - origin
				if to_aim.normalized().dot(dir) > cos(deg_to_rad(9.0)):
					dir = to_aim.normalized()
			fired.emit(origin, dir)
	data.pos = position
	data.vel = vel


func travel_engaged() -> bool:
	return travel


func _toggle_travel() -> void:
	travel = not travel
	travel_charge = 0.0
	if not travel:
		throttle = minf(throttle, 0.6)


func drop_travel() -> void:
	if travel:
		travel = false
		throttle = 0.6
