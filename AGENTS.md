# AGENTS.md

All agent instructions for this repo live in [`CLAUDE.md`](CLAUDE.md). Read it first.

Task-specific playbooks are in `.claude/skills/*/SKILL.md` — plain Markdown, usable by any agent:

| Task | Read |
|---|---|
| Build a new game from a pitch | `.claude/skills/new-game/SKILL.md` |
| Write or fix GDScript for web | `.claude/skills/godot-web-gdscript/SKILL.md` |
| Make it feel good | `.claude/skills/game-feel/SKILL.md` |
| Verify it runs | `.claude/skills/playtest-check/SKILL.md` |
| Export / host / publish | `.claude/skills/export-and-deploy/SKILL.md` |

Gate before finishing any game: `./scripts/check.sh <slug>` prints `PASS`.
