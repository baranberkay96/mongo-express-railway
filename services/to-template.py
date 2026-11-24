"""Build the Mongo Express start command in template.json from
mongo-express/me-start.sh.

    python3 to-template.py            # print it
    python3 to-template.py --check    # exit 1 if template.json differs
    python3 to-template.py --write    # update template.json in place

The script is joined into one line (comments and blank lines dropped, lines
joined with "; " unless they end in then/do/else) and wrapped as
/bin/bash -c '<script>' me-start.
"""
import json
import pathlib
import sys

HERE = pathlib.Path(__file__).resolve().parent
TEMPLATE = HERE.parent / "template.json"
SERVICE = "Mongo Express"
SCRIPT = HERE / "mongo-express" / "me-start.sh"
OPENERS = ("then", "do", "else")


def one_line() -> str:
    lines = []
    for raw in SCRIPT.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if "'" in line or "\\" in line:
            raise SystemExit(f"single quote or backslash not allowed: {line}")
        lines.append(line)
    out = ""
    for i, line in enumerate(lines):
        out += line
        if i < len(lines) - 1:
            out += " " if line.split()[-1] in OPENERS else "; "
    return f"/bin/bash -c '{out}' me-start"


def main() -> int:
    command = one_line()
    if "--write" not in sys.argv and "--check" not in sys.argv:
        print(command)
        return 0
    template = json.loads(TEMPLATE.read_text(encoding="utf-8"))
    service = template["services"][SERVICE]
    if "--write" in sys.argv:
        service["startCommand"] = command
        TEMPLATE.write_text(json.dumps(template, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print("template.json updated")
        return 0
    ok = service["startCommand"] == command
    print("OK" if ok else "out of date; run with --write")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
