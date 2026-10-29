#!/usr/bin/env bash
# 9-seed balance gate: runs the headless harness for seed offsets 0/3/6 (3 seeds each, 3 Godot
# processes in parallel, ~one device call) and prints per-seed lines plus median and IQR (Q1-Q3).
# Usage: bash scripts/studio/balance_gate.sh <slug> <policy=passive|economic> <minutes> [harness args...]
#   harness args are passed through balance.sh, e.g. --perturb=1 or --nowave (see balance.sh).
# Env:
#   GATE_OFFSETS  seed offsets to run now (default "0 3 6"). If one call would pass the 180 s device
#                 cap, split it:  GATE_OFFSETS="0 3" ... ; then  GATE_OFFSETS="6" ...  (same args).
#                 The second call's summary covers every offset file present for this run tag.
#   GATE_OUT      directory for per-offset raw output (default .tools/balance_gate/<tag>); a run
#                 overwrites only the offsets it runs. GATE_OFFSETS="" just re-summarises.
# Passive gate definition (VS-077, S0071): policy=passive means nobody plays, so run it WITHOUT --reserve (the Fleet
#   Reserve is a player action; --reserve is only for explicit A/B). HEAD 40 min 9 seeds: no-reserve median 28.4,
#   earliest 19.2 (seed 169); with --reserve median 27.6, earliest 22.1. Gate = median 20-35; earliest is watched.
# Summary: hq_lost_at / union_collapse_at of -1 (never happened) count as "> minutes" (sorted last).
# Measured S0010 on Daniel's 2-core device (void-sovereign):
#   economic 30 min, 9 seeds, one call: 154 s.
#   passive 40 min does NOT fit one call (est. ~200 s): GATE_OFFSETS="0 3" (137 s), then GATE_OFFSETS="6" (111 s).
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SLUG="$1"; POLICY="$2"; MIN="$3"; shift 3
EXTRA=("$@")
export GODOT="${GODOT:-$(bash "$ROOT/scripts/studio/ensure_godot.sh" | tail -1)}"
TAG="${SLUG}_${POLICY}_${MIN}$(printf '%s' "${EXTRA[*]:-}" | tr -c 'A-Za-z0-9=' '_' | tr '=' '-')"
OUT="${GATE_OUT:-$ROOT/.tools/balance_gate/$TAG}"
mkdir -p "$OUT"
OFFSETS="${GATE_OFFSETS-0 3 6}"
START=$(date +%s)
for f in $OFFSETS; do
  bash "$ROOT/scripts/studio/balance.sh" "$SLUG" "$MIN" 3 "$POLICY" "$f" "${EXTRA[@]}" > "$OUT/first_$f.txt" &
done
wait
echo "GATE_RUN tag=$TAG offsets=[$OFFSETS] elapsed=$(( $(date +%s) - START ))s out=$OUT"
grep -hE "SCRIPT ERROR|Parse Error|Invalid" "$OUT"/first_*.txt && exit 1
python3 - "$MIN" "$OUT"/first_*.txt <<'PY'
import json, sys
minutes = float(sys.argv[1])
rows = []
for path in sys.argv[2:]:
    for line in open(path):
        if line.startswith("BALANCE_JSON "):
            rows.append(json.loads(line[len("BALANCE_JSON "):]))
rows.sort(key=lambda r: r["seed"])
if not rows:
    print("GATE_SUMMARY no BALANCE_JSON lines"); sys.exit(1)
CENSORED = ("hq_lost_at", "union_collapse_at")
KEYS = ["hq_lost_at", "first_raid_at", "union_collapse_at", "net_worth_10", "net_worth_20",
        "net_worth_30", "hive_ships_20", "union_ships_20", "kills"]
def q(v, p):  # linear interpolation (numpy default); for 9 values Q1/Q3 = 3rd/7th value
    x = (len(v) - 1) * p; lo = int(x); hi = min(lo + 1, len(v) - 1)
    if x == lo: return v[lo]
    if float("inf") in (v[lo], v[hi]): return float("inf")
    return v[lo] + (v[hi] - v[lo]) * (x - lo)
def fmt(k, x):
    if k in CENSORED and x > minutes: return ">%g" % minutes
    return ("%.1f" % x) if k in ("hq_lost_at", "first_raid_at", "union_collapse_at") else "%d" % round(x)
for r in rows:
    print("GATE_SEED seed=%d hq_lost_at=%s nw10=%s nw20=%s nw30=%s" % (r["seed"], r["hq_lost_at"],
          r.get("net_worth_10", "-"), r.get("net_worth_20", "-"), r.get("net_worth_30", "-")))
summary = {"seeds": len(rows), "seed_list": [r["seed"] for r in rows],
           "hq_survived": "%d/%d" % (sum(1 for r in rows if float(r["hq_lost_at"]) < 0), len(rows))}
for k in KEYS:
    v = []
    for r in rows:
        if k in r:
            x = float(r[k])
            v.append(float("inf") if (k in CENSORED and x < 0) else x)
    if not v: continue
    v.sort()
    summary[k] = {"median": fmt(k, q(v, 0.5)), "q1": fmt(k, q(v, 0.25)), "q3": fmt(k, q(v, 0.75))}
print("GATE_SUMMARY " + json.dumps(summary))
PY
