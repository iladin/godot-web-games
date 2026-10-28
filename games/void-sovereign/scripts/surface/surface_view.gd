class_name SurfaceView
extends Node3D
## Planet surface: procedural terrain, a Hive base (pylons -> Core), waves of defenders.
## Destroying the Core claims the planet and drops the orbiting Nest's shield.

signal takeoff_requested()
signal player_died()
signal core_killed()
signal hit_something()
signal player_damaged(amount: float)
signal sfx(sound: String)
signal kill_confirmed(big: bool)

const GRID := 72
const SPACING := 7.0
const HEIGHT := 26.0
const RIFLE_DAMAGE := 20.0
const RIFLE_RANGE := 400.0
const MAX_FOES := 16
const FOE_SHOT_SPEED := 45.0
const BOARD_DIST := 9.0
const SPIRE_HEIGHT := 260.0         ## VS-031: Core spire landmark height (m); unshaded, ignores fog
const BEAM_HEIGHT := 200.0          ## VS-031: pylon beam height (m)
const BOT_MOB_PRIORITY := 40.0   ## autoplay bot: flankers count this much closer when picking a target
const BOT_STRAFE_TIME := 1.6
const SPIRE_SHIELDED := Color("ff3b8d")
const SPIRE_EXPOSED := Color("fff2a8")

class Foe extends RefCounted:
	var flank: bool = false
	var kind: String = "crawler"   # crawler | drone | turret | pylon | core
	var node: Node3D
	var hp: float = 50.0
	var hp_max: float = 50.0
	var radius: float = 1.0
	var vel: Vector3 = Vector3.ZERO
	var cd: float = 1.0
	var alive: bool = true
	var phase: float = 0.0

var u: Universe
var touch: TouchControls
var sector_idx: int = 0
var level: int = 1
var noise := FastNoiseLite.new()
var fps: FpsPlayer
var cam: Camera3D
var foes: Array[Foe] = []
var shots: Array[Dictionary] = []
var fx: Array[Dictionary] = []
var core: Foe
var ship_pos: Vector3 = Vector3.ZERO
var core_pos: Vector3 = Vector3.ZERO
var wave_t: float = 12.0
var core_dead: bool = false
var prompt: String = ""
var autoplay: bool = false
var half: float = GRID * SPACING * 0.5
var spire_mat: StandardMaterial3D
var spire_t: float = 0.0
var flanked: bool = false   ## VS-037: the flank squad spawns once, at the first pylon kill
var flank_spawned: int = 0
var bot_t: float = 0.0


func setup(p_u: Universe, p_touch: TouchControls, idx: int) -> void:
	u = p_u
	touch = p_touch
	sector_idx = idx
	var s := u.sectors[idx]
	level = maxi(s.level, 1)
	noise.seed = s.rng_seed
	noise.frequency = 0.006
	noise.fractal_octaves = 4
	ship_pos = Vector3(-half * 0.7, 0, half * 0.7)
	core_pos = Vector3(half * 0.55, 0, -half * 0.55)
	ship_pos.y = height(ship_pos.x, ship_pos.z)
	core_pos.y = height(core_pos.x, core_pos.z)
	_build_env()
	_build_terrain()
	_build_props()
	_build_base()
	fps = FpsPlayer.new()
	fps.setup(touch)
	fps.autopilot = autoplay
	add_child(fps)
	fps.position = ship_pos + Vector3(8, 2, -6)
	fps.look_at(Vector3(core_pos.x, fps.position.y, core_pos.z), Vector3.UP)
	fps.rotation.x = 0.0
	fps.rotation.z = 0.0
	cam = fps.cam
	cam.make_current()
	fps.fired.connect(_on_fired)
	fps.died.connect(func() -> void: player_died.emit())
	for i in 3 + level * 2:
		_spawn_foe("crawler" if i % 2 == 0 else "drone", core_pos + Vector3(randf_range(-90, 90), 0, randf_range(-90, 90)))


## Terrain height: noise, flattened at the landing site and the Hive base.
func height(x: float, z: float) -> float:
	var h := noise.get_noise_2d(x, z) * HEIGHT + noise.get_noise_2d(x * 3.1, z * 3.1) * 3.0
	var edge := maxf(absf(x), absf(z)) / half
	h += smoothstep(0.75, 1.0, edge) * 40.0   # mountains at the rim keep you in
	for site: Vector2 in [Vector2(-half * 0.7, half * 0.7), Vector2(half * 0.55, -half * 0.55)]:
		var d := Vector2(x, z).distance_to(site)
		var flat := smoothstep(70.0, 25.0, d)
		var site_h := noise.get_noise_2d(site.x, site.y) * HEIGHT
		h = lerpf(h, site_h, flat)
	return h


func _build_env() -> void:
	var we := WorldEnvironment.new()
	var e := Environment.new()
	var sky := Sky.new()
	var psm := ProceduralSkyMaterial.new()
	var hues: Array[Color] = [Color("5a2a4a"), Color("3a2a5a"), Color("6a3a2a")]
	var top := hues[sector_idx % hues.size()]
	psm.sky_top_color = top.darkened(0.5)
	psm.sky_horizon_color = top.lightened(0.35)
	psm.ground_horizon_color = top.lightened(0.2)
	psm.ground_bottom_color = top.darkened(0.6)
	sky.sky_material = psm
	e.background_mode = Environment.BG_SKY
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	e.ambient_light_energy = 0.8
	e.fog_enabled = true
	e.fog_light_color = top.lightened(0.3)
	e.fog_density = 0.0035
	e.glow_enabled = true
	e.glow_intensity = 0.6
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = e
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.light_color = Color("ffd8b0")
	sun.light_energy = 1.1
	add_child(sun)


func _build_terrain() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rock := Color("3a2a30")
	var dust := Color("6a4a3a")
	var vein := Color("8a2a5a")
	for zi in GRID:
		for xi in GRID:
			var quad: Array[Vector3] = []
			for c: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
				var x := -half + float(xi + c.x) * SPACING
				var z := -half + float(zi + c.y) * SPACING
				quad.append(Vector3(x, height(x, z), z))
			for tri: Array in [[0, 1, 2], [1, 3, 2]]:
				var a: Vector3 = quad[tri[0]]
				var b: Vector3 = quad[tri[1]]
				var c2: Vector3 = quad[tri[2]]
				var n := (b - a).cross(c2 - a).normalized()
				if n.y < 0.0:
					n = -n
				var slope := 1.0 - n.y
				var col := dust.lerp(rock, clampf(slope * 4.0, 0.0, 1.0))
				var m := (a + b + c2) / 3.0
				if absf(noise.get_noise_2d(m.x * 4.0, m.z * 4.0)) < 0.03:
					col = vein
				for v: Vector3 in [a, b, c2]:
					st.set_color(col)
					st.set_normal(n)
					st.add_vertex(v)
	var mesh := st.commit()
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var m2 := StandardMaterial3D.new()
	m2.vertex_color_use_as_albedo = true
	m2.roughness = 1.0
	mi.material_override = m2
	add_child(mi)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var tri := mesh.create_trimesh_shape()
	tri.backface_collision = true
	cs.shape = tri
	body.add_child(cs)
	add_child(body)


func _build_props() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = u.sectors[sector_idx].rng_seed + 5
	var rock_mat := ProxyFactory.mat(Color("4a3a3a"))
	for i in 34:
		var p := Vector3(rng.randf_range(-half * 0.8, half * 0.8), 0, rng.randf_range(-half * 0.8, half * 0.8))
		if p.distance_to(ship_pos) < 30.0 or Vector2(p.x, p.z).distance_to(Vector2(core_pos.x, core_pos.z)) < 45.0:
			continue
		p.y = height(p.x, p.z)
		var sz := Vector3(rng.randf_range(3, 9), rng.randf_range(3, 12), rng.randf_range(3, 9))
		_static_box(p + Vector3(0, sz.y * 0.35, 0), sz, rock_mat, Vector3(rng.randf_range(-12, 12), rng.randf() * 180.0, rng.randf_range(-12, 12)))
	# Your parked ship.
	var ship := ProxyFactory.make_ship("interceptor", Defs.Faction.PLAYER)
	ship.position = ship_pos + Vector3(0, 2.2, 0)
	ship.scale = Vector3.ONE * 0.55
	add_child(ship)
	var pad := ProxyFactory.part(self, ProxyFactory.cyl(10, 10, 0.4, 16), ProxyFactory.mat(Color("2a2f3a")), ship_pos + Vector3(0, 0.1, 0))
	pad.name = "Pad"
	ProxyFactory.part(self, ProxyFactory.torus(9.4, 10, 24), ProxyFactory.mat(Color("ffb347"), 2.5, true), ship_pos + Vector3(0, 0.35, 0))


func _static_box(p: Vector3, sz: Vector3, m: Material, rot: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = p
	body.rotation_degrees = rot
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = sz
	cs.shape = bs
	body.add_child(cs)
	ProxyFactory.part(body, ProxyFactory.box(sz.x, sz.y, sz.z), m, Vector3.ZERO)
	add_child(body)


func _build_base() -> void:
	core = _make_foe("core", core_pos + Vector3(0, 9, 0))
	_build_spire()
	var n_pylons := level + 1
	for i in n_pylons:
		var a := TAU * float(i) / float(n_pylons)
		var p := core_pos + Vector3(cos(a) * 34.0, 0, sin(a) * 34.0)
		p.y = height(p.x, p.z)
		_make_foe("pylon", p + Vector3(0, 6, 0))
	for i in level * 2:
		var a2 := TAU * (float(i) + 0.5) / float(level * 2)
		var p2 := core_pos + Vector3(cos(a2) * 58.0, 0, sin(a2) * 58.0)
		p2.y = height(p2.x, p2.z)
		_make_foe("turret", p2 + Vector3(0, 2.5, 0))
	var hive := Color("ff3b8d")
	var body := ProxyFactory.mat(Color("2a0f2a"))
	for i in 10:
		var a3 := float(i) * 0.63
		var p3 := core_pos + Vector3(cos(a3) * 20, 0, sin(a3) * 20)
		ProxyFactory.part(self, ProxyFactory.prism(4, 14 + (i % 3) * 6, 4), body, p3 + Vector3(0, 6, 0), Vector3(randf_range(-20, 20), 0, randf_range(-20, 20)))
	ProxyFactory.part(self, ProxyFactory.torus(26, 28, 32), ProxyFactory.mat(hive, 2.0, true), core_pos + Vector3(0, 0.5, 0))


## VS-031: unshaded, fog-free landmarks so the base reads from across the map. The spire is a
## free node (it outlives nothing); each pylon beam is a child of its pylon node so it vanishes with it.
func _unlit(c: Color, alpha: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c, alpha)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.disable_fog = true
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _build_spire() -> void:
	spire_mat = _unlit(SPIRE_SHIELDED, 0.8)
	var sp := Node3D.new()
	sp.name = "Spire"
	add_child(sp)
	sp.position = core_pos
	ProxyFactory.part(sp, ProxyFactory.cyl(0.6, 3.0, SPIRE_HEIGHT, 8), spire_mat, Vector3(0, SPIRE_HEIGHT * 0.5, 0))


func _pulse_spire(delta: float) -> void:
	spire_t += delta
	var exposed := pylons_left() == 0 and core.alive
	var rate := 7.0 if exposed else 1.6
	var k := 0.5 + 0.5 * sin(spire_t * rate)
	var c := SPIRE_EXPOSED if exposed else SPIRE_SHIELDED
	spire_mat.albedo_color = Color(c, lerpf(0.45, 1.0, k))


func _make_foe(kind: String, p: Vector3) -> Foe:
	var f := Foe.new()
	f.kind = kind
	var n := Node3D.new()
	add_child(n)
	n.position = p
	f.node = n
	var hive := Color("ff3b8d")
	var glow := ProxyFactory.mat(hive, 4.0, true)
	var body := ProxyFactory.mat(Color("2a0f2a"))
	match kind:
		"core":
			f.hp_max = 1000.0 + 500.0 * float(level)
			f.radius = 8.0
			ProxyFactory.part(n, ProxyFactory.sphere(7.5, 16, 8), glow, Vector3.ZERO)
			ProxyFactory.part(n, ProxyFactory.sphere(9.5, 8, 4), body, Vector3.ZERO, Vector3(20, 30, 0), Vector3(1, 1.3, 1))
			var sh := ProxyFactory.part(n, ProxyFactory.sphere(14, 24, 12), ProxyFactory.mat(hive, 1.0, true, 0.18), Vector3.ZERO)
			sh.name = "Shield"
			var light := OmniLight3D.new()
			light.light_color = hive
			light.omni_range = 60.0
			light.light_energy = 3.0
			n.add_child(light)
		"pylon":
			f.hp_max = 260.0 + 60.0 * float(level)
			f.radius = 2.2
			ProxyFactory.part(n, ProxyFactory.prism(3, 12, 3), body, Vector3.ZERO)
			ProxyFactory.part(n, ProxyFactory.sphere(1.6, 8, 4), glow, Vector3(0, 6.5, 0))
			ProxyFactory.part(n, ProxyFactory.box(0.4, 10, 0.4), glow, Vector3(0, 0, 1.2))
			var beam := ProxyFactory.part(n, ProxyFactory.cyl(0.9, 0.9, BEAM_HEIGHT, 6), _unlit(Color("ff7ad0"), 0.7), Vector3(0, BEAM_HEIGHT * 0.5, 0))
			beam.name = "Beam"
		"turret":
			f.hp_max = 180.0
			f.radius = 2.0
			ProxyFactory.part(n, ProxyFactory.cyl(1.2, 2.2, 3, 8), body, Vector3(0, -1, 0))
			ProxyFactory.part(n, ProxyFactory.sphere(1.6, 8, 4), glow, Vector3(0, 1, 0))
		"crawler":
			f.hp_max = 45.0 + 10.0 * float(level)
			f.radius = 1.2
			ProxyFactory.part(n, ProxyFactory.sphere(1.1, 8, 4), body, Vector3(0, 0.6, 0), Vector3.ZERO, Vector3(1, 0.7, 1.5))
			for s: float in [-1.0, 1.0]:
				ProxyFactory.part(n, ProxyFactory.prism(0.3, 1.4, 0.3), body, Vector3(s * 0.9, 0.4, 0), Vector3(0, 0, s * 60))
			ProxyFactory.part(n, ProxyFactory.sphere(0.3, 6, 3), glow, Vector3(0, 0.8, -1.4))
		"drone":
			f.hp_max = 55.0 + 10.0 * float(level)
			f.radius = 1.3
			ProxyFactory.part(n, ProxyFactory.sphere(1.0, 4, 2), body, Vector3.ZERO, Vector3.ZERO, Vector3(1, 0.6, 1.4))
			ProxyFactory.part(n, ProxyFactory.sphere(0.35, 6, 3), glow, Vector3(0, 0, -1.2))
			ProxyFactory.part(n, ProxyFactory.box(3.2, 0.1, 0.5), glow, Vector3.ZERO)
	f.hp = f.hp_max
	f.cd = randf_range(0.5, 2.0)
	f.phase = randf() * TAU
	foes.append(f)
	return f


func _spawn_foe(kind: String, p: Vector3) -> void:
	p.y = height(p.x, p.z) + (8.0 if kind == "drone" else 0.6)
	_make_foe(kind, p)


func pylons_left() -> int:
	var n := 0
	for f: Foe in foes:
		if f.alive and f.kind == "pylon":
			n += 1
	return n


func mobiles_alive() -> int:
	var n := 0
	for f: Foe in foes:
		if f.alive and (f.kind == "crawler" or f.kind == "drone"):
			n += 1
	return n


func objective_text() -> String:
	if core_dead:
		return "CORE DESTROYED — return to your ship to take off"
	var p := pylons_left()
	if p > 0:
		return "Destroy the shield pylons (%d left), then the Hive Core" % p
	return "Core exposed — DESTROY THE HIVE CORE  (%d%%)" % int(core.hp / core.hp_max * 100.0)


func markers() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var hive := Color("ff3b8d")
	if core_dead:
		out.append({"pos": ship_pos + Vector3(0, 4, 0), "col": Color("ffb347"), "label": "SHIP"})
		return out
	for f: Foe in foes:
		if f.alive and (f.kind == "pylon" or (f.kind == "core" and pylons_left() == 0)):
			out.append({"pos": f.node.position + Vector3(0, 7, 0), "col": hive, "label": f.kind.to_upper()})
	return out


# --- Per-frame ----------------------------------------------------------------------------
func tick(delta: float) -> void:
	if autoplay:
		_bot()
	fps.tick(delta)
	if fps.global_position.y < -200.0:
		fps.global_position = ship_pos + Vector3(0, 4, 0)
	var shield_up := pylons_left() > 0
	if core.alive and is_instance_valid(core.node):
		var sh := core.node.get_node_or_null("Shield") as Node3D
		if sh:
			sh.visible = shield_up
	_pulse_spire(delta)
	_update_foes(delta)
	_update_shots(delta)
	_update_fx(delta)
	if not core_dead:
		wave_t -= delta
		if wave_t <= 0.0:
			wave_t = maxf(9.0, 24.0 - float(level) * 4.0)
			var alive_mobile := 0
			for f: Foe in foes:
				if f.alive and (f.kind == "crawler" or f.kind == "drone"):
					alive_mobile += 1
			for i in mini(2 + level, MAX_FOES - alive_mobile):
				_spawn_foe("drone" if randf() < 0.4 else "crawler", core_pos + Vector3(randf_range(-20, 20), 0, randf_range(-20, 20)))
	prompt = ""
	if fps.global_position.distance_to(ship_pos) < BOARD_DIST:
		prompt = ("ACT" if touch.active else "F") + ": Board ship and take off"
		if Input.is_action_just_pressed("act") or touch.pressed("act") or (autoplay and core_dead):
			takeoff_requested.emit()


func _bot() -> void:
	var best: Foe = null
	var best_d := INF
	var pp := fps.global_position
	for f: Foe in foes:
		if not f.alive or (f.kind == "core" and pylons_left() > 0):
			continue
		var d := f.node.position.distance_to(pp)
		if f.flank:
			d -= BOT_MOB_PRIORITY   # VS-037: the bot answers flankers before shooting the base
		if d < best_d:
			best_d = d
			best = f
	fps.bot_target = best.node.position if best else null
	var goal := core_pos if not core_dead else ship_pos
	var to := goal - pp
	to.y = 0.0
	# VS-037: the bot keeps moving: closes to 25 m, then strafes around the goal, flipping direction every BOT_STRAFE_TIME.
	if core_dead:
		fps.bot_move = to.normalized() if to.length() > BOARD_DIST * 0.5 else Vector3.ZERO   # keep walking until aboard
	elif to.length() > 25.0:
		fps.bot_move = to.normalized()
	else:
		var side := to.normalized().cross(Vector3.UP)
		bot_t += get_process_delta_time()
		fps.bot_move = side * (1.0 if int(bot_t / BOT_STRAFE_TIME) % 2 == 0 else -1.0)


func _update_foes(delta: float) -> void:
	var pp := fps.global_position + Vector3(0, 1.0, 0)
	for f: Foe in foes:
		if not f.alive:
			continue
		f.phase += delta
		var n := f.node
		var to := pp - n.position
		var d := to.length()
		match f.kind:
			"crawler":
				var dir := Vector3(to.x, 0, to.z).normalized()
				f.vel = f.vel.move_toward(dir * (9.0 + float(level)) * (Defs.FLANK_SPEED_MULT if f.flank else 1.0), 30.0 * delta)
				var np := n.position + f.vel * delta
				np.y = height(np.x, np.z) + 0.6 + absf(sin(f.phase * 12.0)) * 0.25
				n.position = np
				if d > 0.5:
					n.look_at(Vector3(pp.x, np.y, pp.z), Vector3.UP)
				f.cd -= delta
				if d < 2.2 and f.cd <= 0.0:
					f.cd = 0.8
					_hurt_player((10.0 + 2.0 * float(level)) * (Defs.FLANK_DAMAGE_MULT if f.flank else 1.0))
			"drone":
				var want_h := height(n.position.x, n.position.z) + 7.0 + sin(f.phase * 1.7) * 2.0
				var side := to.cross(Vector3.UP).normalized() * sin(f.phase * 0.8) * 6.0
				var desire := (Vector3(to.x, 0, to.z).normalized() * (1.0 if d > 30.0 else -0.5)) * 8.0 + side
				f.vel = f.vel.move_toward(desire, 14.0 * delta)
				var np2 := n.position + f.vel * delta
				np2.y = lerpf(np2.y, want_h, 1.0 - exp(-3.0 * delta))
				n.position = np2
				n.look_at(pp, Vector3.UP)
				_try_shoot(f, d, 70.0, 1.6, delta)
			"turret":
				_try_shoot(f, d, 95.0, 1.1, delta)
			"core":
				n.rotate_y(delta * 0.5)
				n.scale = Vector3.ONE * (1.0 + sin(f.phase * 3.0) * 0.04)
				_try_shoot(f, d, 80.0, 0.7 if pylons_left() == 0 else 2.5, delta)


func _try_shoot(f: Foe, d: float, rng: float, interval: float, delta: float) -> void:
	f.cd -= delta
	if d > rng or f.cd > 0.0:
		return
	f.cd = interval * randf_range(0.8, 1.2)
	var origin := f.node.position + Vector3(0, 0.5, 0)
	var aim := fps.global_position + Vector3(0, 1.2, 0) + fps.velocity * (d / FOE_SHOT_SPEED) * 0.5
	var v := (aim - origin).normalized() * FOE_SHOT_SPEED
	var mi := ProxyFactory.part(self, ProxyFactory.sphere(0.35, 8, 4), ProxyFactory.mat(Color("ff5aa8"), 5.0, true), origin)
	shots.append({"node": mi, "vel": v, "life": 4.0})


func _update_shots(delta: float) -> void:
	var pp := fps.global_position + Vector3(0, 1.0, 0)
	for i in range(shots.size() - 1, -1, -1):
		var s: Dictionary = shots[i]
		var n := s["node"] as Node3D
		n.position += (s["vel"] as Vector3) * delta
		s["life"] = float(s["life"]) - delta
		var dead := float(s["life"]) <= 0.0
		if n.position.distance_to(pp) < 1.3:
			_hurt_player(8.0 + 2.0 * float(level))
			dead = true
		elif n.position.y < height(n.position.x, n.position.z):
			dead = true
		if dead:
			n.queue_free()
			shots.remove_at(i)


func _hurt_player(amount: float) -> void:
	fps.take_damage(amount)
	player_damaged.emit(amount)


# --- Shooting ---------------------------------------------------------------------------------
func _on_fired(origin: Vector3, dir: Vector3) -> void:
	var end := origin + dir * RIFLE_RANGE
	var q := PhysicsRayQueryParameters3D.create(origin, end)
	q.exclude = [fps.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var wall_d := RIFLE_RANGE
	if not hit.is_empty():
		wall_d = origin.distance_to(hit["position"])
	var best: Foe = null
	var best_t := wall_d
	for f: Foe in foes:
		if not f.alive:
			continue
		var c := f.node.position
		var t := (c - origin).dot(dir)
		if t < 0.0 or t > best_t:
			continue
		var closest := origin + dir * t
		var r := f.radius * (1.25 if f.kind == "core" and pylons_left() > 0 else 1.0)
		if closest.distance_to(c) < r * 1.15:
			best_t = t
			best = f
	var impact := origin + dir * best_t
	sfx.emit("rifle")
	_tracer(fps.flash.global_position, impact)
	if best:
		if best.kind == "core" and pylons_left() > 0:
			_spark(impact, Color("ff3b8d"), 0.8)   # shield deflects
			return
		best.hp -= RIFLE_DAMAGE
		hit_something.emit()
		_spark(impact, Color("ffcf7a"), 0.5)
		if best.hp <= 0.0:
			_kill(best)
	elif not hit.is_empty():
		_spark(impact, Color("c0a080"), 0.3)


## VS-037: spawn the flank squad FLANK_ANGLE_MIN..MAX degrees off the player's heading (random side). Returns the count.
func spawn_flank() -> int:
	flanked = true
	var heading := -fps.global_transform.basis.z
	heading.y = 0.0
	heading = heading.normalized() if heading.length() > 0.01 else Vector3.FORWARD
	var n := randi_range(Defs.FLANK_MIN, Defs.FLANK_MAX)
	var lim := half * 0.92
	for i in n:
		var ang := deg_to_rad(randf_range(Defs.FLANK_ANGLE_MIN, Defs.FLANK_ANGLE_MAX)) * (1.0 if randf() < 0.5 else -1.0)
		var p := fps.global_position + heading.rotated(Vector3.UP, ang) * Defs.FLANK_DIST
		p.x = clampf(p.x, -lim, lim)
		p.z = clampf(p.z, -lim, lim)
		_spawn_foe("drone" if i % Defs.FLANK_DRONE_EVERY == Defs.FLANK_DRONE_EVERY - 1 else "crawler", p)
		foes[foes.size() - 1].flank = true
		flank_spawned += 1
	return n


func _kill(f: Foe) -> void:
	f.alive = false
	sfx.emit("explosion")
	sfx.emit("kill")
	kill_confirmed.emit(f.kind == "core" or f.kind == "pylon")
	var big := f.kind == "core"
	_explode(f.node.position, 14.0 if big else (4.0 if f.kind == "pylon" else 2.0))
	f.node.queue_free()
	if f.kind == "pylon" and not flanked and not core_dead:
		spawn_flank()
	if f.kind == "crawler" or f.kind == "drone":
		u.add_credits(60.0, "bounty")
	if big:
		core_dead = true
		u.core_destroyed(sector_idx)
		core_killed.emit()
		for o: Foe in foes:
			if o.alive:
				o.alive = false
				_explode(o.node.position, 2.0)
				o.node.queue_free()
	foes = foes.filter(func(o: Foe) -> bool: return o.alive or o == core)


func _tracer(a: Vector3, b: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var len := a.distance_to(b)
	mi.mesh = ProxyFactory.box(0.03, 0.03, len)
	mi.material_override = ProxyFactory.mat(Color("ffd890"), 4.0, true)
	add_child(mi)
	mi.position = (a + b) * 0.5
	if len > 0.01:
		mi.look_at(b, Vector3.UP if absf((b - a).normalized().y) < 0.99 else Vector3.RIGHT)
	fx.append({"node": mi, "t": 0.0, "dur": 0.05, "grow": 0.0})


func _spark(p: Vector3, c: Color, s: float) -> void:
	var mi := ProxyFactory.part(self, ProxyFactory.sphere(1.0, 6, 3), ProxyFactory.mat(c, 5.0, true), p)
	mi.scale = Vector3.ONE * s
	fx.append({"node": mi, "t": 0.0, "dur": 0.12, "grow": s})


func _explode(p: Vector3, s: float) -> void:
	var mi := ProxyFactory.part(self, ProxyFactory.sphere(1.0, 12, 6), ProxyFactory.mat(Color("fff1c0"), 6.0, true), p)
	fx.append({"node": mi, "t": 0.0, "dur": 0.5, "grow": s})
	var ring := ProxyFactory.part(self, ProxyFactory.sphere(1.0, 12, 6), ProxyFactory.mat(Color("ff3b8d"), 3.0, true, 0.5), p)
	fx.append({"node": ring, "t": 0.0, "dur": 0.8, "grow": s * 2.0})


func _update_fx(delta: float) -> void:
	for i in range(fx.size() - 1, -1, -1):
		var f: Dictionary = fx[i]
		f["t"] = float(f["t"]) + delta
		var k := float(f["t"]) / float(f["dur"])
		var n := f["node"] as Node3D
		var g: float = f["grow"]
		if g > 0.0:
			n.scale = Vector3.ONE * g * (0.4 + k) * (1.0 - k * 0.5)
		if k >= 1.0:
			n.queue_free()
			fx.remove_at(i)
