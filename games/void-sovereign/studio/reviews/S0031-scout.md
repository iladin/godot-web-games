# S0031 Scout proposals: Void Sovereign

Already in BACKLOG as todo (not re-proposed, but ordering advice at the end): VS-035 fit-to-screen text guard, VS-036 raids you can fight, VS-037 on-foot flanking. Balance is green 8/8 so nothing here is a balance task. No brand-new system is proposed; no Out of scope change is needed.

### Hot opening: scouts visibly close in within 25 s
- Answers: S0031 critic problem 1 (dead air t=1..60); QA P3 sortie tip box over the ship.
- Pillar: First 10 minutes (also Flight feel)
- Pitch: Within seconds of takeoff the player sees two scouts as bearing markers with a distance readout and hears a short radio line ("Contacts, bearing 040"). The scouts close in on a visible path and first shots land by about t=25, not t=60. The tip box moves off the ship to a screen edge.
- Reference: Everspace / Freelancer openings (an immediate small fight that teaches the controls); Battlezone '98 radio callouts.
- Size: S   Type: feature
- Acceptance criteria:
  - [ ] `combat_long` shows first shield or hull damage at t <= 30 (was ~60), and hull is still >= 450 at t=85 for the idle bot
  - [ ] Sortie scouts show an on-screen or edge bearing marker with distance from t <= 3
  - [ ] One radio/message line fires at first contact, with touch wording on touch
  - [ ] Tutorial tip box is not drawn over the player ship in `sortie.png` (BOX_Y_FRAC or side anchor)
  - [ ] check.sh PASS; balance gates unchanged (sortie constants only)
- Risks: Idle touch players take more early damage (HANDOVER harshness question), so keep scout dps low. Marker overdraw on small screens.
- Why now: This is the first minute every new player sees, and the sortie change in VS-030 did not make the opening a hook.

### Raid tracks on the galaxy inset (split of VS-036, step 1)
- Answers: S0031 critic problem 2 and bold idea (visible war fronts).
- Pillar: Command depth (also Fantasy)
- Pitch: Each Hive raid shows on the galaxy inset and command map as a moving marker with target and ETA, and ends with one honest outcome line. The player can send the wing to intercept before it arrives. This ships first, before the bounty and redirect rules, so the data and UI can be judged on their own.
- Reference: X4 map orders and threat overlay; Homeworld fleet readability; Starsector fleet markers.
- Size: M   Type: feature
- Acceptance criteria:
  - [ ] Every active raid draws a marker on the inset with target sector name and ETA seconds, updated at 1 Hz
  - [ ] Raid end writes exactly one of: intercepted (k/n), withdrew, succeeded (destroyed X), shown as a message and in the map panel's last 5 min list
  - [ ] Map order "Patrol sector X" on a raid's target sector is reachable in <= 3 clicks or taps
  - [ ] No change to raid spawn or deterrence logic: the 9-seed gate medians are unchanged within IQR (Hive ships @20 <= 60)
  - [ ] Markers are removed from state on save/load round trip (selftest asserts)
  - [ ] check.sh PASS
- Risks: Map clutter at 900 px width; depends on the VS-025 raid tracker being reused, not duplicated. After this lands VS-036 shrinks to bounty plus redirect.
- Why now: The HUD countdown is the main tension device and it has no consequence a competent player can see (HQ survives 9/9).

### Income empty state: show where the first credits will come from
- Answers: S0031 critic problem 5 ("+0 cr/min" next to 30,000 cr; gross vs net unexplained).
- Pillar: Economy legibility
- Pitch: Until the first sale, the HUD shows no rate and the map panel shows a short "Income sources" block instead of "no credit changes yet": station income, trader runs and bounties, each with a current estimate and a one-line hint. Afterwards the panel labels the rate as net, with gross shown beside it.
- Reference: Starsector and X4 finance screens (income grouped by source, with the player shown what they can still unlock).
- Size: S   Type: polish
- Acceptance criteria:
  - [ ] No cr/min text on desktop or touch HUD before the first ledger entry or 15 s (shared with VS-035 item 3; do not duplicate the work)
  - [ ] Map panel's first state lists 3 income sources with estimates computed from owned stations and traders (0 is shown honestly)
  - [ ] After income starts, panel shows "net X (gross Y)" and a ledger test asserts gross >= net
  - [ ] Ledger stays a pure observer: `Universe.add_credits` remains the only writer (selftest still asserts)
  - [ ] check.sh PASS
- Risks: Estimates must come from the same code that pays out, or they will drift from the real numbers.
- Why now: Economy legibility has stayed at 6 for three reviews, and VS-035 only hides the number.

### Honest save on the surface (landing checkpoint and HUD notice)
- Answers: S0031 QA P3 (autosave never fires on foot; Continue restores the last in-space save with no warning).
- Pillar: Readability & UX (also First 10 minutes)
- Pitch: When the player lands, the game writes one in-space autosave at the moment of descent, and the surface HUD says "Progress is saved when you return to space". Closing the tab on foot then loses at most the sortie, and the player is told so. Save-anywhere stays out of scope: no on-foot state is ever written.
- Reference: Deep Rock Galactic and Battlezone-style mission checkpoints (save at the drop, resolve at extraction).
- Size: S   Type: polish
- Acceptance criteria:
  - [ ] An autosave is written when surface mode starts, using the existing atomic writer, and contains no surface state
  - [ ] The surface HUD shows the one-line notice for the first 8 s and in the pause overlay
  - [ ] Focus-out on the surface does not corrupt or advance the save (selftest: save before descent, focus-out, load, state equals the pre-descent state)
  - [ ] Dying on the surface and pressing Continue restores the pre-descent state
  - [ ] DESIGN.md Out of scope is unchanged; check.sh PASS
- Risks: Must not double-write during the descent frame; web IDBFS flush timing (see the next proposal).
- Why now: It is a repeat P3 since S0025, and VS-033 just made saves trustworthy, so the gap is now the surprising part.

### Real-browser smoke: save round trip and late-game frame time
- Answers: S0031 critic problem 10 (VS-006 never verified in five reviews); QA notes (IndexedDB .bak rename untested on web).
- Pillar: Web/touch fitness
- Pitch: A script exports the web build, loads it in headless Chromium, plays a seeded fast-forward to about 60 ships, and records frame time. It also saves, reloads the page and confirms Continue restores the same state, including the `.bak` fallback path. The numbers go into metrics.csv so every later review can quote them.
- Reference: The repo's own balance gate pattern (a deterministic script with thresholds), not a game reference.
- Size: M   Type: tech
- Acceptance criteria:
  - [ ] `scripts/` has a command that exports and serves the build and drives it headless, with no manual steps
  - [ ] Reports median and p95 frame time at about 20 and 60 ships, written to metrics.csv with the session id
  - [ ] Page reload then Continue restores credits and sector; deleting the main save file makes Continue use `.bak` (asserted)
  - [ ] Zero console errors on title, flight and surface
  - [ ] Failing thresholds are recorded, not hidden: VS-006 can be closed or reopened with real numbers
- Risks: Headless software GL timings are pessimistic; compare against a recorded baseline, not an absolute 60 fps. Export templates may need to be present on the runner.
- Why now: Five reviews have scored Web/touch fitness without measuring it, and Hive ships @20 sits at q3 61.

## Suggested order
1. VS-035 (existing, S) together with the income empty state, since they touch the same HUD and map text.
2. Hot opening, then the save notice (both S, low risk).
3. Raid tracks, then the remaining VS-036 bounty rules, then VS-037.
4. Browser smoke any time; schedule it before the next Hive production change.
