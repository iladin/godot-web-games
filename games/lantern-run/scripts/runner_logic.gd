class_name RunnerLogic
extends RefCounted
## Pure rules and tunables for Lantern Run (no nodes), so selftest can assert on them.

# --- Tunables: physics ---
const GRAVITY := 2600.0
const JUMP_VELOCITY := -980.0
const DOUBLE_JUMP_VELOCITY := -860.0
const JUMP_CUT := 0.45
const MAX_JUMPS := 2
const COYOTE_TIME := 0.08
const JUMP_BUFFER := 0.1
const PLAYER_SCREEN_X := 200.0
const GROUND_Y := 900.0
const CEILING_Y := 360.0
const PLAYER_SIZE := Vector2(34, 56)
# --- Tunables: pace ---
const SPEED_START := 320.0
const SPEED_RAMP := 6.0
const SPEED_MAX := 720.0
# --- Tunables: light ---
const LIGHT_START := 340.0
const LIGHT_MAX := 420.0
const LIGHT_MIN := 60.0
const LIGHT_DRAIN_START := 14.0
const LIGHT_DRAIN_RAMP := 0.25
const LIGHT_DRAIN_MAX := 30.0
const OIL_LIGHT_GAIN := 110.0
const OUT_GRACE := 1.5
const LOW_LIGHT_WARN := 120.0
# --- Tunables: level generation ---
const GAP_START := 620.0
const GAP_RAMP := 4.0
const GAP_MIN := 300.0
const PIT_MIN_EARLY := 120.0
const PIT_MAX_EARLY := 180.0
const PIT_MIN_LATE := 160.0
const PIT_MAX_LATE := 260.0
const LATE_PIT_TIME := 45.0
const SPIKE_TIME := 30.0
const SPIKE_CHANCE := 0.25
const SPIKE_TIP_H := 170.0       # hanging spike tip height above the floor
const STALAG_H_MIN := 40.0
const STALAG_H_MAX := 70.0
const HAZARD_HALF_W := 22.0
const OIL_EVERY_EARLY := 3
const OIL_EVERY_LATE := 5
const OIL_LATE_TIME := 60.0
const EMBER_CHANCE := 0.12
const SAFE_START_PX := 900.0
# --- Tunables: score ---
const PX_PER_POINT := 10.0
const OIL_POINTS := 50
const EMBER_POINTS := 200


static func drain_light(radius: float, rate: float, dt: float) -> float:
	return maxf(LIGHT_MIN, radius - rate * dt)


static func add_oil(radius: float) -> float:
	return minf(LIGHT_MAX, radius + OIL_LIGHT_GAIN)


static func speed_at(t: float) -> float:
	return minf(SPEED_MAX, SPEED_START + SPEED_RAMP * t)


static func drain_rate_at(t: float) -> float:
	return minf(LIGHT_DRAIN_MAX, LIGHT_DRAIN_START + LIGHT_DRAIN_RAMP * t)


static func gap_at(t: float, speed: float) -> float:
	return maxf(maxf(GAP_MIN, GAP_START - GAP_RAMP * t), speed * 0.45)


static func pit_range_at(t: float) -> Vector2:
	if t >= LATE_PIT_TIME:
		return Vector2(PIT_MIN_LATE, PIT_MAX_LATE)
	return Vector2(PIT_MIN_EARLY, PIT_MAX_EARLY)


static func oil_every(t: float) -> int:
	return OIL_EVERY_LATE if t >= OIL_LATE_TIME else OIL_EVERY_EARLY


## ground: Array of Vector2(x_start, x_end) solid segments.
static func is_over_pit(x: float, ground: Array) -> bool:
	for seg: Vector2 in ground:
		if x >= seg.x and x <= seg.y:
			return false
	return true


static func score_for(distance_px: float, oil: int, embers: int) -> int:
	return int(distance_px / PX_PER_POINT) + oil * OIL_POINTS + embers * EMBER_POINTS


## Triangle stalagmite at hx with height h; player centre px, feet at feet_y.
static func hits_stalag(px: float, feet_y: float, hx: float, h: float) -> bool:
	var dx := maxf(0.0, absf(px - hx) - PLAYER_SIZE.x * 0.5)
	if dx >= HAZARD_HALF_W:
		return false
	var tri_h := h * (1.0 - dx / HAZARD_HALF_W)
	return feet_y > GROUND_Y - tri_h


## Inverted triangle spike hanging from the ceiling to tip_y.
static func hits_spike(px: float, feet_y: float, hx: float, tip_y: float) -> bool:
	var dx := maxf(0.0, absf(px - hx) - PLAYER_SIZE.x * 0.5)
	if dx >= HAZARD_HALF_W:
		return false
	var low := CEILING_Y + (tip_y - CEILING_Y) * (1.0 - dx / HAZARD_HALF_W)
	return feet_y - PLAYER_SIZE.y < low
