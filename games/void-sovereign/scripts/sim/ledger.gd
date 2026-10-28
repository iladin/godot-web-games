class_name CreditLedger
extends RefCounted
## VS-024: categorised record of every change to the player's credits. Universe.add_credits()
## is its only writer. Pure observer: it never reads the RNG or alters the simulation.

const BUCKET := 5.0               # seconds per history bucket
const RATE_WINDOW := 60.0         # HUD cr/min: gross income over the last minute
const BREAKDOWN_WINDOW := 300.0   # map / dock "last 5 min" breakdown
const MIN_RATE_SPAN := 15.0       # early in a run, average over at least this many seconds
const CATEGORIES: Array[String] = ["trade", "freight", "mining", "stations", "colonies", "bounty", "intercept",
	"ships", "build", "repair", "losses", "reserve"]
const LABELS: Dictionary = {
	"trade": "Trading (you)", "freight": "Freighters", "mining": "Mining", "stations": "Your stations",
	"colonies": "Colonies", "bounty": "Bounties", "intercept": "Raid intercepts", "ships": "Ships bought", "build": "Construction",
	"repair": "Repairs", "losses": "Ship losses", "reserve": "Reserve call",
}

var totals: Dictionary = {}           # category -> net credits since the run started
var _buckets: Array[Dictionary] = []  # oldest first: {"i": bucket index, "net": {cat: cr}, "gain": cr}


func record(now: float, amount: float, cat: String) -> void:
	assert(LABELS.has(cat), "unknown credit category '%s'" % cat)
	if amount == 0.0:
		return
	totals[cat] = float(totals.get(cat, 0.0)) + amount
	var i := int(floor(now / BUCKET))
	if _buckets.is_empty() or int(_buckets[-1]["i"]) != i:
		_buckets.append({"i": i, "net": {}, "gain": 0.0})
		var oldest := i - int(ceil(BREAKDOWN_WINDOW / BUCKET))
		while int(_buckets[0]["i"]) < oldest:
			_buckets.pop_front()
	var b: Dictionary = _buckets[-1]
	var net: Dictionary = b["net"]
	net[cat] = float(net.get(cat, 0.0)) + amount
	if amount > 0.0:
		b["gain"] = float(b["gain"]) + amount


## Sum of every category since the run started (equals credits - starting credits).
func total() -> float:
	var s := 0.0
	for c: String in totals:
		s += float(totals[c])
	return s


## Gross income (earnings only, spending ignored) per minute over the last RATE_WINDOW seconds.
func income_per_min(now: float) -> float:
	var first := int(floor((now - RATE_WINDOW) / BUCKET)) + 1
	var gain := 0.0
	for b: Dictionary in _buckets:
		if int(b["i"]) >= first:
			gain += float(b["gain"])
	var span := clampf(now - maxf(float(first) * BUCKET, 0.0), MIN_RATE_SPAN, RATE_WINDOW)
	return gain / span * 60.0


## Net income (earnings minus spending) per minute over the same window; gross >= net always.
func net_per_min(now: float) -> float:
	var first := int(floor((now - RATE_WINDOW) / BUCKET)) + 1
	var net := 0.0
	for b: Dictionary in _buckets:
		if int(b["i"]) >= first:
			for c: String in b["net"]:
				net += float(b["net"][c])
	var span := clampf(now - maxf(float(first) * BUCKET, 0.0), MIN_RATE_SPAN, RATE_WINDOW)
	return net / span * 60.0


## Net credits per category over the last `window` seconds, largest magnitude first.
## Returns [[category, amount], ...]; categories that rounded to zero are left out.
func breakdown(now: float, window: float = BREAKDOWN_WINDOW) -> Array:
	var first := int(floor((now - window) / BUCKET)) + 1
	var sums: Dictionary = {}
	for b: Dictionary in _buckets:
		if int(b["i"]) < first:
			continue
		var net: Dictionary = b["net"]
		for c: String in net:
			sums[c] = float(sums.get(c, 0.0)) + float(net[c])
	var out: Array = []
	for c: String in CATEGORIES:
		if absf(float(sums.get(c, 0.0))) >= 1.0:
			out.append([c, float(sums[c])])
	out.sort_custom(func(a: Array, b: Array) -> bool: return absf(float(a[1])) > absf(float(b[1])))
	return out
