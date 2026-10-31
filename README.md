# Godot Web Games

A monorepo for making small Godot 4 games that play in the browser, built so an AI coding agent (Claude Code, or anything that reads `AGENTS.md`) can generate, check and ship a new game from a one-line pitch.

Push to `main` → GitHub Actions installs Godot headless, exports every game to HTML5/WASM, builds a gallery page, and deploys to GitHub Pages.

```
https://<you>.github.io/<repo>/            ← gallery
https://<you>.github.io/<repo>/starfall/   ← each game
```

## Quick start

```bash
# 1. Make a new game from the template
./scripts/new_game.sh space-goats "Space Goats"

# 2. Ask your agent to build it
claude "/new-game space-goats: lane-switching runner where goats dodge asteroids, tap to switch lanes"

# 3. Check + export locally (needs Godot 4.7 on PATH, or GODOT=/path/to/godot)
./scripts/check.sh space-goats
./scripts/export_all.sh && ./scripts/serve.sh   # http://localhost:8000

# 4. Ship
git add . && git commit -m "Add Space Goats" && git push
```

One-time GitHub setup: **Settings → Pages → Source: GitHub Actions.**

## Layout

| Path | What it is |
|---|---|
| `CLAUDE.md` / `AGENTS.md` | Rules the agent follows in this repo |
| `.claude/skills/` | Skills: `new-game`, `godot-web-gdscript`, `game-feel`, `playtest-check`, `export-and-deploy` |
| `template/` | Minimal working Godot project every new game is copied from |
| `games/<slug>/` | One self-contained Godot project per game (+ `game.json`, `DESIGN.md`) |
| `games/starfall/` | Complete sample game (catch stars, dodge meteors; keyboard + touch) |
| `scripts/` | `new_game`, `install_godot`, `check`, `export_all`, `build_site`, `serve`, `zip_for_itch` |
| `hosting/` | Drop-in config for Netlify / Cloudflare Pages |
| `docs/HOSTING.md` | Hosting comparison and the threads/headers gotcha |
| `.github/workflows/deploy-pages.yml` | CI: check → export → gallery → Pages |

## Games built for AI players

`falsify` (educational), `opcode` (hard) and `crossfire` (fun) were designed with an AI as the primary player, but humans can play them with touch, mouse or keyboard. All three are turn-based and fully observable, and each one exposes the same interface (`games/<slug>/scripts/ai_bridge.gd`, an identical copy in each game):

| Way in | How |
|---|---|
| Keyboard command line | Press `/`, type a command (`help` lists them), Enter. It stays open for the next command. |
| Browser JS | `aiGame.state()` returns the full state as an object; `aiGame.play("cmd")` returns `{ok, msg, state}`; `aiGame.help` lists the commands. |
| Headless | `--autoplay` runs a bot through the same commands. `--shot=<name> --shotfile=<png>` renders a scenario. |

| Game | Commands | What it is |
|---|---|---|
| Falsify | `test 3 6 9`, `name B`, `next` | Find a hidden rule over number triples; every experiment costs funding (Wason's 2-4-6 task). |
| Opcode | `open 7`, `program IN \| ADD 5 \| OUT`, `run`, `step` | Assembly puzzles for a 3-register machine, with par scores for cycles and size. |
| Crossfire | `move ne`, `shove w`, `end`, `map` | Hex tactics with no weapon: enemies telegraph their attacks; shove them into each other. |

## Why it works on GitHub Pages

Godot 4.3+ can export **without thread support**, which removes the need for `SharedArrayBuffer` and the COOP/COEP headers GitHub Pages can't set. Every preset here ships with `variant/thread_support=false`. If you ever turn threads on, use a host that supports custom headers (see `docs/HOSTING.md`).

## Pinning Godot

The version lives in one place: `GODOT_VERSION` in `.github/workflows/deploy-pages.yml` (default for scripts is the same). Bump it there; CI caches the binary + web templates per version.
