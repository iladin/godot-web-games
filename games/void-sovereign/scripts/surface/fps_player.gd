class_name FpsPlayer
extends CharacterBody3D
## On-foot first-person controller with a hitscan rifle.

signal fired(origin: Vector3, dir: Vector3)
signal died()

const MAX_HP := 100.0
const MAX_SHIELD := 60.0
const SHIELD_DELAY := 3.0
const SHIELD_REGEN := 20.0
const WALK := 9.0
const SPRINT := 14.5
const ACCEL := 60.0
const AIR_ACCEL := 14.0
const JUMP := 7.5
const GRAVITY := 18.0
const MAG := 30
const FIRE_INTERVAL := 0.095
const RELOAD_TIME := 1.4
const MOUSE_SENS := 0.0024
const TOUCH_LOOK_SENS := 0.006
const SPREAD := 0.012
const COYOTE := 0.12

var touch: TouchControls
var head: Node3D
var cam: Camera3D
var gun: Node3D
var flash: MeshInstance3D
var hp: float = MAX_HP
var shield: float = MAX_SHIELD
var since_hit: float = 99.0
var ammo: int = MAG
var reload_t: float = 0.0
var fire_cd: float = 0.0
var kick: float = 0.0
var bob_t: float = 0.0
var air_t: float = 0.0
var dead: bool = false
var input_enabled: bool = true
var autopilot: bool = false
var bot_target: Variant = null
var bot_move: Vector3 = Vector3.ZERO


func setup(p_touch: TouchControls) -> void:
	touch = p_touch
	var shape := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.8
	shape.shape = cap
	shape.position.y = 0.9
	add_child(shape)
	head = Node3D.new()
	head.position.y = 1.6
	add_child(head)
	cam = Camera3D.new()
	cam.fov = 78.0
	cam.near = 0.05
	cam.far = 1500.0
	head.add_child(cam)
	gun = Node3D.new()
	gun.position = Vector3(0.28, -0.26, -0.5)
	gun.scale = Vector3.ONE * 0.8
	cam.add_child(gun)
	var dark := ProxyFactory.mat(Color("2a2f3a"))
	ProxyFactory.part(gun, ProxyFactory.box(0.09, 0.12, 0.62), dark, Vector3.ZERO)
	ProxyFactory.part(gun, ProxyFactory.box(0.07, 0.16, 0.12), dark, Vector3(0, -0.12, 0.1))
	ProxyFactory.part(gun, ProxyFactory.box(0.02, 0.015, 0.36), ProxyFactory.mat(Color("ffb347"), 1.2, true), Vector3(0.05, 0.05, -0.05))
	ProxyFactory.part(gun, ProxyFactory.cyl(0.025, 0.025, 0.25, 8), dark, Vector3(0, 0.02, -0.42), Vector3(90, 0, 0))
	flash = ProxyFactory.part(gun, ProxyFactory.sphere(0.09, 8, 4), ProxyFactory.mat(Color("ffe0a0"), 6.0, true), Vector3(0, 0.02, -0.58))
	flash.visible = false
	floor_max_angle = deg_to_rad(50.0)


func _unhandled_input(event: InputEvent) -> void:
	if dead or not input_enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_look((event as InputEventMouseMotion).relative * MOUSE_SENS)
	elif event is InputEventMouseButton and (event as InputEventMouseButton).pressed and event.device != InputEvent.DEVICE_ID_EMULATION:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()


func _look(d: Vector2) -> void:
	rotate_y(-d.x)
	head.rotation.x = clampf(head.rotation.x - d.y, -1.45, 1.45)


func tick(delta: float) -> void:
	if dead:
		return
	since_hit += delta
	if since_hit > SHIELD_DELAY:
		shield = minf(MAX_SHIELD, shield + SHIELD_REGEN * delta)
	var move := Vector2.ZERO
	var want_jump := false
	var sprint := false
	var firing := false
	var reload := false
	if autopilot:
		if bot_target != null:
			var to: Vector3 = (bot_target as Vector3) - head.global_position
			var yaw := atan2(-to.x, -to.z)
			rotation.y = lerp_angle(rotation.y, yaw, 1.0 - exp(-8.0 * delta))
			var flat := Vector2(to.x, to.z).length()
			head.rotation.x = lerpf(head.rotation.x, atan2(to.y, flat), 1.0 - exp(-8.0 * delta))
			firing = true
		var local := global_transform.basis.inverse() * bot_move
		move = Vector2(local.x, -local.z).limit_length(1.0)
		want_jump = is_on_wall()
	elif input_enabled:
		move = Vector2(Input.get_axis("move_l", "move_r"), Input.get_axis("move_b", "move_f"))
		if touch.active and touch.layout == "surface":
			if touch.stick != Vector2.ZERO:
				move = Vector2(touch.stick.x, -touch.stick.y)
			_look(touch.take_look() * TOUCH_LOOK_SENS)
		want_jump = Input.is_action_just_pressed("jump") or touch.pressed("jump")
		sprint = Input.is_action_pressed("sprint") or touch.held("sprint")
		firing = touch.held("fire") or (Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT))
		reload = Input.is_action_just_pressed("reload") or touch.pressed("reload")
	# Movement
	var basis_flat := global_transform.basis
	var dir := (basis_flat.x * move.x - basis_flat.z * move.y)
	dir.y = 0.0
	dir = dir.limit_length(1.0)
	var spd := SPRINT if sprint and move.y > 0.2 else WALK
	var on_floor := is_on_floor()
	air_t = 0.0 if on_floor else air_t + delta
	var hv := Vector3(velocity.x, 0, velocity.z)
	hv = hv.move_toward(dir * spd, (ACCEL if on_floor else AIR_ACCEL) * delta)
	velocity.x = hv.x
	velocity.z = hv.z
	velocity.y -= GRAVITY * delta
	if want_jump and air_t < COYOTE:
		velocity.y = JUMP
		air_t = COYOTE
	move_and_slide()
	# Weapon
	fire_cd -= delta
	if reload_t > 0.0:
		reload_t -= delta
		if reload_t <= 0.0:
			ammo = MAG
	elif reload and ammo < MAG:
		reload_t = RELOAD_TIME
	elif firing and fire_cd <= 0.0:
		if ammo <= 0:
			reload_t = RELOAD_TIME
		else:
			ammo -= 1
			fire_cd = FIRE_INTERVAL
			kick = minf(kick + 0.35, 1.0)
			var spread := Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * SPREAD * (1.0 + kick)
			var d := (-cam.global_transform.basis.z + cam.global_transform.basis * spread).normalized()
			fired.emit(cam.global_position, d)
			flash.visible = true
			flash.rotation.z = randf() * TAU
			head.rotation.x = minf(head.rotation.x + 0.006, 1.45)
	if fire_cd < FIRE_INTERVAL * 0.5:
		flash.visible = false
	kick = maxf(kick - delta * 4.0, 0.0)
	# Gun bob + recoil
	var moving := hv.length() > 1.0 and on_floor
	bob_t += delta * (hv.length() * 0.9 if moving else 0.0)
	var reload_dip := 0.0 if reload_t <= 0.0 else sin(reload_t / RELOAD_TIME * PI) * 0.25
	gun.position = Vector3(0.28 + sin(bob_t) * 0.015, -0.26 - absf(cos(bob_t)) * 0.015 - reload_dip, -0.5 + kick * 0.06)


func take_damage(amount: float) -> void:
	if dead:
		return
	since_hit = 0.0
	var a := minf(shield, amount)
	shield -= a
	hp -= amount - a
	if hp <= 0.0:
		hp = 0.0
		dead = true
		died.emit()
