QA REPORT - sweep - S0056
Criteria: n/a (sweep)
Regression / coverage:
- bash scripts/check.sh void-sovereign: PASS (import, smoke, autoplay, selftest).
- surface_long (90 s headless, 6000 frames): 0 error-pattern lines; pylons t=45, 55, core t=67; credits 30000 -> 32923; hull/shield stable; no softlock.
- combat_long: 0 error-pattern lines (only exit-time "ObjectDB instances leaked / 9 resources in use" notices, harmless); shield drains to 108 then recovers, credits rise 30000 -> 31933.
- Shots reviewed (1280x720 and 900x720): map, dock, touch_surface (900), raid_map_touch, over. shot.sh also rendered surface, win, death, raid_map without script errors.
- Code read: Fleet Reserve (call_reserve / reserve_refusal / expires): cost, cooldown, expiry and save/load of reserve_ready_at and expires all consistent; no exploit found (4,000 cr, 600 s cooldown, no kills credited on expiry). Focus-out pause + autosave present in main.gd.
Bugs:
- [P3] Touch surface 900x720: ACT / JUMP / RUN / FIRE buttons crowd into one overlapping cluster, and the first-person gun model sits underneath them - repro: RES=900x720 shots.sh void-sovereign touch_surface - expected: separated hit targets - actual: ACT circle overlaps JUMP and FIRE edges (mis-tap risk) - evidence: .tools/shots/void-sovereign/touch_surface.png
- [P3] Command map side panel at 900x720 is clipped at the bottom (info text "...per min each" cut off; Reserve button just fits) - relies on scroll; no visible scroll cue beyond a thin bar - evidence: .tools/shots/void-sovereign/map.png (900)
- [P3] Game-over screen: "Best 170,997" line collides with the ship model/backdrop mid-screen, reducing legibility - evidence: .tools/shots/void-sovereign/over.png
Notes for Producer:
- No P0-P2 found; build is stable on all runs. Remaining findings are touch/narrow layout polish (possible single VS task: "900x720 touch surface button spacing + map side panel scroll hint").
- Env note: /tmp is not writable by QA from the device shell and long Godot runs must run foreground (backgrounded runs died silently); write logs under .tools/.
