class_name SpaceView
extends Node3D
## Renders the player's current sector from sim data and runs the flight layer:
## proxies, lasers, explosions, gates, docking and landing prompts.

signal dock_requested(st: StationData)
signal land_requested(sector_idx: int)
signal sector_entered(sector_idx: int)
signal player_hit_something()
signal player_damaged(amount: float)
signal sfx(sound: String)

const BOLT_SPEED := 2600.0
const BOLT_LIFE := 1.1
const BOLT_DAMAGE := 11.0
const NPC_BOLT_SPEED := 2200.0
const MAX_BOLTS := 160
const CAM_OFFSET := Vector3(0, 9, 36)
const CAM_SMOOTH := 9.0
const GATE_TRIGGER := 95.0
const DUST_COUNT := 160
const DUST_BOX := 300.0
const EXPLOSION_HEAR_RANGE := 2500.0

var u: Universe
var touch: TouchControls
var sector_idx: int = -1
var world: Node3D
var proxies: Dictionary = {}       # id -> Node3D
var gates: Array[Node3D] = []
var planet: Node3D
var player: PlayerFlight
var cam: Camera3D
var env: WorldEnvironment
var sun: DirectionalLight3D
var bolts: Array[Dictionary] = []
var fx: Array[Dictionary] = []
var dust: MultiMeshInstance3D
var target_id: int = 0
var prompt: String = ""
var _prompt_action: Callable
var docked: bool = false
var flight_enabled: bool = true
var shake: float = 0.0
var _last_hp: float = 0.0
var autoplay: bool = false


func setup(p_u: Universe, p_touch: TouchControls) -> void:
	u = p_u
	touch = p_touch
	cam = Camera3D.new()
	cam.far = 40000.0
	cam.near = 0.5
	cam.fov = 72.0
	add_child(cam)
	env = WorldEnvironment.new()
	env.environment = Environment.new()
	add_child(env)
	sun = DirectionalLight3D.new()
	sun.light_energy = 1.2
	sun.rotation_degrees = Vector3(-35, 40, 0)
	add_child(sun)
	u.shot.connect(_on_shot)
	u.destroyed.connect(_on_destroyed)
	u.planet_changed.connect(func(idx: int) -> void:
		if idx == sector_idx:
			_build_sector())
	_make_dust()


func _exit_tree() -> void:
	if env and not env.is_inside_tree():
		env.queue_free()


func spawn_player() -> void:
	if player:
		player.queue_free()
	player = PlayerFlight.new()
	player.setup(u.player_ship, touch)
	player.autopilot = autoplay
	add_child(player)
	player.fired.connect(_on_player_fired)
	var face := u.hq.pos if u.hq and u.hq.alive and u.hq.sector == u.player_ship.sector else Vector3.ZERO
	player.look_at_from_position(u.player_ship.pos, u.player_ship.pos + (u.player_ship.pos - face).normalized() * 100.0 + Vector3(0, 0.01, 0), Vector3.UP)
	cam.global_transform = player.global_transform.translated_local(CAM_OFFSET)
	_last_hp = u.player_ship.hull + u.player_ship.shield
	docked = false
	if u.player_ship.sector != sector_idx:
		enter_sector(u.player_ship.sector)


func enter_sector(idx: int) -> void:
	sector_idx = idx
	_build_sector()
	sector_entered.emit(idx)


func _build_sector() -> void:
	if world:
		world.queue_free()
	for p: Node3D in proxies.values():
		p.queue_free()
	proxies.clear()
	gates.clear()
	for b: Dictionary in bolts:
		(b["node"] as Node3D).queue_free()
	bolts.clear()
	world = Node3D.new()
	add_child(world)
	var s := u.sectors[sector_idx]
	var e := env.environment
	e.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var tints: Array[Color] = [Color("3a1f6a"), Color("1f4a6a"), Color("2a5a4a"), Color("6a3a1f"), Color("6a1f4a"), Color("5a0f3a"), Color("4a2a1a")]
	sky.sky_material = ProxyFactory.sky_material(tints[sector_idx % tints.size()])
	e.sky = sky
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("6a7aa0")
	e.ambient_light_energy = 0.55
	e.glow_enabled = true
	e.glow_intensity = 0.7
	e.glow_bloom = 0.05
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	for g: Dictionary in s.gates:
		var to: int = g["to"]
		var gn := ProxyFactory.make_gate(u.sectors[to].name)
		gn.position = g["pos"]
		world.add_child(gn)
		gn.look_at(Vector3(0, 0.001, 0), Vector3.UP)
		gn.set_meta("to", to)
		gates.append(gn)
	planet = Node3D.new()
	planet.position = s.planet_pos
	world.add_child(planet)
	var pm := MeshInstance3D.new()
	pm.mesh = ProxyFactory.sphere(Defs.PLANET_RADIUS, 64, 32)
	pm.material_override = ProxyFactory.planet_material(s.planet_state, s.rng_seed)
	planet.add_child(pm)
	var atmo_col := Color("ff4fa0") if s.planet_state == "hive" else (Color("ffb347") if s.planet_state == "colony" else Color("6ab8ff"))
	var am := MeshInstance3D.new()
	am.mesh = ProxyFactory.sphere(Defs.PLANET_RADIUS * 1.07, 48, 24)
	am.material_override = ProxyFactory.atmosphere_material(atmo_col)
	planet.add_child(am)
	for i in s.fields.size():
		var f: Dictionary = s.fields[i]
		var mmi := ProxyFactory.make_field(f["radius"], s.rng_seed + i)
		mmi.position = f["pos"]
		world.add_child(mmi)
	_sync_proxies(0.0)


# --- Per-frame -------------------------------------------------------------------------------
func tick(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var pd := u.player_ship
	if not docked and pd.alive:
		player.input_enabled = flight_enabled
		if autoplay:
			var t := u.get_ent(target_id)
			if t == null or not t.alive or t.sector != sector_idx:
				_cycle_target()
				t = u.get_ent(target_id)
			player.bot_goal = t.pos if t else Vector3(0, 0, 0)
		player.aim_point = _lead_point()
		player.tick(delta)
		_collide_player()
		u.player_evasion = clampf(player.speed() / 600.0, 0.0, 0.6)
		if flight_enabled:
			_handle_flight_input()
		_check_gates()
	_sync_proxies(delta)
	_update_bolts(delta)
	_update_fx(delta)
	_update_camera(delta)
	_update_dust()
	_update_prompt()
	var hp := pd.hull + pd.shield
	if hp < _last_hp - 0.5:
		shake = minf(shake + (_last_hp - hp) * 0.04, 1.2)
		player_damaged.emit(_last_hp - hp)
		player.drop_travel()
	_last_hp = hp


func _handle_flight_input() -> void:
	if Input.is_action_just_pressed("target") or touch.pressed("target"):
		_cycle_target()
	if (Input.is_action_just_pressed("act") or touch.pressed("act")) and _prompt_action.is_valid():
		_prompt_action.call()
	if Input.is_action_just_pressed("fleet_attack"):
		_fleet_attack()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not flight_enabled or docked:
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed and event.device != InputEvent.DEVICE_ID_EMULATION:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()


func _cycle_target() -> void:
	var best_score := INF
	var best_id := 0
	var fwd := -player.global_transform.basis.z
	for e: SimEntity in u.ents_in(sector_idx):
		if e.faction != Defs.Faction.HIVE or not e.alive or e.id == target_id:
			continue
		var to := e.pos - player.position
		var d := to.length()
		var facing := fwd.dot(to / maxf(d, 0.01))
		var score := d * (2.0 - facing)
		if score < best_score:
			best_score = score
			best_id = e.id
	if best_id == 0:
		var cur := u.get_ent(target_id)
		if cur == null or not cur.alive:
			target_id = 0
		return
	target_id = best_id


func _fleet_attack() -> void:
	var t := u.get_ent(target_id)
	if t == null:
		return
	var n := 0
	for e: SimEntity in u.ents_in(sector_idx):
		if e is ShipData and e.faction == Defs.Faction.PLAYER and e.armed() and not (e as ShipData).is_player:
			(e as ShipData).order = "attack"
			(e as ShipData).order_target = t.id
			n += 1
	if n > 0:
		u.message.emit("%d ships attacking %s" % [n, t.display_name], Defs.faction_color(Defs.Faction.PLAYER))


func _lead_point() -> Variant:
	var t := u.get_ent(target_id)
	if t == null or not t.alive or t.sector != sector_idx:
		return null
	var d := t.pos.distance_to(player.position)
	var tt := d / BOLT_SPEED
	return t.pos + (t.vel - player.vel * 0.0) * tt


func _collide_player() -> void:
	for e: SimEntity in u.ents_in(sector_idx):
		if not e.is_station:
			continue
		var r := e.radius * 0.85
		var to := player.position - e.pos
		if to.length() < r:
			player.position = e.pos + to.normalized() * r
			player.vel = player.vel.bounce(to.normalized()) * 0.3
	var s := u.sectors[sector_idx]
	var tp := player.position - s.planet_pos
	if tp.length() < Defs.PLANET_RADIUS + 40.0:
		player.position = s.planet_pos + tp.normalized() * (Defs.PLANET_RADIUS + 40.0)
		player.vel = player.vel.slide(tp.normalized())
	u.player_ship.pos = player.position


func _check_gates() -> void:
	for gn: Node3D in gates:
		if player.position.distance_to(gn.position) < GATE_TRIGGER:
			var to: int = gn.get_meta("to")
			var from := sector_idx
			u.player_ship.sector = to
			enter_sector(to)
			var gin := u.sectors[to].gate_to(from)
			var gp: Vector3 = gin["pos"]
			var inward := -gp.normalized()
			player.position = gp + inward * 320.0
			player.look_at(player.position + inward * 100.0, Vector3.UP)
			player.vel = inward * player.speed()
			u.player_ship.pos = player.position
			cam.global_transform = player.global_transform.translated_local(CAM_OFFSET)
			shake = 0.6
			sfx.emit("gate")
			u.message.emit("Entered %s" % u.sectors[to].name, Color("8fd8ff"))
			return


func _update_prompt() -> void:
	prompt = ""
	_prompt_action = Callable()
	if docked or not u.player_ship.alive:
		return
	var best: StationData = null
	var best_d := INF
	for e: SimEntity in u.ents_in(sector_idx):
		if e is StationData and e.faction != Defs.Faction.HIVE:
			var d := e.pos.distance_to(player.position) - e.radius
			if d < Defs.DOCK_DIST and d < best_d:
				best_d = d
				best = e as StationData
	var key := "ACT" if touch.active else "F"
	if best:
		prompt = "%s: Dock at %s" % [key, best.display_name]
		var st := best
		_prompt_action = func() -> void: dock_requested.emit(st)
		return
	var s := u.sectors[sector_idx]
	if player.position.distance_to(s.planet_pos) < Defs.PLANET_RADIUS + Defs.LAND_MARGIN:
		match s.planet_state:
			"hive":
				prompt = "%s: Land on %s — Hive Core (threat %d)" % [key, s.planet_name, s.level]
				var idx := sector_idx
				_prompt_action = func() -> void: land_requested.emit(idx)
			"colony":
				prompt = "%s colony: secure (+%d cr/min)" % [s.planet_name, int(Defs.COLONY_INCOME)]
			_:
				prompt = "%s: Union world — landing restricted" % s.planet_name


# --- Proxies ------------------------------------------------------------------------------
func _sync_proxies(delta: float) -> void:
	var seen: Dictionary = {}
	for e: SimEntity in u.ents_in(sector_idx):
		if e == u.player_ship:
			continue
		if e is ShipData and (e as ShipData).hidden:
			continue
		seen[e.id] = true
		var p: Node3D = proxies.get(e.id)
		if p == null:
			if e is ShipData:
				p = ProxyFactory.make_ship((e as ShipData).cls, e.faction)
			else:
				p = ProxyFactory.make_station((e as StationData).kind, e.faction)
			world.add_child(p)
			p.position = e.pos
			proxies[e.id] = p
		p.position = e.pos
		if e is ShipData:
			if e.vel.length() > 5.0:
				var want := Basis.looking_at(e.vel.normalized(), Vector3.UP)
				p.basis = p.basis.slerp(want, 1.0 - exp(-5.0 * delta)) if delta > 0.0 else want
		else:
			var spin := p.get_node_or_null("Spin") as Node3D
			if spin:
				spin.rotate_y(delta * 0.08)
			var sh := p.get_node_or_null("Shield") as Node3D
			if sh:
				sh.visible = not e.can_be_damaged()
	for id: int in proxies.keys():
		if not seen.has(id):
			(proxies[id] as Node3D).queue_free()
			proxies.erase(id)


# --- Weapons + FX ------------------------------------------------------------------------------
func _on_player_fired(origin: Vector3, dir: Vector3) -> void:
	_spawn_bolt(origin, dir * BOLT_SPEED + player.vel, Defs.faction_color(Defs.Faction.PLAYER), true, BOLT_LIFE)
	sfx.emit("laser")


func _spawn_bolt(origin: Vector3, v: Vector3, col: Color, is_player: bool, life: float) -> void:
	if bolts.size() >= MAX_BOLTS:
		var old: Dictionary = bolts.pop_front()
		(old["node"] as Node3D).queue_free()
	var mi := MeshInstance3D.new()
	mi.mesh = ProxyFactory.box(0.7, 0.7, 14.0 if is_player else 18.0)
	mi.material_override = ProxyFactory.mat(col, 4.0, true)
	world.add_child(mi)
	mi.position = origin
	if v.length() > 0.1:
		mi.look_at(origin + v, Vector3.UP if absf(v.normalized().y) < 0.99 else Vector3.RIGHT)
	bolts.append({"node": mi, "pos": origin, "vel": v, "life": life, "player": is_player})


func _on_shot(src_id: int, dst_id: int) -> void:
	var src := u.get_ent(src_id)
	var dst := u.get_ent(dst_id)
	if src == null or dst == null or src.sector != sector_idx or not visible:
		return
	var aim := dst.pos + Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * dst.radius * 0.6
	var dir := (aim - src.pos).normalized()
	var start := src.pos + dir * src.radius
	var life := start.distance_to(aim) / NPC_BOLT_SPEED
	_spawn_bolt(start, dir * NPC_BOLT_SPEED, Defs.faction_color(src.faction).lightened(0.2), false, life)


func _update_bolts(delta: float) -> void:
	for i in range(bolts.size() - 1, -1, -1):
		var b: Dictionary = bolts[i]
		var from: Vector3 = b["pos"]
		var to: Vector3 = from + (b["vel"] as Vector3) * delta
		b["pos"] = to
		b["life"] = float(b["life"]) - delta
		var node := b["node"] as Node3D
		node.position = to
		var dead := float(b["life"]) <= 0.0
		if bool(b["player"]) and not dead:
			var hit := _bolt_hit(from, to)
			if hit:
				u.player_hit(hit, BOLT_DAMAGE)
				_spark(to, Defs.faction_color(Defs.Faction.PLAYER), 6.0)
				player_hit_something.emit()
				dead = true
		elif dead and not bool(b["player"]):
			_spark(to, (node as MeshInstance3D).material_override.get("albedo_color"), 4.0)
		if dead:
			node.queue_free()
			bolts.remove_at(i)


func _bolt_hit(a: Vector3, b: Vector3) -> SimEntity:
	var seg := b - a
	var len2 := seg.length_squared()
	for e: SimEntity in u.ents_in(sector_idx):
		if e.faction != Defs.Faction.HIVE or not e.alive:
			continue
		var t := clampf((e.pos - a).dot(seg) / maxf(len2, 0.001), 0.0, 1.0)
		var closest := a + seg * t
		var r := e.radius * (0.9 if e.is_station else 1.6)
		if closest.distance_squared_to(e.pos) < r * r:
			return e
	return null


func _on_destroyed(ent: SimEntity, _killer: int) -> void:
	if ent.sector != sector_idx:
		return
	var size := ent.radius * (2.5 if ent.is_station else 3.0)
	explode(ent.pos, size, Defs.faction_color(ent.faction))
	if player and ent.pos.distance_to(player.position) < EXPLOSION_HEAR_RANGE:
		sfx.emit("explosion")
	if player and ent.pos.distance_to(player.position) < 900.0:
		shake = minf(shake + 0.4, 1.2)
	if ent.id == target_id:
		target_id = 0
		_cycle_target()


func explode(pos: Vector3, size: float, col: Color) -> void:
	var core := MeshInstance3D.new()
	core.mesh = ProxyFactory.sphere(1.0, 12, 6)
	core.material_override = ProxyFactory.mat(Color("fff1c0"), 6.0, true).duplicate()
	world.add_child(core)
	core.position = pos
	var ring := MeshInstance3D.new()
	ring.mesh = ProxyFactory.sphere(1.0, 12, 6)
	ring.material_override = ProxyFactory.mat(col, 3.0, true, 0.6).duplicate()
	world.add_child(ring)
	ring.position = pos
	var light := OmniLight3D.new()
	light.light_color = col.lightened(0.4)
	light.omni_range = size * 6.0
	light.light_energy = 6.0
	world.add_child(light)
	light.position = pos
	fx.append({"core": core, "ring": ring, "light": light, "t": 0.0, "dur": 0.9, "size": size})
	for i in 6:
		var deb := MeshInstance3D.new()
		deb.mesh = ProxyFactory.box(1, 1, 1)
		deb.material_override = ProxyFactory.mat(Color("ffcf7a"), 4.0, true)
		world.add_child(deb)
		deb.position = pos
		deb.scale = Vector3.ONE * size * 0.08
		fx.append({"debris": deb, "vel": Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized() * size * 3.0, "t": 0.0, "dur": 1.2, "size": size})


func _spark(pos: Vector3, col: Color, size: float) -> void:
	var s := MeshInstance3D.new()
	s.mesh = ProxyFactory.sphere(1.0, 6, 3)
	s.material_override = ProxyFactory.mat(col, 5.0, true)
	world.add_child(s)
	s.position = pos
	fx.append({"core": s, "t": 0.0, "dur": 0.18, "size": size})


func _update_fx(delta: float) -> void:
	for i in range(fx.size() - 1, -1, -1):
		var f: Dictionary = fx[i]
		f["t"] = float(f["t"]) + delta
		var k := float(f["t"]) / float(f["dur"])
		var size: float = f["size"]
		if f.has("core"):
			(f["core"] as Node3D).scale = Vector3.ONE * size * (0.3 + k * 0.9) * (1.0 - k * 0.6)
		if f.has("ring"):
			var ring := f["ring"] as MeshInstance3D
			ring.scale = Vector3.ONE * size * (0.4 + k * 1.6)
			(ring.material_override as StandardMaterial3D).albedo_color.a = 0.6 * (1.0 - k)
		if f.has("light"):
			(f["light"] as OmniLight3D).light_energy = 6.0 * (1.0 - k)
		if f.has("debris"):
			var d := f["debris"] as Node3D
			d.position += (f["vel"] as Vector3) * delta
			d.rotate_x(delta * 5.0)
			d.scale = Vector3.ONE * size * 0.08 * (1.0 - k)
		if k >= 1.0:
			for key: String in ["core", "ring", "light", "debris"]:
				if f.has(key):
					(f[key] as Node).queue_free()
			fx.remove_at(i)


# --- Camera + dust -------------------------------------------------------------------------------
func _update_camera(delta: float) -> void:
	if player == null:
		return
	var off := CAM_OFFSET
	if player.travel and player.travel_charge > PlayerFlight.TRAVEL_CHARGE:
		off.z += 10.0
	var want := player.global_transform.translated_local(off)
	want = want.looking_at(player.global_transform * Vector3(0, 3, -80), player.global_transform.basis.y)
	cam.global_transform = cam.global_transform.interpolate_with(want, 1.0 - exp(-CAM_SMOOTH * delta))
	var fov_want := 72.0 + clampf(player.speed() / max(player.max_speed(), 1.0) - 1.0, 0.0, 3.5) * 8.0
	cam.fov = lerpf(cam.fov, fov_want, 1.0 - exp(-3.0 * delta))
	shake = maxf(shake - delta * 1.8, 0.0)
	if shake > 0.0:
		cam.h_offset = randf_range(-1, 1) * shake * 1.5
		cam.v_offset = randf_range(-1, 1) * shake * 1.5
	else:
		cam.h_offset = 0.0
		cam.v_offset = 0.0


func _make_dust() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = ProxyFactory.box(0.25, 0.25, 0.25)
	mm.instance_count = DUST_COUNT
	for i in DUST_COUNT:
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * DUST_BOX))
	dust = MultiMeshInstance3D.new()
	dust.multimesh = mm
	dust.material_override = ProxyFactory.mat(Color("c8d8ff"), 0.8, true)
	add_child(dust)


func _update_dust() -> void:
	if cam == null:
		return
	var c := cam.global_position
	var mm := dust.multimesh
	for i in DUST_COUNT:
		var p := mm.get_instance_transform(i).origin
		var rel := p - c
		if absf(rel.x) > DUST_BOX or absf(rel.y) > DUST_BOX or absf(rel.z) > DUST_BOX:
			rel.x = wrapf(rel.x, -DUST_BOX, DUST_BOX)
			rel.y = wrapf(rel.y, -DUST_BOX, DUST_BOX)
			rel.z = wrapf(rel.z, -DUST_BOX, DUST_BOX)
			mm.set_instance_transform(i, Transform3D(Basis(), c + rel))


# --- Docking ----------------------------------------------------------------------------------
func set_docked(on: bool, at: StationData = null) -> void:
	docked = on
	u.player_ship.hidden = on
	player.visible = not on
	if not on and at:
		var out := (player.position - at.pos).normalized()
		if out.length() < 0.1:
			out = Vector3.BACK
		player.position = at.pos + out * (at.radius + 160.0)
		player.look_at(player.position + out * 100.0, Vector3.UP)
		player.vel = Vector3.ZERO
		player.throttle = 0.2
		u.player_ship.pos = player.position
