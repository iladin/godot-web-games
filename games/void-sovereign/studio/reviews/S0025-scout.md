# S0025 Feature Scout (void-sovereign)

Inputs: S0025 critic, QA, balance; BACKLOG (VS-029 blocked, VS-030/031/032 todo, parking lot); DESIGN Out of scope (save-anywhere, no on-foot saves). Nothing below changes Out of scope. VS-030, VS-031 and VS-032 are already queued and are not re-proposed; proposals 4 and 5 cover only what those tasks leave out.

### Atomic run save and honest save failures
- Answers: QA S0025 P2 (RunSave.write truncates then writes; write() result ignored)
- Pillar: Web/touch fitness
- Pitch: A crash, tab close or full browser storage mid-autosave never costs the player their run. If a save fails, a short HUD line says so, and Continue always points at the last good save.
- Reference: standard temp-file-plus-rename saves (Everspace, Starsector keep a backup slot).
- Size: S   Type: tech
- Acceptance criteria:
  - [ ] RunSave.write writes `run.save.tmp`, verifies it parses, then renames it over `run.save`; the previous good file is kept as `.bak`
  - [ ] load_universe falls back to `.bak` when the main file is truncated or invalid
  - [ ] Selftest: a truncated main file still leaves Continue enabled via `.bak`; a corrupt tmp never replaces a good save
  - [ ] A failed autosave shows one throttled HUD message (no spam); check.sh PASS
- Risks: Web export rename/IDBFS flush behaviour is unverified, so needs a real-browser pass. No on-foot saving is added.
- Why now: Save work is complete (VS-026/027/028) and the file I/O is the weak point, so fix it before anything builds on it.

### Close VS-029: Breach retune and a clean passive baseline
- Answers: Balance S0025 rec 1 (passive HQ-lost 36.0 min vs 20-35; Hive ships @20 econ 61 vs 60); critic problem 3; unblocks VS-029
- Pillar: Pacing & difficulty
- Pitch: The Breach should make a do-nothing player bleed sooner without punishing an active one. Tune its size and timing so passive play loses the HQ inside the target window.
- Reference: Starsector and X4 scale early pressure by how exposed you are. Keep one scripted spike and tune it, not the Hive ramp.
- Size: S   Type: balance
- Acceptance criteria:
  - [ ] Try BREACH_SIZE 4 -> 6 and/or BREACH_TIME 360 -> 300 in defs.gd; leave DREAD_TIME at 1200
  - [ ] 9-seed passive median HQ-lost lands 20-35 min, moving beyond the IQR versus S0025 (36.0, IQR 31.9-40)
  - [ ] Econ gates hold: nw20 >= 90k, HQ survives >= 6/9, first raid 3-4 min; Hive ships @20 reported (<= 60 or a lower Hive production cap before minute 20)
  - [ ] `--perturb=1` run reported (not run since S0019); VS-029 marked done or the remaining gap stated
- Risks: Sim chaos means one-seed readings mislead, so use the 9-seed harness. Sequential runs only (parallel timed out).
- Why now: VS-029 has been blocked two sessions and passive and Hive-count numbers drifted the wrong way.

### Raids you can fight: intercept bounty and honest outcome reports
- Answers: Critic problem 1 and bold idea (visible war fronts); parking lot S0019 scout and QA (raid outcomes, redirect to Union)
- Pillar: Command depth
- Pitch: Raids already show on the map with an ETA. Now killing a raid group in transit pays a ledger bounty, and a deterred raid redirects to the nearest Union station instead of vanishing. The report says what actually happened, including "raid succeeded, destroyed X". The wing finally has a reason to leave HQ.
- Reference: X4 and Starsector fleet intercepts; Homeworld readability for the tracked group.
- Size: M   Type: feature
- Acceptance criteria:
  - [ ] Each raid outcome is exactly one of: intercepted (k/n), withdrew, redirected to <Union station>, succeeded (destroyed X)
  - [ ] Intercept kills in sectors other than the HQ pay a bounty through `Universe.add_credits(amount, "intercept")`, shown in the ledger breakdown
  - [ ] Deterred raids pick the nearest Union station and arrive there with the same ETA marker
  - [ ] Union ships @20 and the nw30 tail (seed 101) do not worsen; Hive ships @20 stays <= 60; balance gates and check.sh PASS
- Risks: Perturbed-econ tail (nw30 < 90k in 4/9 seeds) may worsen; ship-count and web perf guard (VS-006). Do after proposal 2.
- Why now: VS-025 and VS-029 are in, so this is the planned follow-up, and the critic has asked for it three times.

### Fit-to-screen text guard and map/title label fixes
- Answers: Critic problem 4; QA P3s (title FLIGHT line clipped, map "Sovereign HQ" label overlap, touch "+0 cr/min"). VS-032 covers the touch buttons, ACT wording and map fold, so this does not repeat them.
- Pillar: Readability & UX
- Pitch: The first screen on a phone should not have text running off the edges. Title controls wrap or shorten, the HQ map label stays readable, and touch shows the same cr/min figure as desktop.
- Reference: Freelancer and X4 keep the title and menus legible at every resolution. Mechanism: assert that no text exceeds the viewport.
- Size: S   Type: polish
- Acceptance criteria:
  - [ ] `--shot=title` at 1280x720 and 900x720 passes a test that no Label or draw_string rect leaves the viewport; the FLIGHT line wraps or is shortened
  - [ ] Map "Sovereign HQ" label is drawn above player and escort icons with an offset at default zoom (map.png reviewed)
  - [ ] Touch HUD cr/min matches desktop in the same state, and the cause of "+0" is noted; the rate is hidden for the first 15 s (parking lot S0013)
  - [ ] check.sh PASS
- Risks: Low. Layout-only, but it needs re-shots at both sizes.
- Why now: Three of these have survived two reviews, and the guard stops them coming back.

### On-foot pressure: flanking Hive and hit/kill feedback
- Answers: Critic problem 5 (bot clears pylons and Core in ~55 s with 0 damage); deepens VS-031, which only adds the spire and beams
- Pillar: On-foot FPS
- Pitch: Once the spire shows where to go, Hive units should come for you. A second wave arrives from the side after a pylon falls, and every hit and kill gives clear feedback. The 55-second walk becomes a short fight.
- Reference: Battlezone '98 ground skirmishes; Deep Rock Galactic wave pressure with clear objectives.
- Size: M   Type: feature
- Acceptance criteria:
  - [ ] After the first pylon dies, 2-3 Hive units spawn at 60-120 degrees off the player's heading and chase the player (constants in defs.gd)
  - [ ] `surface_long` shows player hull below 600 before the Core dies, and never below 150 for a bot that keeps moving to objectives
  - [ ] Hit-marker and kill flash/sound reuse the Sfx synthesis (no assets)
  - [ ] Surface timings stay: pylons down <= 90 s, Core dead <= 100 s (relax from 60/65 only if documented); no new lights; check.sh PASS
- Risks: Touch aim is imprecise, so keep dps low. Depends on VS-031 landing first, and enemy count affects the web frame budget.
- Why now: On-foot FPS is the weakest pillar, and VS-031 is only the visual half of the fix.
