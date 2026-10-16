#!/usr/bin/env python3
"""Check local Markdown links and fenced code in docs/vivado."""

from __future__ import annotations

import re
import sys
from pathlib import Path, PureWindowsPath
from urllib.parse import unquote, urlsplit


_FENCE = re.compile(r"^ {0,3}(`{3,}|~{3,})(.*)$")
_LINK = re.compile(
    r"!?\[[^\]]*\]\(\s*(?:<([^>\n]*)>|((?:\\.|[^()\s]|\([^()]*\))+))"
)
_WINDOWS_ABSOLUTE = re.compile(r"^(?:[A-Za-z]:[\\/]|\\\\|//)")


def _markdown_files(docs_root: Path) -> list[Path]:
    return sorted(path for path in docs_root.rglob("*.md") if path.is_file())


def _source_root(root: Path) -> Path:
    """Accept either the source checkout root or its legacy parent workspace."""
    if (root / "docs" / "vivado").is_dir():
        return root
    return root / "gamebub-source"


def _check_file(path: Path, root: Path) -> tuple[int, list[str]]:
    """Return local-link count and diagnostics for one Markdown file."""
    errors: list[str] = []
    local_links = 0
    fence: tuple[str, int] | None = None

    for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        fence_match = _FENCE.match(line)
        if fence is not None:
            if (
                fence_match
                and fence_match.group(1)[0] == fence[0]
                and len(fence_match.group(1)) >= fence[1]
                and not fence_match.group(2).strip()
            ):
                fence = None
            continue

        if fence_match:
            marker = fence_match.group(1)
            info = fence_match.group(2)
            if marker[0] == "~" or "`" not in info:
                fence = (marker[0], len(marker))
                continue

        for match in _LINK.finditer(line):
            target = match.group(1) if match.group(1) is not None else match.group(2)
            target = target.replace("\\ ", " ").strip()
            if not target or target.startswith("#"):
                continue

            if _WINDOWS_ABSOLUTE.match(target) or PureWindowsPath(target).is_absolute():
                errors.append(
                    f"{path.relative_to(root)}:{line_number}: absolute Windows filesystem link: {target}"
                )
                continue

            parsed = urlsplit(target)
            if parsed.scheme.lower() in {"http", "https", "mailto"}:
                continue

            local_target = unquote(parsed.path)
            if not local_target:
                continue
            if PureWindowsPath(local_target).is_absolute():
                errors.append(
                    f"{path.relative_to(root)}:{line_number}: absolute Windows filesystem link: {target}"
                )
                continue
            if Path(local_target).is_absolute():
                errors.append(
                    f"{path.relative_to(root)}:{line_number}: absolute filesystem link: {target}"
                )
                continue

            local_links += 1
            resolved = (path.parent / Path(local_target)).resolve()
            if not resolved.exists():
                errors.append(
                    f"{path.relative_to(root)}:{line_number}: missing local link target: {target}"
                )

    if fence is not None:
        errors.append(f"{path.relative_to(root)}: unclosed fenced code block")
    return local_links, errors


def check(root: str | Path) -> list[str]:
    """Check docs/vivado under a repository root; return any diagnostics."""
    root_path = _source_root(Path(root).resolve())
    docs_root = root_path / "docs" / "vivado"
    if not docs_root.is_dir():
        return [f"documentation directory not found: {docs_root}"]

    docs = _markdown_files(docs_root)
    links = 0
    errors: list[str] = []
    for doc in docs:
        count, file_errors = _check_file(doc, root_path)
        links += count
        errors.extend(file_errors)

    print(f"Checked {len(docs)} Markdown files and {links} local links in {docs_root}.")
    return errors


def main() -> int:
    repo_root = Path(__file__).resolve().parents[3]
    errors = check(repo_root)
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)
    if errors:
        print(f"Documentation check found {len(errors)} issue(s).", file=sys.stderr)
        return 1
    print("Documentation check passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
