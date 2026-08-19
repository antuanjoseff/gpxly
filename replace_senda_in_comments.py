#!/usr/bin/env python3
"""Substitueix la paraula "senda" (qualsevol majúscula/minúscula) per "STrack Rec"
dins de comentaris (// ... i /* ... */) de tots els fitxers *.dart del projecte.
El codi fora de comentaris (incloent-hi strings) no es toca.
"""

import re
import sys
from pathlib import Path

WORD_RE = re.compile(r"\bsenda\b", re.IGNORECASE)
REPLACEMENT = "STrack Rec"

# Directoris que no s'han d'escanejar (generats/tercers)
EXCLUDED_DIRS = {"build", ".dart_tool", ".git"}


def replace_word(text: str) -> str:
    return WORD_RE.sub(REPLACEMENT, text)


def process_content(content: str) -> tuple[str, bool]:
    result = []
    i = 0
    n = len(content)
    in_string = None
    in_line_comment = False
    in_block_comment = False
    comment_buf: list[str] = []
    changed = False

    def flush_comment():
        nonlocal comment_buf, changed
        original = "".join(comment_buf)
        replaced = replace_word(original)
        if replaced != original:
            changed = True
        result.append(replaced)
        comment_buf = []

    while i < n:
        c = content[i]
        nxt = content[i + 1] if i + 1 < n else ""

        if in_line_comment:
            if c == "\n":
                flush_comment()
                in_line_comment = False
                result.append(c)
            else:
                comment_buf.append(c)
            i += 1
            continue

        if in_block_comment:
            if c == "*" and nxt == "/":
                comment_buf.append(c)
                comment_buf.append(nxt)
                flush_comment()
                in_block_comment = False
                i += 2
            else:
                comment_buf.append(c)
                i += 1
            continue

        if in_string:
            result.append(c)
            if c == "\\" and nxt:
                result.append(nxt)
                i += 2
                continue
            if c == in_string:
                in_string = None
            i += 1
            continue

        if c == "/" and nxt == "/":
            in_line_comment = True
            comment_buf = [c, nxt]
            i += 2
            continue

        if c == "/" and nxt == "*":
            in_block_comment = True
            comment_buf = [c, nxt]
            i += 2
            continue

        if c == "'" or c == '"':
            in_string = c
            result.append(c)
            i += 1
            continue

        result.append(c)
        i += 1

    if in_line_comment or in_block_comment:
        flush_comment()

    return "".join(result), changed


def main():
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
    modified_files = []

    for path in root.rglob("*.dart"):
        if any(part in EXCLUDED_DIRS for part in path.parts):
            continue

        original_content = path.read_text(encoding="utf-8")
        new_content, changed = process_content(original_content)

        if changed:
            path.write_text(new_content, encoding="utf-8")
            modified_files.append(path)

    print(f"Fitxers modificats: {len(modified_files)}")
    for f in modified_files:
        print(f" - {f}")


if __name__ == "__main__":
    main()
