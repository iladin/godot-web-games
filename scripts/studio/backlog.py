#!/usr/bin/env python3
"""Deterministic helper for games/<slug>/studio/BACKLOG.md (stdlib only).

Task format (one per heading, fields as "- key: value" lines, acceptance as a checklist):

    ## VS-012 · Short imperative title
    - status: todo            # todo | in-progress | done | blocked | split
    - priority: P1            # P0 | P1 | P2 | P3
    - type: feature           # bug | feature | polish | balance | tech | perf
    - size: S                 # S | M | L   (L must be split before work)
    - source: critic          # critic | qa | scout | balance | human | dev | producer
    - created: S0003
    - why: one line citing the finding
    - acceptance:
      - [ ] observable, testable criterion
    - notes: free text (optional)
    - done: S0005 — summary (when done)

Everything after a heading "# Ideas parking lot" (or "## Ideas parking lot") is ignored.

Usage:
    backlog.py validate FILE
    backlog.py summary FILE
    backlog.py list FILE [STATUS]
    backlog.py next FILE            # prints task id or NONE
    backlog.py ready-count FILE
    backlog.py new-id FILE
    backlog.py set FILE ID FIELD VALUE
"""
import re
import sys

STATUSES = ["todo", "in-progress", "done", "blocked", "split"]
PRIORITIES = ["P0", "P1", "P2", "P3"]
TYPES = ["bug", "feature", "polish", "balance", "tech", "perf"]
SIZES = ["S", "M", "L"]
REQUIRED = ["status", "priority", "type", "size", "source", "why"]
HEAD_RE = re.compile(r"^##\s+([A-Z]+-\d+)\s*[·\-:]\s*(.+?)\s*$")
FIELD_RE = re.compile(r"^-\s+([a-z\-]+):\s*(.*)$")
PARKING_RE = re.compile(r"^#{1,2}\s+Ideas parking lot", re.I)


def parse(path):
    with open(path, encoding="utf-8") as f:
        lines = f.read().splitlines()
    tasks, cur = [], None
    for i, line in enumerate(lines):
        if PARKING_RE.match(line):
            break
        m = HEAD_RE.match(line)
        if m:
            cur = {"id": m.group(1), "title": m.group(2), "line": i, "fields": {}, "acceptance": []}
            tasks.append(cur)
            continue
        if cur is None:
            continue
        fm = FIELD_RE.match(line)
        if fm:
            cur["fields"][fm.group(1)] = fm.group(2).strip()
            cur["fields"].setdefault("_last", "")
            cur["_lastkey"] = fm.group(1)
        elif re.match(r"^\s+-\s+\[[ xX]\]", line) and cur.get("_lastkey") == "acceptance":
            cur["acceptance"].append(line.strip())
    return lines, tasks


def num(tid):
    return int(tid.split("-")[1])


def validate(tasks):
    errs, seen = [], set()
    in_prog = [t for t in tasks if t["fields"].get("status") == "in-progress"]
    for t in tasks:
        f = t["fields"]
        where = f"{t['id']} (line {t['line'] + 1})"
        if t["id"] in seen:
            errs.append(f"{where}: duplicate id")
        seen.add(t["id"])
        for k in REQUIRED:
            if not f.get(k):
                errs.append(f"{where}: missing '{k}'")
        checks = [("status", STATUSES), ("priority", PRIORITIES), ("type", TYPES), ("size", SIZES)]
        for k, allowed in checks:
            if f.get(k) and f[k] not in allowed:
                errs.append(f"{where}: {k}='{f[k]}' not in {allowed}")
        if f.get("status") in ("todo", "in-progress") and not t["acceptance"]:
            errs.append(f"{where}: no acceptance criteria")
    if len(in_prog) > 1:
        errs.append("more than one task in-progress: " + ", ".join(t["id"] for t in in_prog))
    return errs


def ready(tasks):
    return [t for t in tasks if t["fields"].get("status") == "todo" and t["fields"].get("size") != "L"]


def pick_next(tasks):
    for t in tasks:
        if t["fields"].get("status") == "in-progress":
            return t
    todo = [t for t in tasks if t["fields"].get("status") == "todo"]
    if not todo:
        return None

    def key(t):
        f = t["fields"]
        pr = PRIORITIES.index(f["priority"]) if f.get("priority") in PRIORITIES else 9
        return (pr, 0 if f.get("type") == "bug" else 1, num(t["id"]))

    todo.sort(key=key)
    return todo[0]  # may be size L: the Producer must split it


def main(argv):
    if len(argv) < 3:
        print(__doc__)
        return 2
    cmd, path = argv[1], argv[2]
    lines, tasks = parse(path)
    if cmd == "validate":
        errs = validate(tasks)
        for e in errs:
            print("ERROR", e)
        print(f"{len(tasks)} tasks, {len(errs)} errors")
        return 1 if errs else 0
    if cmd == "summary":
        counts = {s: 0 for s in STATUSES}
        for t in tasks:
            s = t["fields"].get("status", "?")
            counts[s] = counts.get(s, 0) + 1
        print(" · ".join(f"{k} {v}" for k, v in counts.items()) + f" · ready {len(ready(tasks))}")
        return 0
    if cmd == "list":
        want = argv[3] if len(argv) > 3 else None
        for t in tasks:
            f = t["fields"]
            if want and f.get("status") != want:
                continue
            print(f"{t['id']:8} {f.get('status', '?'):11} {f.get('priority', '?'):3} {f.get('type', '?'):8} {f.get('size', '?'):2} {t['title']}")
        return 0
    if cmd == "next":
        t = pick_next(tasks)
        print(t["id"] if t else "NONE")
        return 0
    if cmd == "ready-count":
        print(len(ready(tasks)))
        return 0
    if cmd == "new-id":
        prefix = tasks[0]["id"].split("-")[0] if tasks else "VS"
        n = max([num(t["id"]) for t in tasks] or [0]) + 1
        print(f"{prefix}-{n:03d}")
        return 0
    if cmd == "set":
        tid, field, value = argv[3], argv[4], " ".join(argv[5:])
        t = next((t for t in tasks if t["id"] == tid), None)
        if t is None:
            print(f"no task {tid}")
            return 1
        end = len(lines)
        later = [x["line"] for x in tasks if x["line"] > t["line"]]
        if later:
            end = min(later)
        for i in range(t["line"] + 1, end):
            m = FIELD_RE.match(lines[i])
            if m and m.group(1) == field:
                lines[i] = f"- {field}: {value}"
                break
        else:
            ins = t["line"] + 1
            for i in range(t["line"] + 1, end):
                if lines[i].startswith("- ") or lines[i].startswith("  - "):
                    ins = i + 1
            lines.insert(ins, f"- {field}: {value}")
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            f.write("\n".join(lines) + "\n")
        print(f"{tid}.{field} = {value}")
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
