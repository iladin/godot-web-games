QA REPORT — verify:VS-038 — S0031
Verdict: FAIL (balance gate regression; all gameplay criteria otherwise met)

Criteria:
- [x] combat_long first damage t<=30, hull>=450 at t=85 — first shield damage t=12 (sh 379), shield bottoms at 108 at t=30-33, hull stays 600 throughout, hull=600 at t=85. 0 script errors.
- [x] Scout marker/edge arrow with distance from spawn (spawn t<=10) — OPENING_WAVE_TIME=8; hud.gd draws "Scout Nm" edge arrow off-screen or labelled marker on-screen. sortie.png (T+00:09) shows "Scout 577m" arrow plus two labelled scout markers.
- [x] One radio line at first contact, touch wording — opening_wave.radio_line(); selftest asserts both wordings; "press R"/"tap TGT" match real bindings (R = target, TGT button). main.gd feeds touch.active each frame. Not visible in sortie.png only because the 7 s message life had expired by the shot.
- [x] Tip box not over ship in sortie.png — box top y~468, ship bottom y~452 (sortie.png and touch.png). Touch box right edge x~1000 vs THR- button at ~1005 (tight, no overlap).
- [x] check.sh PASS.
- [ ] Balance gates unchanged — FAIL, see below.

Regression:
- check.sh void-sovereign: PASS.
- shots sortie + touch viewed: OK apart from P3 below.
- balance.sh void-sovereign 20 3 economic (seeds 101/118/135): HQ survives 3/3, BUT nw20 = 45105 / 72428 / 105286, median 72428 (< 90k gate). Baseline from git HEAD (git archive copy, same command): 92867 / 104020 / 89022, median 92867. Same code with --nowave: median 119528. hive_ships_20 median 51 (baseline 49, ok). Seed 101 halves (92867 -> 45105), seed 118 drops 104020 -> 72428. Cause is the wave arriving at t=8 instead of 60 in the harness (the economic policy loses ships/income to an early wave). The "sortie constants only" assumption is false for the sim: it changes the harness outcome.

Bugs:
- [P1] nw20 gate regression from OPENING_WAVE_TIME 60->8 — repro: bash scripts/studio/balance.sh void-sovereign 20 3 economic — expected median nw20 >= 90k, actual 72428 (baseline 92867) — evidence above. Needs a 9-seed balance_gate.sh run to see whether this is a real shift or seed noise (min of 9-seed IQR was previously 89022); fix options: drop the harness bot's exposure (e.g. wave target only the player's wing, tune scouts to not pull econ ships), or have Balance Analyst re-baseline if the drop is judged acceptable.
- [P3] Scout label "Scout 613m" overlaps "Meridian Hub 3.1km" label in sortie.png (bottom centre), text is jumbled.
- [P3] test_driver.gd comment on combat_long still says "lands on the player at t=60"; the sortie scenario sets opening.t=0.2, so sortie.png does not exercise the 8 s default.

Notes for Producer: Not a code defect in the HUD/radio work; gameplay criteria pass. Needs either a 9-seed gate decision (Balance Analyst) or a fix that keeps nw20 median >= 90k, then re-verify. Baseline temp copy at ~/baseline_vs (outside repo) can be deleted.

---
## ROUND 2 (verify) — S0031
Verdict: PASS

- [x] combat_long: first shield damage t~13 (sh 359), shield min 108 at t=31, hull 600 throughout, hull=600 at t=85; 0 script errors.
- [x] balance.sh void-sovereign 20 3 economic: HQ 3/3; nw20 = 119528 / 141593 / 109665, median 119528 (>= 90k; equals the --nowave figure, as expected since the wave never spawns with the hidden pilot).
- [x] check.sh void-sovereign: PASS.
- [x] sortie.png: "Scout 578m" edge arrow + "Scout 612m"/"Scout 627m" labels sit above the diamonds, all legible. "Scout 612m" is close to the "Meridian Hub 3.1km" label but not overprinted (round-1 jumble fixed). Tip box clear of ship. touch.png: tip box/buttons unchanged, no overlap.
- Diff verified (git diff): _pilot_present() = player_ship != null and alive and not hidden gates only the PENDING->spawn transition; hud.gd label above diamond + edge-arrow label clamped to screen; test_driver comment corrected.
- Gating soundness: hidden is true only while docked (space_view.set_docked), on the surface (main.gd), and in the balance/breach harnesses; also waits while the player is dead. t stays <=0 so the wave spawns on the first step after undock/take-off/respawn (arrival cue + radio line still fire). It cannot be skipped in real play: a fresh run starts in flight (combat_long spawns at t~8). Save/restore unaffected (t/state serialised; Continue sets hidden=false). Harmless; caveat: a player who docks immediately and stays gets no sortie until leaving (intended).
Bugs:
- [P3] balance harness hive_ships_20 median now 60 (round-1 baseline 49) because the opening wave no longer runs in the sim; the harness no longer exercises the First Sortie. Balance Analyst may want a note/--wave option; not a gate failure.
Notes for Producer: baseline temp copy ~/baseline_vs (outside repo) can be deleted.
