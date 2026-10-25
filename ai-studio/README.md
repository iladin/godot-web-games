# ai-studio

The autonomous development loop for games in this repo. Strategy: [`docs/AI_STUDIO.md`](../docs/AI_STUDIO.md).

| File | What |
|---|---|
| `studio-cycle.md` | The Producer's procedure — what every scheduled session follows, step by step |
| `roles/game-developer.md` | Implements one task, tests it, reports |
| `roles/qa-tester.md` | Verify mode (PASS/FAIL per acceptance criterion) and sweep mode (bug hunt) |
| `roles/game-critic.md` | Scores the build on 10 pillars, top 5 problems, trends |
| `roles/balance-analyst.md` | Runs the simulation harness, compares to targets, proposes numbers |
| `roles/feature-scout.md` | ≤5 scoped proposals grounded in findings and genre references |

These files live here (not in `.claude/`) because remote sessions can't write to `.claude/` on your computer, and sessions read them directly anyway.
Optional, for native Claude Code use on your machine: copy `roles/*.md` into `.claude/agents/` (they already have subagent frontmatter) and `studio-cycle.md` into `.claude/skills/studio-cycle/SKILL.md`. Keep this folder as the source of truth.
