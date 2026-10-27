class_name Defs
extends RefCounted
## Static game data: factions, wares, ship classes, station types, galaxy layout.
## Every balance number lives here so it can be tuned in one place.

enum Faction { PLAYER, UNION, HIVE }

const FACTION_COLORS: Array[Color] = [Color("ffb347"), Color("5ee6ff"), Color("ff3b8d")]
const FACTION_NAMES: Array[String] = ["Sovereign", "Union", "Hive"]

# --- Economy -----------------------------------------------------------------
const WARES: Array[String] = ["ore", "energy", "alloy", "munitions"]
const WARE_NAMES: Dictionary = {"ore": "Ore", "energy": "Energy", "alloy": "Alloy", "munitions": "Munitions"}
const BASE_PRICE: Dictionary = {"ore": 16.0, "energy": 12.0, "alloy": 80.0, "munitions": 170.0}
const PRICE_HIGH := 1.4          # price multiplier when a station's stock is empty
const PRICE_LOW := 0.6           # ... and when full
const CYCLE_TIME := 10.0         # seconds per production cycle
const STATION_CAPACITY := 300    # per ware
const TRADE_HUB_CAPACITY := 600
# Trade Hubs export to the wider galaxy: every production cycle a hub ships out up to
# TRADE_HUB_EXPORT units of each ware it holds above TRADE_HUB_TARGET_FILL. Without this sink
# hubs fill up, prices bottom out and miner/trader income stalls by minute ~5.
const TRADE_HUB_EXPORT := 80
const TRADE_HUB_TARGET_FILL := 0.1
# Traders and miners plan routes only through sectors with fewer than this many Hive warships
# (Nest sectors are always avoided), so they stop feeding themselves to infested sectors.
const CIVILIAN_AVOID_HIVE := 2
# Sovereign warships patrolling the HQ sector only chase targets this far beyond HQ gun range.
const GUARD_LEASH := 400.0
# Credits per unit a hauler (miner or freighter selling cargo) demands before selling in another
# sector instead of its own; keeps miners near home instead of drifting into raid lanes. Was 2.5.
const CROSS_SECTOR_SELL_PENALTY := 6.0
# HQ dock crews: automated Sovereign ships within REPAIR_RANGE of the HQ that haven't been hit
# for SHIELD_DELAY patch REPAIR_RATE of max hull per second (free).
const REPAIR_RANGE := 2000.0
const REPAIR_RATE := 0.02
# Starting stock as a fraction of capacity. Outputs start fuller than inputs so producer ->
# consumer runs are profitable on minute one (price falls as fill rises).
const START_FILL_INPUT := 1.0 / 3.0
const START_FILL_OUTPUT := 0.5
const START_CREDITS := 30000.0
const TRADER_RESERVE := 2000.0  # player-owned auto ships/stations never spend credits below this
const COLONY_INCOME := 450.0     # credits per minute per colony
const BOUNTY: Dictionary = {"drone": 150.0, "ravager": 600.0, "dreadnought": 4000.0}
const RESPAWN_PENALTY := 0.25    # fraction of credits lost when your ship dies

# --- Combat --------------------------------------------------------------------
const SENSOR_RANGE := 2400.0
const RETARGET_TIME := 0.5
const SHOT_INTERVAL := 0.45
const SHIELD_DELAY := 4.0        # seconds without damage before shields recharge
const SHIELD_REGEN := 0.08       # fraction of max per second
const DOCK_DIST := 320.0
const GATE_DIST := 150.0
const SECTOR_RADIUS := 3600.0    # where gates sit
const PLANET_DIST := 5600.0
const PLANET_RADIUS := 1500.0
const LAND_MARGIN := 650.0

# --- Ships ---------------------------------------------------------------------
# role: player | combat | miner | trader
const SHIP: Dictionary = {
	"interceptor": {"name": "Interceptor", "role": "player", "hull": 600.0, "shield": 400.0, "speed": 280.0, "dps": 0.0, "range": 0.0, "cargo": 40, "cost": 0, "radius": 16.0},
	"fighter": {"name": "Fighter", "role": "combat", "hull": 320.0, "shield": 180.0, "speed": 230.0, "dps": 36.0, "range": 950.0, "cargo": 0, "cost": 4500, "radius": 14.0},
	"corvette": {"name": "Corvette", "role": "combat", "hull": 700.0, "shield": 350.0, "speed": 150.0, "dps": 70.0, "range": 1300.0, "cargo": 0, "cost": 16000, "radius": 30.0},
	"miner": {"name": "Miner", "role": "miner", "hull": 300.0, "shield": 80.0, "speed": 140.0, "dps": 0.0, "range": 0.0, "cargo": 80, "cost": 6000, "radius": 22.0},
	"trader": {"name": "Freighter", "role": "trader", "hull": 300.0, "shield": 120.0, "speed": 150.0, "dps": 0.0, "range": 0.0, "cargo": 80, "cost": 7000, "radius": 24.0},
	"drone": {"name": "Hive Drone", "role": "combat", "hull": 90.0, "shield": 0.0, "speed": 250.0, "dps": 16.0, "range": 850.0, "cargo": 0, "cost": 0, "radius": 11.0},
	"ravager": {"name": "Ravager", "role": "combat", "hull": 480.0, "shield": 160.0, "speed": 165.0, "dps": 52.0, "range": 1150.0, "cargo": 0, "cost": 0, "radius": 26.0},
	"dreadnought": {"name": "Dreadnought", "role": "combat", "hull": 3200.0, "shield": 1200.0, "speed": 90.0, "dps": 170.0, "range": 1600.0, "cargo": 0, "cost": 0, "radius": 70.0},
}
const PLAYER_BUYABLE: Array[String] = ["fighter", "corvette", "miner", "trader"]

# --- Stations -------------------------------------------------------------------
const STATION: Dictionary = {
	"solar": {"name": "Solar Array", "hull": 4000.0, "shield": 1500.0, "in": {}, "out": {"energy": 20}, "cost": 28000, "dps": 0.0, "range": 0.0, "radius": 130.0},
	"refinery": {"name": "Refinery", "hull": 5000.0, "shield": 1500.0, "in": {"ore": 8, "energy": 4}, "out": {"alloy": 3}, "cost": 42000, "dps": 0.0, "range": 0.0, "radius": 140.0},
	"factory": {"name": "Munitions Factory", "hull": 5000.0, "shield": 1500.0, "in": {"alloy": 3, "energy": 6}, "out": {"munitions": 2}, "cost": 52000, "dps": 0.0, "range": 0.0, "radius": 140.0},
	"trade": {"name": "Trade Hub", "hull": 7000.0, "shield": 2500.0, "in": {}, "out": {}, "cost": 0, "dps": 30.0, "range": 1300.0, "radius": 170.0},
	"shipyard": {"name": "Shipyard", "hull": 9000.0, "shield": 3000.0, "in": {"alloy": 4, "munitions": 2}, "out": {}, "cost": 0, "dps": 50.0, "range": 1500.0, "radius": 190.0},
	"defense": {"name": "Defense Platform", "hull": 4500.0, "shield": 2500.0, "in": {}, "out": {}, "cost": 30000, "dps": 95.0, "range": 1700.0, "radius": 90.0},
	"hq": {"name": "Sovereign HQ", "hull": 30000.0, "shield": 6000.0, "in": {}, "out": {}, "cost": 0, "dps": 70.0, "range": 1600.0, "radius": 200.0},
	"nest": {"name": "Hive Nest", "hull": 9000.0, "shield": 5000.0, "in": {}, "out": {}, "cost": 0, "dps": 75.0, "range": 1700.0, "radius": 200.0},
}
const PLAYER_BUILDABLE: Array[String] = ["solar", "refinery", "factory", "defense"]

# --- Galaxy ----------------------------------------------------------------------
# planet: "union" (peaceful, no landing), "hive" (ground Core; level 1-3)
const SECTORS: Array[Dictionary] = [
	{"name": "Haven's Reach", "map": Vector2(0.18, 0.55), "planet": "hive", "level": 1, "planet_name": "Ember", "fields": 1,
		"stations": [["hq", 0], ["solar", 1], ["trade", 1]]},
	{"name": "Argent Fields", "map": Vector2(0.36, 0.30), "planet": "union", "level": 0, "planet_name": "Argentum", "fields": 3,
		"stations": [["refinery", 1], ["solar", 1], ["solar", 1]]},
	{"name": "Meridian Hub", "map": Vector2(0.38, 0.76), "planet": "union", "level": 0, "planet_name": "Meridian", "fields": 1,
		"stations": [["shipyard", 1], ["trade", 1], ["factory", 1], ["defense", 1]]},
	{"name": "Cinder Belt", "map": Vector2(0.58, 0.40), "planet": "hive", "level": 2, "planet_name": "Cinder", "fields": 4,
		"stations": [["refinery", 1], ["solar", 1]]},
	{"name": "Hollow Verge", "map": Vector2(0.80, 0.24), "planet": "hive", "level": 2, "planet_name": "Hollow", "fields": 2,
		"stations": [["nest", 2]]},
	{"name": "Black Choir", "map": Vector2(0.84, 0.70), "planet": "hive", "level": 3, "planet_name": "Choir", "fields": 1,
		"stations": [["nest", 2]]},
	{"name": "Ashfall Gate", "map": Vector2(0.62, 0.78), "planet": "hive", "level": 2, "planet_name": "Ashfall", "fields": 2,
		"stations": [["factory", 1], ["defense", 1], ["solar", 1]]},
]
const LINKS: Array[Vector2i] = [Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 3), Vector2i(2, 6), Vector2i(3, 4), Vector2i(3, 6), Vector2i(6, 5), Vector2i(4, 5)]

# --- Hive director ramp ------------------------------------------------------------
const FIRST_RAID := 200.0
const RAID_INTERVAL_START := 180.0
const RAID_INTERVAL_MIN := 75.0
# Raid size = RAID_SIZE_START + t / RAID_SIZE_GROWTH ships, capped at RAID_SIZE_MAX.
const RAID_SIZE_START := 3
const RAID_SIZE_GROWTH := 90.0
const RAID_SIZE_MAX := 16
# VS-020: from RAID_DETER_FROM on, each player Defense Platform in a raid target's sector multiplies the chance the raid
# goes ahead (otherwise it is called off; the timer still resets). Union targets unaffected.
const RAID_DETER_PER_PLATFORM := 0.25
# VS-023: only platforms within RAID_DETER_RANGE (2x platform gun range) of the raid target count.
const RAID_DETER_RANGE := 3400.0
# VS-025: raid reporting. The tracker polls every RAID_TRACK_INTERVAL s; "turned back" is announced at most once per
# RAID_TURNED_BACK_THROTTLE s (later ones are counted into the next message); RAID_HOP_ETA = rough seconds per gate hop.
const RAID_TRACK_INTERVAL := 0.5
const RAID_TURNED_BACK_THROTTLE := 300.0
const RAID_HOP_ETA := 40.0
const RAID_DETER_FROM := 1200.0   # s; before this the Hive raids regardless (early game unchanged)
const RAVAGER_TIME := 300.0
const DREAD_TIME := 1200.0
const NEST_SPAWN_START := 30.0
const NEST_SPAWN_MIN := 12.0
# First Sortie (VS-018, opening_wave.gd): once per run, OPENING_WAVE_TIME s of play in,
# OPENING_WAVE_SIZE scouts appear OPENING_WAVE_RANGE ahead of the player (leaning toward Ember's
# orbit, OPENING_WAVE_ORBIT above its surface) and hunt the player's wing. Stations and Union ships
# ignore them for OPENING_WAVE_LINGER s, so the fight is the player's. Hull/dps scale a drone.
# Not a raid: the raid timer (FIRST_RAID) is unaffected.
const OPENING_WAVE_TIME := 60.0
const OPENING_WAVE_SIZE := 3
const OPENING_WAVE_HULL := 3.0
const OPENING_WAVE_DPS := 0.5
const OPENING_WAVE_ORBIT := 700.0
const OPENING_WAVE_RANGE := 1300.0
const OPENING_WAVE_LINGER := 240.0

# --- Union upkeep --------------------------------------------------------------------
const UNION_QUOTA: Dictionary = {"fighter": 10, "trader": 8, "miner": 6}
const UNION_SPAWN_TIME := 40.0
const UNION_REBUILD_TIME := 240.0


static func ship_f(cls: String, key: String) -> float:
	return float(SHIP[cls][key])


static func station_f(kind: String, key: String) -> float:
	return float(STATION[kind][key])


static func faction_color(f: int) -> Color:
	return FACTION_COLORS[f]


static func hostile(a: int, b: int) -> bool:
	return a != b and (a == Faction.HIVE or b == Faction.HIVE)
