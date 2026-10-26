# Void Sovereign — Handover
_Last updated: S0010 · 2026-10-26 21:40 UTC · mode: BUILD_

## TL;DR
S0010 shipped two S tasks, both QA PASS on the first round. **VS-021**: balance gates now run 9 seeds with median and IQR (`scripts/studio/balance_gate.sh`), plus `--perturb=N` / `--nowave` A/B switches, with new 9-seed baselines in metrics.csv. **VS-014**: the pause screen handles touch and mouse correctly through the new `scripts/ui/pause_gate.gd`. The game's main open problem is unchanged: late-game decline (VS-020). `check.sh` passes.

## Next session should
1. **Preflight** per `ai-studio/studio-cycle.md`. Request delete permission for the repo root (granted S0001/3/5–10 → git works). Use `git -c core.fileMode=false …` for status/add; commit with `git -c "user.name=Claude Studio" -c user.email=studio@localhost commit -F - <<'EOF2'`.
2. **Build VS-020** (P1 M, late-game Hive pressure); `backlog.py next` returns it. Its acceptance now uses 9-seed gates:
   - Economic: `GODOT=.tools/godot bash scripts/studio/balance_gate.sh void-sovereign economic 30` runs in one call, 154 s.
   - Passive 40 min needs two calls: `GATE_OFFSETS="0 3"` (~137 s), then `GATE_OFFSETS="6"`. See the script header.
   - Baseline: econ nw20 107.7k [103.5–127.0k], nw30 55.9k [39.9–70.2k], HQ 9/9, Hive ships at 20 min 58, Union collapse 27.6.
   - Passive baseline: HQ lost 33.7 [32.1–35.8], survived 2/9.
   - Use `--perturb=1` / `--nowave` A/B runs to check that a gain isn't noise. Respect the notes: no global raid nerf, no shared Defense Platform buff.
3. **Health rule:** builds_since_review = 5. After VS-020, or instead of it if the session is short, the next session must run a **PLANNING** round, since the last one was S0007. The critic flagged economy legibility (credit ledger, parking lot) as the top candidate.
4. **P2 S queue:**
   - VS-005: surface marker declutter.
   - VS-010: traders stuck at a player station.
   - VS-007: wing commands.
   - VS-009 is L, so split it before building. VS-006 is blocked until VS-020.
5. **Cheap P3s in the parking lot from S0010 QA:**
   - selftest assert that PauseGate is main's child 0.
   - Mouse wheel resumes from pause.
   - Game-over on the surface needs two clicks.
   - balance_gate stale offset files.
   - Quote the S0003 metrics.csv row.

## Last session
- Did:
  - **VS-021 done.**
    - `games/void-sovereign/scripts/tools/balance.gd`: `--perturb=N` (draws N extra global randf() after t=60 s) and `--nowave`. With no new args the output is byte-identical (QA ran the HEAD harness side by side).
    - `scripts/studio/balance.sh` passes any args after the 5th through to the harness.
    - New `scripts/studio/balance_gate.sh <slug> <policy> <minutes> [args]`: offsets 0/3/6 run in parallel; output goes to `.tools/balance_gate/<tag>/`, with GATE_SEED and GATE_SUMMARY lines.
    - `ai-studio/roles/balance-analyst.md` now uses the 9-seed gates.
    - Two metrics.csv rows added.
  - **VS-014 done.**
    - New PauseGate, main's first child, handles input while paused:
      - It swallows pointer events, and emulated touch clicks never resume.
      - SND/N still mute while paused. MAP, TRVL, dock and map buttons do nothing.
      - One real click, an off-button tap, or a key resumes. The resume click doesn't capture or fire.
    - Also changed: `run_flow.pause()` delegates to it; `controls.resumes_from_pause` and the `touch_controls` paused flag; 2 selftest asserts; DESIGN.md pause paragraph.
    - QA's own probe covered flight, surface, map and dock. The same probe on HEAD fails 20 checks.
- Check: PASS · Git: cbb8fdf (VS-021), e6126dd (VS-014), + wrap-up commit (HANDOVER/LOG/state) · Roles collapsed: none

## In-flight / uncommitted work
None from this session. Left uncommitted on purpose: Windows mount file-mode noise and Daniel's edits outside this game. Scratch (gitignored `.tools/`):
- `.tools/s0010/` (dev balance A/B)
- `.tools/s0010_dev/` (pause_probe.gd, plus `base/`, a HEAD copy of the game used as a control; can be removed)
- `.tools/s0010_qa/` and `.tools/s0010_qa2/` (qa_probe.gd, over_probe.gd, pause screenshots)
- `.tools/balance_gate/` (gate outputs)

## Build health
- check.sh: PASS (~20 s). The selftest now also checks real vs emulated click resume.
- Known noise, not bugs: "ObjectDB instances leaked" / "resources still in use at exit"; ALSA errors under xvfb.
- Latest metrics: S0010 9-seed econ30 nw20 107685 / nw30 55869 / HQ 9/9; passive40 HQ lost 33.7 [32.1–35.8], 2/9 survive.

## Backlog snapshot
todo 5 · in-progress 0 · done 13 · blocked 1 · split 2 · ready 4 · Top ready: VS-020 late-game Hive pressure (P1 M), VS-005 surface marker declutter (P2 S), VS-010 traders stuck at player station (P2 S)

## Watch out for
- **Sim chaos:** the global `randf()` is seeded at universe.gd:30 and used by director, ShipData.setup and retarget. Judge balance only on 9-seed medians and IQR, and use `--perturb` / `--nowave` controls.
- **Gate timing:** the device has 2 cores. The econ 30-min gate takes 154 s of the 180 s cap, so if the sim gets heavier, split it with `GATE_OFFSETS`.
- **Stale gate files:** a gate tag doesn't include the game version. After a code change, clear `.tools/balance_gate/<tag>/` or set a fresh `GATE_OUT` before a split run.
- **GATE_SUMMARY medians** can be strings like ">40" (not lost). In passive runs nw30 counts as 0 when the HQ fell.
- **Passive gate is near its ceiling** (median 33.7 vs 35). Any added defence must be player-only.
- **PauseGate must stay main's first child** (`_input` order: TouchControls → PauseGate → GUI). Don't add scene children to main.tscn or add_child before it.
- After a resume click the mouse stays free; the next click captures it. This is intentional.
- **Sortie scouts** (VS-018) target only the player wing for 240 s, then become normal drones.
- **Code size:** main.gd is 306 lines; split it before adding more. universe.gd is 454 lines.
- **Conventions:** every sound goes through `Sfx.play()`. The default font has no arrow glyphs.

## Open questions for Daniel
- VS-020: if no clean lever is found, is a mild late decline acceptable (e.g. nw30 ≥ 0.7 × nw20 with HQ ≥ 7/9) instead of strict growth?
- Still open: remember tutorial tips in the save file? Target session length (design assumes 30–40 min)?

## Answers to Daniel
- None new (INBOX was empty). Earlier rulings still apply: a slower early game after VS-016 is fine; VS-007/VS-009 were restored to todo; the studio never pushes unless asked. The S0009 question about switching to 9-seed gates was resolved by the Producer in VS-021 (gates cost ~2–4 extra minutes per balance run). Veto via INBOX if you disagree.

## Session history (newest first, keep 10)
- S0010 2026-10-26 BUILD — VS-021 9-seed balance gates + A/B switches done; VS-014 pause-screen touch/mouse done (both QA PASS first round)
- S0009 2026-10-26 BUILD — VS-018 First Sortie done (QA FAIL → fix round → PASS); VS-021 added (sim chaos makes 3-seed gates unreliable)
- S0008 2026-10-26 BUILD — VS-011 split → VS-019 harness done (HQ 6/6, nw30 74k) + VS-020 open; VS-017 tutorial tips follow the world done (QA PASS after 1 fix round)
- S0007 2026-10-26 PLANNING+BUILD — first review round (critic 5.1/10) → VS-015..018; VS-015 title freeze/overlay fix + VS-016 trade arbitrage fix done (both QA PASS)
- S0006 2026-10-26 BUILD — VS-004 tutorial tips + VS-012 touch row/pause-mute/sfx assert done (both QA PASS); VS-013, VS-014 added
- S0005 2026-10-26 BUILD — took over stale S0004 lock; VS-003 procedural SFX done (QA PASS); VS-012 added
- S0004 2026-10-26 SUPERSEDED — took lock 03:32Z, device calls stalled ~8 h; resumed later as S0006
- S0003 2026-10-26 BUILD — cleaned up hung S0002; VS-001 mid-game rebalance done (nw20 8k→139k, HQ 5/6); VS-011 added
- S0002 2026-10-26 ABORTED — hung during VS-001, cancelled by Daniel; diff salvaged, no handover
- S0001 2026-10-26 BUILD — baseline commit; VS-002 trader reserve + VS-008 AI-journey selftest done; VS-010 added
