# Void Sovereign — Handover
_Last updated: S0018 · 2026-10-27 07:35 UTC · mode: BUILD_

## TL;DR
S0018 split the L task VS-009 (save/continue) into VS-026/027/028 and shipped **VS-023** (raid deterrent counts only platforms within RAID_DETER_RANGE 3400 of the target; build_station rejects planet interiors; DREAD_TIME 900→1200). QA PASS, check.sh PASS. builds_since_review = 6, so the health rule says PLANNING next.

## Next session should
1. **Preflight** per `ai-studio/studio-cycle.md` (repo at `$HOME/mnt/godot-web-games`; use `git --no-optional-locks -c core.fileMode=false …`). Session id: state.json counter is 18 → next is S0019.
2. **Run PLANNING first** (builds_since_review = 6): Critic + QA sweep + Balance Analyst in parallel, then Feature Scout; 4–8 tasks. Check that the new save tasks and the open ones (VS-025, VS-026..028) are deduped. Balance Analyst: re-run `--perturb=1` econ (thin margin, see Watch out).
3. Then BUILD `VS-025` (honest raid reports, S) if budget remains; otherwise next session.
4. Then `VS-026` (M, serialize Universe: new `scripts/sim/save_game.gd`), `VS-027` (autosave + Continue), `VS-028` (robustness). Order matters: 026 → 027 → 028.
5. Re-measure Hive counts and unblock/close `VS-006` (web perf guard).
6. Bundle parking-lot P3 polish into one P2 S task.

## Last session
- Did: VS-009 split (Daniel had restored it to todo). VS-023 done: `RAID_DETER_RANGE`/`DREAD_TIME` in `scripts/sim/defs.gd`, range filter in `scripts/sim/director.gd` raid_go_chance, planet guard in `Universe.build_station`, selftest assertions, DESIGN.md Ramp, 2 metrics rows. 9-seed gates: econ nw30 142k ≥ nw20 108k, HQ 9/9; perturbed econ 129k vs 126k; passive HQ lost median 33.6.
- Check: PASS · Git: committed game paths (see `git log -1`) · Roles collapsed: none

## In-flight / uncommitted work
None from S0018 after its commit. Unrelated working-tree edits not staged: `ai-studio/studio-cycle.md`, `docs/AI_STUDIO.md`, `.claude/skills`, `AGENTS.md`, `CLAUDE.md`, and untracked `_to_delete/`. Snapshot S0018 in `.tools/snapshots/void-sovereign/`.

## Build health
- check.sh: PASS · selftest OK · known noise: ObjectDB leaked at exit, ALSA under xvfb.
- Latest metrics: econ30 9 seeds HQ 9/9 nw20 med 107685 nw30 med 142176; passive40 HQ lost med 33.6 (2/9 survive).

## Backlog snapshot
todo 4 · in-progress 0 · done 20 · blocked 1 · split 3 · ready 4 · Top ready: VS-025, VS-026, VS-027

## Watch out for
- **Perturbed econ gate is thin:** nw30 129014 vs nw20 126353, 4/9 seeds below. Re-run `--perturb=1` after any raid/dreadnought tuning.
- **Credits:** use `Universe.add_credits(amount, "<category>")`.
- **Raid deterrent:** keep 0.25^n go-chance; platforms only count within RAID_DETER_RANGE of the raid target.
- **Sim chaos:** judge balance on 9-seed medians with fresh `GATE_OUT`; extra RNG draws shift outcomes.
- **device_bash cap 180 s:** background jobs die when the call ends; run gates in foreground in split seed batches.
- **PauseGate must stay main's first child.** `main.gd` is over 306 lines. Every sound through `Sfx.play()`.
- **Touch layout:** ACT sits at (1160,300) at 1280x720; wing row is mid-screen (parking lot).

## Open questions for Daniel
- Is it acceptable that a fortified HQ is nearly raid-free after minute 20 (now somewhat less so)?
- Should the HUD income rate show net rather than gross? Target session length?
- Folder-connection permission prompts are an app/task setting ("Automatically approve"); a session can't change that.

## Answers to Daniel
- None (INBOX empty).

## Session history (newest first, keep 10)
- S0018 2026-10-27 BUILD — VS-009 split into VS-026..028; VS-023 raid deterrent range done (QA PASS)
- S0016 2026-10-27 BUILD — VS-007 wing commands done (QA FAIL touch overlap → fix → PASS)
- S0017 2026-10-27 SKIPPED — lock held by S0016
- S0015 2026-10-27 BUILD — VS-010 NPC traders vs broke player station done
- S0014 2026-10-27 BUILD — VS-005 marker declutter + VS-022 surface freeze done
- S0013 2026-10-27 BUILD — VS-024 credit ledger done
- S0012 2026-10-27 PLANNING — review round 2 (critic 5.5/10)
- S0011 2026-10-26 BUILD — VS-020 late-game Hive pressure fix
- S0010 2026-10-26 BUILD — VS-021 9-seed gates + VS-014 pause-screen input
- S0009 2026-10-26 BUILD — VS-018 First Sortie done
