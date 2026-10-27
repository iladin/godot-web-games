class_name ProxyFactory
extends RefCounted
## Procedural visuals: every mesh in space is built here from primitives. No assets.

const HULL_DARK := Color("1c2030")
const HULL_MID := Color("3a4258")
const HIVE_BODY := Color("2a0f2a")

static var _mats: Dictionary = {}


static func mat(color: Color, emission: float = 0.0, unshaded: bool = false, alpha: float = 1.0) -> StandardMaterial3D:
	var key := "%s|%.2f|%s|%.2f" % [color.to_html(), emission, unshaded, alpha]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color, alpha)
	m.roughness = 0.6
	m.metallic = 0.3
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mats[key] = m
	return m


static func part(parent: Node3D, mesh: Mesh, material: Material, pos: Vector3, rot_deg: Vector3 = Vector3.ZERO, scl: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	mi.rotation_degrees = rot_deg
	mi.scale = scl
	parent.add_child(mi)
	return mi


static func box(x: float, y: float, z: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(x, y, z)
	return b


static func prism(x: float, y: float, z: float) -> PrismMesh:
	var p := PrismMesh.new()
	p.size = Vector3(x, y, z)
	return p


static func sphere(r: float, segs: int = 12, rings: int = 6) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = segs
	s.rings = rings
	return s


static func cyl(top: float, bottom: float, h: float, segs: int = 12) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = segs
	c.rings = 1
	return c


static func torus(inner: float, outer: float, segs: int = 32) -> TorusMesh:
	var t := TorusMesh.new()
	t.inner_radius = inner
	t.outer_radius = outer
	t.rings = segs
	t.ring_segments = 8
	return t


# --- Ships ------------------------------------------------------------------------------
## Ships face -Z. Size roughly matches Defs radius.
static func make_ship(cls: String, faction: int) -> Node3D:
	var root := Node3D.new()
	var fc := Defs.faction_color(faction)
	var glow := mat(fc, 3.0, true)
	var hull := mat(HULL_MID if faction != Defs.Faction.HIVE else HIVE_BODY)
	var dark := mat(HULL_DARK)
	match cls:
		"interceptor", "fighter":
			var s := 1.0 if cls == "interceptor" else 0.8
			part(root, prism(10 * s, 22 * s, 3 * s), hull, Vector3.ZERO, Vector3(-90, 0, 0))
			part(root, box(26 * s, 0.8 * s, 7 * s), dark, Vector3(0, 0, 4 * s))
			part(root, box(1.2 * s, 0.9 * s, 7.2 * s), glow, Vector3(12.5 * s, 0, 4 * s))
			part(root, box(1.2 * s, 0.9 * s, 7.2 * s), glow, Vector3(-12.5 * s, 0, 4 * s))
			part(root, box(3 * s, 2.2 * s, 14 * s), dark, Vector3(0, 1.0 * s, 3 * s))
			for x: float in [-3.2, 3.2]:
				part(root, cyl(1.5 * s, 1.8 * s, 6 * s, 10), dark, Vector3(x * s, 0, 9 * s), Vector3(90, 0, 0))
				part(root, cyl(1.2 * s, 1.2 * s, 0.3 * s, 10), mat(Color("ff8a3a"), 5.0, true), Vector3(x * s, 0, 12.1 * s), Vector3(90, 0, 0))
			part(root, sphere(1.6 * s, 10, 5), mat(Color("4fb8d8"), 0.8), Vector3(0, 1.9 * s, -2.5 * s), Vector3.ZERO, Vector3(1, 0.6, 2.0))
		"corvette":
			part(root, box(12, 8, 46), hull, Vector3.ZERO)
			part(root, prism(12, 14, 8), hull, Vector3(0, 0, -30), Vector3(-90, 0, 0))
			for x: float in [-11.0, 11.0]:
				part(root, cyl(3.5, 3.5, 30), dark, Vector3(x, -1, 4), Vector3(90, 0, 0))
				part(root, sphere(3.2, 8, 4), glow, Vector3(x, -1, 19))
			part(root, box(12.5, 1, 30), glow, Vector3(0, 4.2, 0))
		"miner":
			part(root, box(18, 12, 26), hull, Vector3.ZERO)
			part(root, cyl(2, 7, 14), dark, Vector3(0, -2, -19), Vector3(-90, 0, 0))
			part(root, box(19, 2, 4), glow, Vector3(0, 4, 8))
			part(root, sphere(3, 8, 4), glow, Vector3(0, 0, 14))
		"trader":
			part(root, box(10, 9, 14), hull, Vector3(0, 0, -20))
			for i in 4:
				var c := Color("6c5a3a") if i % 2 == 0 else Color("3d5566")
				part(root, box(16, 12, 8), mat(c), Vector3(0, 0, -8 + i * 9))
			part(root, box(4, 4, 44), dark, Vector3(0, -7, 0))
			part(root, sphere(3.5, 8, 4), glow, Vector3(0, 0, 26))
			part(root, box(10.5, 1, 1), glow, Vector3(0, 4.5, -26))
		"drone":
			part(root, sphere(7, 4, 2), hull, Vector3.ZERO, Vector3(0, 0, 0), Vector3(1, 0.6, 1.5))
			part(root, prism(3, 10, 3), glow, Vector3(7, 0, 2), Vector3(0, 0, -90))
			part(root, prism(3, 10, 3), glow, Vector3(-7, 0, 2), Vector3(0, 0, 90))
			part(root, sphere(2.2, 8, 4), mat(fc, 5.0, true), Vector3(0, 0, -8))
		"ravager":
			part(root, sphere(14, 6, 3), hull, Vector3.ZERO, Vector3.ZERO, Vector3(0.9, 0.5, 2.0))
			for i in 4:
				var a := float(i) * 90.0 + 45.0
				part(root, prism(5, 22, 5), hull, Vector3(cos(deg_to_rad(a)) * 12, sin(deg_to_rad(a)) * 7, 6), Vector3(0, 0, a - 90))
			part(root, sphere(4, 8, 4), mat(fc, 5.0, true), Vector3(0, 0, -26))
			part(root, box(2, 2, 40), glow, Vector3(0, 7, 0))
		"dreadnought":
			part(root, sphere(40, 8, 4), hull, Vector3.ZERO, Vector3.ZERO, Vector3(1, 0.55, 2.2))
			for i in 6:
				var a2 := float(i) * 60.0
				part(root, prism(10, 50, 10), hull, Vector3(cos(deg_to_rad(a2)) * 34, sin(deg_to_rad(a2)) * 20, 20), Vector3(0, 0, a2 - 90))
			part(root, sphere(10, 8, 4), mat(fc, 6.0, true), Vector3(0, 0, -86))
			part(root, torus(36, 40, 24), glow, Vector3(0, 0, 10), Vector3(90, 0, 0))
	return root


# --- Stations -----------------------------------------------------------------------------
static func make_station(kind: String, faction: int) -> Node3D:
	var root := Node3D.new()
	var spin := Node3D.new()
	spin.name = "Spin"
	root.add_child(spin)
	var fc := Defs.faction_color(faction)
	var glow := mat(fc, 2.5, true)
	var hull := mat(HULL_MID)
	var dark := mat(HULL_DARK)
	match kind:
		"solar":
			part(root, cyl(14, 14, 200, 8), hull, Vector3.ZERO)
			for i in 4:
				var a := float(i) * 90.0
				var panel := Node3D.new()
				panel.rotation_degrees = Vector3(0, a, 0)
				spin.add_child(panel)
				part(panel, box(150, 3, 70), mat(Color("1d3a8a"), 0.6), Vector3(100, 40, 0))
				part(panel, box(152, 1, 2), glow, Vector3(100, 42, 0))
			part(root, sphere(20, 10, 5), glow, Vector3(0, 105, 0))
		"refinery":
			part(root, cyl(40, 50, 120, 10), hull, Vector3.ZERO)
			part(root, cyl(18, 18, 220, 8), dark, Vector3(0, 0, 0))
			part(spin, torus(90, 102, 32), hull, Vector3.ZERO)
			part(spin, torus(102, 106, 32), glow, Vector3.ZERO)
			for i in 3:
				part(root, sphere(28, 10, 5), mat(Color("8a5a2a")), Vector3(cos(i * 2.1) * 60, -50, sin(i * 2.1) * 60))
		"factory":
			for i in 5:
				part(root, box(60, 50, 60), hull if i % 2 == 0 else dark, Vector3((i % 3 - 1) * 70, (i / 3) * 55 - 20, (i % 2) * 50 - 25))
			part(root, box(220, 4, 4), glow, Vector3(0, 40, 0))
			part(spin, torus(110, 116, 32), glow, Vector3.ZERO, Vector3(90, 0, 0))
		"trade":
			part(root, sphere(55, 16, 8), hull, Vector3.ZERO)
			part(spin, torus(140, 165, 40), hull, Vector3.ZERO)
			part(spin, torus(165, 170, 40), glow, Vector3.ZERO)
			for i in 4:
				part(spin, box(6, 6, 150), dark, Vector3.ZERO, Vector3(0, i * 45, 0))
			part(root, cyl(8, 8, 260, 8), dark, Vector3.ZERO)
		"shipyard":
			for x: float in [-1.0, 1.0]:
				for y: float in [-1.0, 1.0]:
					part(root, box(8, 8, 320), dark, Vector3(x * 70, y * 50, 0))
			for z in 5:
				part(root, box(150, 6, 6), hull, Vector3(0, 50, -140 + z * 70))
				part(root, box(150, 6, 6), hull, Vector3(0, -50, -140 + z * 70))
			part(spin, torus(170, 180, 40), glow, Vector3.ZERO, Vector3(0, 0, 0))
			part(root, box(60, 30, 80), mat(Color("4a3a2a")), Vector3(0, 0, 40))
		"defense":
			part(root, sphere(45, 8, 4), hull, Vector3.ZERO, Vector3.ZERO, Vector3(1, 0.7, 1))
			for i in 6:
				var a3 := float(i) * 60.0
				var p := Vector3(cos(deg_to_rad(a3)) * 50, 0, sin(deg_to_rad(a3)) * 50)
				part(spin, cyl(5, 5, 50, 6), dark, p, Vector3(90, a3, 0))
			part(spin, torus(58, 62, 24), glow, Vector3.ZERO)
		"hq":
			part(root, cyl(80, 80, 120, 6), hull, Vector3.ZERO)
			part(root, cyl(40, 80, 80, 6), dark, Vector3(0, 100, 0))
			part(root, cyl(80, 40, 80, 6), dark, Vector3(0, -100, 0))
			part(spin, torus(150, 175, 48), hull, Vector3.ZERO)
			part(spin, torus(175, 182, 48), glow, Vector3.ZERO)
			for i in 6:
				part(spin, box(8, 8, 160), dark, Vector3.ZERO, Vector3(0, i * 30, 0))
			part(root, sphere(20, 10, 5), mat(fc, 5.0, true), Vector3(0, 150, 0))
		"nest":
			var body := mat(HIVE_BODY)
			for i in 7:
				var p2 := Vector3(cos(i * 1.7) * 80, sin(i * 2.3) * 60, sin(i * 1.1) * 80)
				part(root, sphere(55 + i * 6, 10, 6), body, p2)
				part(root, sphere(14, 8, 4), mat(fc, 4.0, true), p2 * 1.5)
			part(spin, torus(150, 158, 32), glow, Vector3.ZERO, Vector3(30, 0, 20))
			part(spin, torus(170, 176, 32), glow, Vector3.ZERO, Vector3(-40, 0, 10))
			var shield := part(root, sphere(250, 24, 12), mat(fc, 1.0, true, 0.12), Vector3.ZERO)
			shield.name = "Shield"
	return root


# --- Scenery --------------------------------------------------------------------------------
static func make_gate(to_name: String) -> Node3D:
	var root := Node3D.new()
	var c := Color("8fd8ff")
	part(root, torus(110, 135, 40), mat(HULL_MID), Vector3.ZERO, Vector3(90, 0, 0))
	part(root, torus(104, 110, 40), mat(c, 3.0, true), Vector3.ZERO, Vector3(90, 0, 0))
	var disc := part(root, cyl(104, 104, 1, 32), mat(c, 1.2, true, 0.25), Vector3.ZERO, Vector3(90, 0, 0))
	disc.name = "Disc"
	for i in 4:
		part(root, box(14, 50, 20), mat(HULL_DARK), Vector3(cos(i * PI / 2) * 135, sin(i * PI / 2) * 135, 0), Vector3(0, 0, i * 90))
	root.set_meta("label", to_name)
	return root


static func make_field(radius: float, rng_seed: int) -> MultiMeshInstance3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = sphere(1.0, 7, 4)
	mm.instance_count = 70
	for i in mm.instance_count:
		var p := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.3, 0.3), rng.randf_range(-1, 1)) * radius
		var s := rng.randf_range(6.0, 45.0)
		var b := Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, 0)).scaled(Vector3(s, s * rng.randf_range(0.6, 1.0), s * rng.randf_range(0.7, 1.3)))
		mm.set_instance_transform(i, Transform3D(b, p))
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("5a4c44")
	m.roughness = 1.0
	mmi.material_override = m
	return mmi


static func planet_material(state: String, rng_seed: int) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = PLANET_SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	var a := Color("1f4e7a")
	var b := Color("3f7a3a")
	var veins := Color("e8f0ff")
	match state:
		"hive":
			a = Color("2a1420")
			b = Color("5a2a2a")
			veins = Color("ff3b8d")
		"colony":
			a = Color("2a2a30")
			b = Color("6a4a2a")
			veins = Color("ffb347")
	m.set_shader_parameter("col_a", a)
	m.set_shader_parameter("col_b", b)
	m.set_shader_parameter("veins", veins)
	m.set_shader_parameter("seed", float(rng_seed % 97))
	return m


static func atmosphere_material(col: Color) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = ATMO_SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("col", col)
	return m


static func sky_material(tint: Color) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = SKY_SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("tint", tint)
	return m


const PLANET_SHADER := """
shader_type spatial;
uniform vec4 col_a : source_color;
uniform vec4 col_b : source_color;
uniform vec4 veins : source_color;
uniform float seed = 1.0;
varying vec3 objp;
float h(vec3 p){ return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719)) + seed) * 43758.5453); }
float n3(vec3 p){
	vec3 i = floor(p); vec3 f = fract(p); f = f*f*(3.0-2.0*f);
	return mix(mix(mix(h(i), h(i+vec3(1,0,0)), f.x), mix(h(i+vec3(0,1,0)), h(i+vec3(1,1,0)), f.x), f.y),
		mix(mix(h(i+vec3(0,0,1)), h(i+vec3(1,0,1)), f.x), mix(h(i+vec3(0,1,1)), h(i+vec3(1,1,1)), f.x), f.y), f.z);
}
float fbm(vec3 p){ float v = 0.0; float a = 0.5; for (int i = 0; i < 5; i++){ v += a * n3(p); p *= 2.03; a *= 0.5; } return v; }
void vertex(){ objp = normalize(VERTEX); }
void fragment(){
	float n = fbm(objp * 3.0);
	vec3 c = mix(col_a.rgb, col_b.rgb, smoothstep(0.4, 0.62, n));
	float v = 1.0 - abs(fbm(objp * 6.0 + 7.0) - 0.5) * 2.0;
	float vein = smoothstep(0.93, 0.99, v);
	ALBEDO = c;
	EMISSION = veins.rgb * vein * 1.6;
	ROUGHNESS = 0.9;
}
"""

const ATMO_SHADER := """
shader_type spatial;
render_mode unshaded, blend_add, cull_front;
uniform vec4 col : source_color;
void fragment(){
	float f = 1.0 - abs(dot(NORMAL, VIEW));
	ALBEDO = col.rgb * pow(f, 2.5) * 1.8;
	ALPHA = 1.0;
}
"""

const SKY_SHADER := """
shader_type sky;
uniform vec4 tint : source_color = vec4(0.3, 0.1, 0.5, 1.0);
float h(vec3 p){ return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float n3(vec3 p){
	vec3 i = floor(p); vec3 f = fract(p); f = f*f*(3.0-2.0*f);
	return mix(mix(mix(h(i), h(i+vec3(1,0,0)), f.x), mix(h(i+vec3(0,1,0)), h(i+vec3(1,1,0)), f.x), f.y),
		mix(mix(h(i+vec3(0,0,1)), h(i+vec3(1,0,1)), f.x), mix(h(i+vec3(0,1,1)), h(i+vec3(1,1,1)), f.x), f.y), f.z);
}
void sky(){
	vec3 d = EYEDIR;
	vec3 cell = floor(d * 260.0);
	float s = h(cell);
	vec3 local = fract(d * 260.0) - 0.5;
	float star = step(0.9965, s) * smoothstep(0.35, 0.0, length(local)) * (0.6 + 0.4 * h(cell + 3.0));
	float neb = n3(d * 2.5) * 0.6 + n3(d * 6.0) * 0.4;
	neb = smoothstep(0.45, 0.9, neb);
	vec3 col = vec3(0.004, 0.006, 0.016) + tint.rgb * neb * 0.5 + tint.rgb * 0.04;
	float sd = max(dot(d, LIGHT0_DIRECTION), 0.0);
	col += vec3(1.0, 0.9, 0.75) * (pow(sd, 2000.0) * 6.0 + pow(sd, 60.0) * 0.25);
	col += vec3(star) * mix(vec3(1.0), vec3(0.7, 0.85, 1.0), h(cell + 9.0));
	COLOR = col;
}
"""
