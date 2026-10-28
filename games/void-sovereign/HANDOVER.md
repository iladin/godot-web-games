# Void Sovereign — Handover
_Last updated: S0033 · 2026-10-28 00:15 UTC · mode: BUILD_

## TL;DR
S0033 shipped VS-035 (title help text wraps to fit, map station names drawn above ships, top-bar cr/min hidden for first 15 s via Hud.rate_text); QA PASS. Build green; 6 ready todos.

## Next session should
1. Preflight per `ai-studio/studio-cycle.md` (repo `$HOME/mnt/godot-web-games`; `git --no-optional-locks -c core.fileMode=false ...`). Next id S0034. Export `GODOT=$(bash scripts/studio/ensure_godot.sh | tail -1)`.
2. BUILD `backlog.py next` -> VS-036 is size M (bounty + redirect only; VS-039 already ships outcome kinds). Before it, consider the S tasks VS-040 (income empty state / net-gross), VS-043 (raid panel fit at 900/touch), VS-041 (surface autosave notice).
3. Then VS-037, VS-042 (real-browser smoke, M; before next Hive production change).
4. builds_since_review = 3; planning round due after 6.
5. Check the QA P3: touch@900 hint line "Need credits? Dock at the Union.Trade Hub" shows a stray dot (1280 reads fine); find the string in hud/overlay and fix if real.
6. Consider a harness mode with the pilot present so balance gates include the First Sortie; run `--perturb=1` on the passive gate (HQ lost 31.9).

## Last session
- Did: BUILD VS-035 (overlay.gd fit_lines/title_body; map_view.gd station labels second pass; hud.gd rate_text; selftest _test_text_fit). QA PASS round 1.
- Check: PASS · Git: committed this session · Roles collapsed: none

## In-flight / uncommitted work
Unrelated, Daniel's, not staged: `ai-studio/studio-cycle.md`, `docs/AI_STUDIO.md`, untracked `_to_delete/`. QA left scratch `.tools/qa_base` (gitignored, harmless).

## Build health
- check.sh: PASS (use `timeout 175`) · known noise: ObjectDB leak at exit, ALSA, ERR_CANT_OPEN on --shot exit.
- Latest metrics (QA, HEAD, 9 seeds economic): HQ 9/9, nw10 93k, nw20 120.8k, nw30 167.5k, hive ships @20 median 53 (q3 61). Passive gate unchanged from S0031 (HQ lost 31.9). S0031 metrics.csv line for econ is slightly stale (nw20 104k).

## Backlog snapshot
todo 6 · in-progress 0 · done 33 · blocked 1 · split 3 · Top ready: VS-036, VS-037, VS-040

## Watch out for
- Title FLIGHT line wraps leaving an orphan "travel · M map" line (cosmetic). Station labels on map now drawn last; check overlap with gate labels if new stations are added.
- Raid panel pushes BUY/BUILD to the bottom edge with a raid active (VS-043). Inset label overlaps "Cinder Belt".
- "Succeeded" outcome is decided at raid end, not when the target dies.
- Defend with empty selection selects all armed ships incl. auto-trade/mine.
- Balance gates still hide the pilot (no First Sortie); idle touch players take scout damage from t~12.
- Do NOT `pkill -f godot`; use `pkill -x godot`. Foreground `timeout 175`, balance sequential.

## Open questions for Daniel
- Desktop text got slightly longer (earn hint at 0 income, HQ dock second sentence): keep, or touch-only?
- Fortified HQ nearly raid-free after minute 20: want the Breach nastier?
- HUD income gross vs net? Target session length? over.png Net worth 45,000 vs 30,000: confirm formula.
- A real-browser pass is still needed for IndexedDB persistence / .bak rename and audio unlock (VS-042).
- Is a scout fight 8 s after takeoff too aggressive for first-time touch players?

## Answers to Daniel
- none

## Session history (newest first, keep 10)
- S0033 2026-10-28 BUILD — VS-035 text fit guard + map/title labels + cr/min gate done (QA PASS)
- S0032 2026-10-27 BUILD — VS-039 raid tracks + outcome history + Defend button done (QA PASS)
- S0031 2026-10-27 PLANNING+BUILD — review round -> VS-038..042; VS-038 hot opening done (QA PASS round 2)
- S0030 2026-10-27 BUILD — VS-033 atomic run save, QA PASS -> done
- S0029 2026-10-27 BUILD — VS-032 touch/UX bundle, QA PASS -> done
- S0028 2026-10-27 BUILD — VS-031 spire + beams, QA PASS -> done
- S0027 2026-10-27 BUILD — VS-030 selftest fix, QA PASS -> done
- S0026 2026-10-27 BUILD — VS-030 First Sortie implemented, QA FAIL on dead selftest assertion -> blocked (code kept, check PASS)
- S0025 2026-10-27 PLANNING+BUILD — review round -> VS-033..037; VS-034 Breach retune done (QA PASS), VS-029 closed
- S0024 2026-10-27 BUILD — VS-028 save robustness + new-game confirm done (QA PASS)
