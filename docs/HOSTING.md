# Hosting options (checked October 2026)

All exported games are plain static files, so any static host works. Free tiers change — verify before relying on limits.

| Host | Free tier highlights | Custom headers (for threaded exports) | Best for |
|---|---|---|---|
| **GitHub Pages** (default here) | Free for public repos; ~100 GB/mo soft bandwidth cap; 1 GB site | No | Zero-config from this repo |
| **Cloudflare Pages** | Unmetered static bandwidth, unlimited sites, 500 builds/mo, commercial use OK — **but 25 MiB max per file** | Yes (`_headers`) | Great for the gallery; Godot's stock `.wasm` usually exceeds the per-file cap (see below) |
| **Netlify** | Credit-based free plan (hard-capped, no overage), commercial use OK | Yes (`netlify.toml` / `_headers`) | Deploy previews per PR |
| **Vercel** | Hobby tier is personal/non-commercial only | Yes (`vercel.json`) | Fine, but no advantage for static games |
| **itch.io** | Free; HTML5 games play in an iframe on your game page; donations only for browser games | "SharedArrayBuffer support" checkbox | Players, discovery, game jams, community |
| **GitLab Pages** | Free with GitLab | No | If the repo lives on GitLab (CI config is a short port of the GitHub workflow) |
| **Firebase / Azure Static Web Apps / Render** | Small free tiers with bandwidth caps | Yes | Only if you're already in those ecosystems |

## Recommendation
- **Start:** GitHub Pages — the workflow is already here.
- **If you outgrow GitHub Pages:** Netlify (no per-file cap issue, headers supported). Cloudflare Pages only after confirming your `index.wasm` is under 25 MiB.
- **For players and feedback:** also publish each finished game on itch.io (`scripts/zip_for_itch.sh`). GitHub Pages / Netlify are your portfolio; itch.io is where people find games.

## Threads and headers
The repo exports with `variant/thread_support=false`, so no `SharedArrayBuffer`, so no COOP/COEP headers, so it runs on every host above. Turn threads on only for a game that needs them, and then avoid GitHub/GitLab Pages for that game.

## Scaling note
Each exported game carries its own copy of the engine (`index.wasm`, roughly 35–45 MB uncompressed). GitHub Pages caps a site at about 1 GB, so plan on ~20 games per repo there. Cloudflare Pages rejects any single file over 25 MiB, and Godot 4's stock web `index.wasm` is typically larger. Check with `ls -lh build/*/index.wasm`. Getting under it means a size-optimized custom export template (Godot compiled with unused modules disabled) — doable, but not worth it for a hobby setup. Netlify and GitHub Pages don't have this problem.

## Custom domain on GitHub Pages
Settings → Pages → Custom domain, then a `CNAME` DNS record to `<you>.github.io`. Add a `CNAME` file to `build/` in `export_all.sh` if you want it versioned.
