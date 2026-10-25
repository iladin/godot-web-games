---
name: export-and-deploy
description: Export Godot games from this repo to HTML5, serve them locally, and publish to GitHub Pages, Cloudflare Pages, Netlify or itch.io, including the threads/COOP-COEP header gotcha. Use when the user asks to export, host, deploy, publish, or change hosting.
---

# Export & deploy

## Local
```bash
./scripts/install_godot.sh          # optional: Linux binary + web templates into ~/.local
./scripts/export_all.sh             # build/<slug>/index.html for every game
python3 scripts/build_site.py       # build/index.html gallery
./scripts/serve.sh                  # http://localhost:8000
```
Opening `index.html` via `file://` does not work — always serve over HTTP.

Export templates must match the editor version exactly. In the editor: Editor → Manage Export Templates → Download. Headless: `install_godot.sh` pulls only the web templates.

## The one gotcha: threads
| Export setting | Needs COOP/COEP headers? | Hosts |
|---|---|---|
| `variant/thread_support=false` (**repo default**) | No | Anywhere, including GitHub Pages |
| `variant/thread_support=true` | Yes (`Cross-Origin-Opener-Policy: same-origin`, `Cross-Origin-Embedder-Policy: require-corp`) | Netlify, Cloudflare Pages (`hosting/_headers`), itch.io (tick "SharedArrayBuffer support") |

Only turn threads on if a game genuinely needs them. Single-threaded audio can crackle on low-end devices — that's the tradeoff.

## Hosts
- **GitHub Pages** (default) — `.github/workflows/deploy-pages.yml`. One-time: Settings → Pages → Source: GitHub Actions. Public repo for free.
- **Netlify** — move `hosting/netlify.toml` to the repo root and connect the repo. Supports headers if threads are ever on.
- **Cloudflare Pages** — 25 MiB per-file cap; Godot's stock `index.wasm` usually exceeds it. Check `ls -lh build/*/index.wasm` before trying. Only viable with a size-optimized custom export template.
- **itch.io** — best for discovery and a community. `./scripts/zip_for_itch.sh <slug>` → upload `dist/<slug>-web.zip`, kind of project = HTML, tick "This file will be played in the browser", set viewport 720×1280 (or enable fullscreen button). Optional automation: `butler push dist/<slug>-web.zip <user>/<game>:web`.
- **Embedding elsewhere** — any exported game is a static folder; drop it into any site and `<iframe src="/games/starfall/" width="720" height="1280" allow="fullscreen; autoplay">`.

## Size budget
Check `du -sh build/<slug>`. The engine `.wasm` is the bulk (~35–45 MB uncompressed, much smaller gzipped/brotli, which all these hosts do automatically). Keep game assets under ~10 MB on top.

## When CI fails
Open the failed run → the `Check games` / `Export games` steps show output per game. Reproduce locally with `./scripts/check.sh <slug>`.
