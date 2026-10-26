# Void Sovereign — Handover
_Last updated: S0007 · 2026-10-26 13:33 UTC · mode: PLANNING + BUILD_

## TL;DR
S0007 ran the first full review round (Critic avg 5.1/10; lowest pillars: Economy legibility 3, FPS 4, Pacing 4) and turned it into four new tasks, then shipped two P1 bug fixes from the QA sweep. **VS-015**: the world no longer runs behind the title screen, and ending a run with the map/dock open no longer eats clicks. **VS-016**: no more infinite credits from buy/sell at one Trade Hub. `check.sh` passes. Next up: the tutorial stalls at tip 3 (VS-017), and the late-game slide (VS-011) is still open — now with a lower income baseline after VS-016.

## Next session should
1. **Preflight** per `ai-studio/studio-cycle.md`. Request delete permission for the repo root (granted S0001/3/5/6/7 → git works). Use `git -c core.fileMode=false …` for status/add; commit with `git -c "user.name=Claude Studio" -c user.email=studio@localhost commit -F - <<'EOF'` (inline, not via a shell variable).
2. **BUILD `VS-017`** (P1 S, tutorial tips follow the world; absorbs VS-013). `backlog.py next` may return VS-011 first (P1 balance, older) — if so, prefer VS-017 only if you justify it in LOG; otherwise do VS-011. Key evidence: tip 3 "lock onto a Hive ship" is uncompletable at home (0 Hive ships in Haven's Reach for 10 min in seeds 7/101/118), so tips 4–6 never show — see `studio/reviews/S0007-critic.md` #1/#3 and `S0007-qa.md` bug 4. File: `games/void-sovereign/scripts/ui/tutorial_hints.gd`.
3. **VS-011** (P1 M): first add the seed-offset option to `scripts/studio/balance.sh` / `scripts/tools/balance.gd` (a working prototype is `.tools/s0007/balance_offset.gd`, adds `--first=`). Then re-baseline 6 seeds (two 3-seed calls ≈90 s each) — VS-016 lowered income (credits_10 17k/21k/10k, nw20 median 129k on seeds 101/118/135). Balance analyst's suggested levers: `RAID_INTERVAL_MIN` 75→100, `RAID_SIZE_MAX` 16→13 in `scripts/sim/defs.gd`; the harness's economic policy should replace lost fighters / build a Defense Platform after minute 10. Probably no longer need TRADE_HUB_EXPORT trimming — measure first.
4. **VS-018** First Sortie (P1 M): a one-time 3-drone wave near Ember at ~60 s. VS-015 is done, so title time no longer counts. Ideally after VS-017 so the target tip can point at the wave.
5. Then P2s: VS-014 (pause-screen input; also dock/map buttons stay clickable under the pause overlay), VS-005, VS-010. VS-006 is blocked until VS-011 lands (re-measure Hive count).

## Last session
- Did:
  - **PLANNING** (health rule, builds_since_review was 6). Reports in `games/void-sovereign/studio/reviews/S0007-{critic,qa,balance,scout}.md`; metrics row appended (sim unchanged since S0003: econ 6 seeds nw20 139k, nw30 median 42.9k — falls in 5/6 seeds).
  - New tasks: VS-015, VS-016, VS-017 (absorbs VS-013 → `split`), VS-018. VS-006 → blocked on VS-011; VS-007 and VS-009 → blocked ("parked by Producer", ≤8 todo cap — Daniel can revive via INBOX). ~10 parking-lot items added (credit ledger cr/min, honest raid reports, HQ "keep N fighters" order, station-in-planet, dock batch-price readout, trade-hub dock shot…).
  - **VS-015 done** (commit d16b60d): new `scripts/run_flow.gd` (class RunFlow: start/finish/close_overlays/pause/save, `sim_runs(state)` = PLAYING only). main.gd 329→306 lines. Title shows no HUD/prompts; finish closes map/dock; land/dock guards (no surface after a run ends mid-fade). Autoplay idles 10 title frames and asserts u.time == 0; `--shot=title` is now the real title; new `over_map` shot. QA PASS with 2 mutations.
  - **VS-016 done**: `StationData.price_at` / `batch_total` price each unit along the stock curve; `Universe.transact` charges it (automated player trades shrink qty to fit budget/reserve). Selftest `_check_no_round_trip_profit` (every station × ware × N∈{1,10,40} × 4 stock levels). QA PASS with 2 mutations, real dock-button probe, reserve clamp re-checked.
- Check: PASS · Git: committed `studio(S0007)` review round (3fd3d72), VS-015 (d16b60d), VS-016 + wrap-up · Roles collapsed: none

## In-flight / uncommitted work
none. Left uncommitted on purpose: Windows mount noise (nearly every file shows modified with 0-line diffs, incl. template/.github/starfall) and Daniel's edits outside this game. Probes outside the repo: `$HOME/probe/` (QA p1–p9, q1, qa16*), `$HOME/critic/`; balance raw output in `.tools/s0007/`.

## Build health
- check.sh: PASS (~17 s). Selftest adds "run flow: sim gating OK" and the VS-016 round-trip check; autoplay prints "title: 10 frames, u.time 0.0 — world frozen".
- Known noise (not bugs): "ObjectDB instances leaked" / "resources still in use at exit"; ALSA errors under xvfb.
- Latest metrics: S0007 economic 30 min 6 seeds (pre-VS-016): HQ 5/6, nw10 101k, nw20 139k, nw30 median 42.9k, hive_20 59 (max 65). Post-VS-016 (3 seeds, not in metrics.csv): credits_10 17.4k/21.2k/10.3k, nw20 129k, HQ 2/3.

## Backlog snapshot
todo 8 · in-progress 0 · done 8 · blocked 1 · split 1 · ready 7 · Top ready: VS-011 grow from minute 20 to 30, VS-017 tips follow the world, VS-018 First Sortie

## Watch out for
- **Run flow**: the Universe steps only while PLAYING (`RunFlow.sim_runs`). `_on_finished` / `RunFlow.finish()` are ignored unless PLAYING. The title backdrop is now a still scene. `_set_mode` keeps HUD/touch at "none" when not PLAYING.
- **Trade pricing**: batches are priced per unit along the curve; the dock still shows the next-unit (spot) price, so Buy 10 costs slightly more than 10× shown. ShipAI.plan_trade still estimates with spot prices.
- Shot/autoplay runs share `user://save.cfg` best score with real play (win shot sets best 170997).
- Tutorial tips: box rect depends on viewport; touch probes need xvfb `--resolution 1280x720`. TutorialHints `_input` runs before TouchControls (steals steer drags). `emulate_mouse_from_touch=true` → every tap is also a mouse click (VS-014).
- `check.sh` fails on "SCRIPT ERROR" only; a failed selftest assert still prints "SELFTEST OK" — read the whole output. Use ≥ 6 seeds for survival gates; balance runs > 3 seeds exceed the 180 s device cap without seed offsets.
- Every sound goes through `Sfx.play()`. Only one WorldEnvironment at a time. Default font has no arrow glyphs. main.gd is 306 lines — split further before adding to it.
- Git needs delete permission (lock files). Never stage template/.github/starfall/.claude mode noise.

## Open questions for Daniel
- Still open: should tutorial tips be remembered in the save file? Target session length (design assumes 30–40 min)?

## Answers to Daniel
- (from Daniel, after S0007) A slower early game after VS-016 is fine. VS-011 should not try to restore early income; aim its nw20 band at the new baseline.
- (from Daniel) VS-007 (wing commands) and VS-009 (save and continue) are back to `todo`. That makes 8 open todo tasks; Daniel's call overrides the cap. VS-009 is size L, so split it into S/M tasks before anyone builds it (`backlog.py next` skips L).
- (from Daniel) The repo is now pushed to GitHub (`origin` = https://github.com/iladin/godot-web-games, branch `main`). Studio sessions still never push on their own unless Daniel asks.

## Session history (newest first, keep 10)
- S0007 2026-10-26 PLANNING+BUILD — first review round (critic 5.1/10) → VS-015..018; VS-015 title freeze/overlay fix + VS-016 trade arbitrage fix done (both QA PASS)
- S0006 2026-10-26 BUILD — VS-004 tutorial tips + VS-012 touch row/pause-mute/sfx assert done (both QA PASS); VS-013, VS-014 added
- S0005 2026-10-26 BUILD — took over stale S0004 lock; VS-003 procedural SFX done (QA PASS); VS-012 added
- S0004 2026-10-26 SUPERSEDED — took lock 03:32Z, device calls stalled ~8 h; resumed later as S0006
- S0003 2026-10-26 BUILD — cleaned up hung S0002; VS-001 mid-game rebalance done (nw20 8k→139k, HQ 5/6); VS-011 added
- S0002 2026-10-26 ABORTED — hung during VS-001, cancelled by Daniel; diff salvaged, no handover
- S0001 2026-10-26 BUILD — baseline commit; VS-002 trader reserve + VS-008 AI-journey selftest done; VS-010 added
- S0000 2026-10-25 SETUP — game v1 + AI studio + seeded backlog
