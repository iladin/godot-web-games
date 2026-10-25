#!/usr/bin/env python3
"""Build build/index.html: a gallery of every exported game.

Reads games/<slug>/game.json for each game that has an export in build/<slug>/.
Use --all to list games even if they weren't exported (for previewing the page).
"""
import html
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
GAMES = ROOT / "games"
BUILD = ROOT / "build"
HEX = re.compile(r"^#[0-9a-fA-F]{6}$")


def load_games(include_unexported: bool) -> list[dict]:
    games = []
    for meta_path in sorted(GAMES.glob("*/game.json")):
        slug = meta_path.parent.name
        if not include_unexported and not (BUILD / slug / "index.html").exists():
            continue
        try:
            meta = json.loads(meta_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as e:
            sys.exit(f"{meta_path}: invalid JSON ({e})")
        accent = meta.get("accent", "#5ee6ff")
        games.append({
            "slug": slug,
            "title": meta.get("title", slug),
            "tagline": meta.get("tagline", ""),
            "controls": meta.get("controls", ""),
            "accent": accent if HEX.match(accent) else "#5ee6ff",
        })
    return games


def card(g: dict) -> str:
    e = html.escape
    initial = e(g["title"][:1].upper())
    return f"""
      <a class="card" href="./{e(g['slug'])}/" style="--accent:{g['accent']}">
        <div class="thumb"><span>{initial}</span></div>
        <div class="body">
          <h2>{e(g['title'])}</h2>
          <p>{e(g['tagline'])}</p>
          <small>{e(g['controls'])}</small>
        </div>
      </a>"""


PAGE = """<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Game Shelf</title>
<style>
  :root {{ --bg:#0b0d1a; --panel:#151833; --text:#eef0ff; --muted:#9aa0c7; }}
  * {{ box-sizing:border-box; }}
  body {{ margin:0; background:var(--bg); color:var(--text);
         font:16px/1.5 system-ui, -apple-system, "Segoe UI", sans-serif; }}
  header {{ max-width:1080px; margin:0 auto; padding:48px 16px 8px; }}
  h1 {{ margin:0; font-size:clamp(32px,6vw,56px); letter-spacing:-0.02em; }}
  header p {{ margin:4px 0 0; color:var(--muted); }}
  main {{ max-width:1080px; margin:0 auto; padding:24px 16px 64px;
         display:grid; gap:16px; grid-template-columns:repeat(auto-fill,minmax(240px,1fr)); }}
  .card {{ display:flex; flex-direction:column; background:var(--panel); border-radius:16px;
          overflow:hidden; color:inherit; text-decoration:none;
          border:1px solid color-mix(in srgb, var(--accent) 25%, transparent);
          transition:transform .15s ease, border-color .15s ease; }}
  .card:hover, .card:focus-visible {{ transform:translateY(-3px); border-color:var(--accent); outline:none; }}
  .thumb {{ aspect-ratio:16/10; display:grid; place-items:center;
           background:radial-gradient(circle at 30% 30%, color-mix(in srgb, var(--accent) 55%, transparent), transparent 60%), #0e1024; }}
  .thumb span {{ font-size:64px; font-weight:800; color:var(--accent); }}
  .body {{ padding:14px 16px 18px; }}
  h2 {{ margin:0 0 4px; font-size:20px; }}
  .body p {{ margin:0 0 8px; color:var(--muted); }}
  small {{ color:var(--accent); }}
  .empty {{ color:var(--muted); }}
</style>
</head>
<body>
<header>
  <h1>Game Shelf</h1>
  <p>{count} browser game{plural} · made with Godot</p>
</header>
<main>{cards}
</main>
</body>
</html>
"""


def main() -> None:
    include_all = "--all" in sys.argv
    games = load_games(include_all)
    cards = "".join(card(g) for g in games) or '\n  <p class="empty">No games exported yet.</p>'
    BUILD.mkdir(exist_ok=True)
    out = BUILD / "index.html"
    out.write_text(PAGE.format(count=len(games), plural="" if len(games) == 1 else "s", cards=cards),
                   encoding="utf-8")
    print(f"Wrote {out.relative_to(ROOT)} with {len(games)} game(s)")


if __name__ == "__main__":
    main()
