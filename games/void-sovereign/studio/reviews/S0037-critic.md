# S0037 Critic review: Void Sovereign

_Sixth critic review; compared with `S0031-critic.md` (6.5/10). Build: HEAD after S0036 (VS-035 text fit, VS-036 raid bounty/tracks, VS-037 flank squad, VS-038 hot opening, VS-039 raid tracks/Defend, VS-040 ledger net/gross). Evidence rendered 2026-10-28 into `.tools/shots/void-sovereign/` (title, map, dock, surface, touch, touch_surface, combat); viewed: title, map, combat, touch, surface. Not viewed: dock, touch_surface, over, win (over/win render timed out in this run). `combat_long` and `surface_long` re-run headless. Balance numbers from metrics.csv (last row S0031, not re-run; HANDOVER says unchanged)._

| # | Pillar | Score | Trend | Justification |
|---|---|---|---|---|
| 1 | Fantasy | 6 | → | Wing orders, map and Continue carry it; HQ is still not credibly threatened by an active player. |
| 2 | Flight feel | 7 | ↑ | `combat_long`: shield 400 -> 108 over t=11..30 (fight now starts at t=11, was t=60). Hull never touched; shield refills by t=45. The fight is a shield tickle, not a threat. |
| 3 | Command depth | 7 | → | Raid tracks on the galaxy inset (`map.png`: red markers with counts 6/2/6) give the wing a purpose; redirect is off, so the decision is thin. |
| 4 | On-foot FPS | 7 | → | `surface.png`: beams plus "2x PYLON 366m" read well. Flank squad now exists (flank=5 at t=49) but `min_foot` only 525/600 and hp stays 100: no pressure. |
| 5 | Economy legibility | 6 | → | Ledger net/gross shipped, but HUD top bar still shows an unlabelled "+150 cr" (`combat.png`) which is a one-off sale, not a rate. |
| 6 | First 10 minutes | 7 | → | Contact by t=11 is a real improvement, but tip 1/6 "Click the view to capture the mouse" sits over the first fight and the ship is already under fire while the player is reading it. |
| 7 | Readability & UX | 7 | ↑ | Title no longer clipped (`title.png`, though the controls paragraph widows "T / travel"). Map HQ label now readable. Touch: THR+ still overlaps a station silhouette, wing ATK/ESC/HOLD column sits on the planet limb, "Click to capture mouse" still floats mid-screen on the surface. |
| 8 | Visual identity | 7 | → | Pink sky, magenta veins, beams: intentional. Ships and stations remain box-kit; the FPS weapon is a plain black slab. |
| 9 | Pacing & difficulty | 6 | → | Passive HQ-lost 31.9 min is on target, but econ runs still end 9/9 HQ survived; nw30 median 122k, so tension is a countdown that rarely bites. |
| 10 | Web/touch fitness | 7 | → | Touch layout is fine at 1280x720; VS-006/VS-042 real-browser verification has now slipped six reviews. |

**Average: 6.7 / 10** (S0031: 6.5). Biggest mover: Flight feel +1 (6 -> 7, hot opening), Readability +1 (6 -> 7, title/map fixes). Nothing regressed.

## What changed since S0031
- VS-038: first contact at t=11, shield drained to 108 by t=30, bounty +150 at t=11 and +1,483 at t=75 (sortie kill). Real fix to old problem 1.
- VS-035/039/040: title and map text fit; raid tracks on the inset; ledger shows income sources. Good, mostly invisible during a first look.
- VS-037: `surface_long` flank=5 spawns after pylon1 (t=45), pylons down t=51, Core dead ~65 s; `min_foot` 525, hp 100 the whole run. The squad exists but the bot beats it for free.
- Open: opening fight is hot, but then nothing happens t=45..75 (shield full, hull 600, credits flat at 30,450) until the sortie bounty.

## Top 5 problems (by player impact)

### 1. Active play is still never dangerous
- **Symptom:** `combat_long` hull 600 for the entire 89 s; `surface_long` hp 100 / hull 600 throughout; econ gate 9/9 HQ survival.
- **Evidence:** `combat_long` lines t=12..89; `surface_long` min_foot 525; metrics S0031 econ row.
- **Why it matters:** every tension device (raids, flankers, scouts) drains shield and then resets. No decision is ever costly, so the fantasy of a sovereign under siege never lands.
- **Direction:** make damage persistent and consequential (hull/hp attrition across a landing, VS-045; raids that actually take HQ shield/hull when ignored), not just regenerating shield.

### 2. The opening fight collides with the first tip
- **Symptom:** shield falls from t=12 while tip 1/6 asks the player to capture the mouse (`combat.png`, T+00:03, a Hive Drone already 1.7 km out).
- **Evidence:** `combat.png`, `combat_long` t=11..30.
- **Why it matters:** a new player is shot at during the one sentence teaching steering; the "lock a target" and "fire" tips come after the fight starts. Open question: 8 s after takeoff is too aggressive for first-time touch players if tips lag.
- **Direction:** order tips by what is happening (fire/target first when a hostile is inbound), or delay contact until steering has been exercised once.

### 3. Economy HUD number is a lie
- **Symptom:** "+150 cr" next to 30,150 cr at T+00:03, one sale, shown as if it were a rate; gross vs net and the one-off nature are unexplained at the top bar.
- **Evidence:** `combat.png` top-left; HANDOVER carry-over "top-bar HUD rate still gross/unlabelled".
- **Why it matters:** the ledger panel is honest, but the thing players watch constantly is not.
- **Direction:** label it (cr/min net) or show last change as a transient delta; match the map ledger's wording.

### 4. Touch and surface prompts still clutter
- **Symptom:** THR+ on a station silhouette, ATK/ESC/HOLD on the planet limb (`touch.png`); "Click to capture mouse" mid-screen on surface (`surface.png`) and the title controls paragraph widows "T / travel".
- **Why it matters:** fifth review running for the capture prompt; the controls paragraph is the first thing read.
- **Direction:** fixed bottom bar for the capture prompt; give the wing column an opaque backing; shorten the FLIGHT control line.

### 5. Real-browser behaviour is unverified
- **Symptom:** IndexedDB saves, .bak rename, audio unlock and WebGL perf have never been seen in a real browser (VS-042, VS-006).
- **Evidence:** HANDOVER open question; all evidence here is headless Mesa.
- **Why it matters:** this is a browser game; a save or audio failure on load kills the first impression regardless of the polish above.
- **Direction:** do VS-042 before more tuning; one 10-minute manual or automated browser pass on desktop and a phone.

## Protect this
- **Pylon beams and Core spire** as the surface landmark (`surface.png`: three beams readable at 366 m).
- **The hot opening** (contact by t~11) and the ledger as pure observer with atomic Continue/New Game.

## One bold idea
**Persistent war damage:** raiders and flankers wound things that stay wounded: station hull that needs repair crews/credits, on-foot hp that carries between landings, wing ships that need drydock time. It converts the existing countdown and flank squad into real economic decisions and answers problem 1 without new content. (Carries over the visible-war-fronts idea, whose tracking half now exists.)

## Notes for open questions (HANDOVER)
- Longer desktop hint text: keep, it is not what is cluttering; fix problem 4 first.
- HUD gross vs net: net, labelled (problem 3).
- Flank squad 5-6 instead of 2-3: yes, keep, but it needs hp cost (VS-045) to matter.
- Fortified HQ raid-free after minute 20: yes, make the Breach nastier, ties into problem 1.

## Evidence index
- **Screenshots:** `.tools/shots/void-sovereign/{title,map,combat,touch,surface}.png`.
- **`combat_long`:** credits 30,000 -> 30,150 at t=11; shield 400 -> 108 by t=30; shield 400 by t=45; credits 31,933 at t=75; hull 600 throughout.
- **`surface_long`:** pylon1 45 s, pylons down 51 s, flank=5 at t=49, Core dead ~65 s, min_foot 525, hp 100; no SCRIPT ERROR.
