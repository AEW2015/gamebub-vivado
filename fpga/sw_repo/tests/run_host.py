#!/usr/bin/env python3
"""Compile host-compatible drivers and run any driver-local C tests."""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
import uuid
from pathlib import Path


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[3]


def _source_root(root: Path) -> Path:
    """Accept a source checkout root or its legacy parent workspace."""
    if (root / "fpga" / "sw_repo").is_dir():
        return root
    return root / "gamebub-source"


def _find_gcc() -> Path | None:
    if os.name == "nt":
        preferred = Path("C:/msys64/ucrt64/bin/gcc.exe")
        if preferred.is_file():
            return preferred
    discovered = shutil.which("gcc")
    return Path(discovered).resolve() if discovered else None


def _run(command: list[str], env: dict[str, str], cwd: Path) -> bool:
    print("+ " + subprocess.list2cmdline(command))
    result = subprocess.run(command, cwd=cwd, env=env, check=False)
    return result.returncode == 0


def _test_sources(driver: Path) -> list[Path]:
    tests = driver / "tests"
    if not tests.is_dir():
        return []
    return sorted(path for path in tests.rglob("test_*.c") if path.is_file())


def _link_sources(sources: list[Path], tests: list[Path]) -> list[Path]:
    """Avoid linking generated config tables when a fixture supplies them."""
    test_text = "\n".join(test.read_text(encoding="utf-8") for test in tests)
    generated: set[Path] = set()
    for source in sources:
        if not source.name.endswith("_g.c"):
            continue
        text = source.read_text(encoding="utf-8")
        match = re.search(r"^\s*\w+\s+(\w+_ConfigTable)\s*\[\s*\]", text, re.MULTILINE)
        if match and match.group(1) in test_text:
            generated.add(source)
    return [source for source in sources if source not in generated]


def _include_args(driver: Path, test: Path | None) -> list[str]:
    include_dirs = [
        Path(__file__).resolve().parent / "mock_include",
        driver / "src",
    ]
    if test is not None:
        include_dirs.extend((test.parent, driver / "tests" / "include"))
    args: list[str] = []
    seen: set[Path] = set()
    for include_dir in include_dirs:
        resolved = include_dir.resolve()
        if resolved.is_dir() and resolved not in seen:
            args.extend(("-I", str(resolved)))
            seen.add(resolved)
    return args


def run(root: Path, output_dir: Path, gcc: Path) -> int:
    repo_root = _source_root(root.resolve())
    if not output_dir.is_absolute():
        output_dir = repo_root / output_dir
    sw_repo = repo_root / "fpga" / "sw_repo"
    drivers_root = sw_repo / "drivers"
    if not drivers_root.is_dir():
        print(f"ERROR: drivers directory not found: {drivers_root}", file=sys.stderr)
        return 2
    if output_dir.exists():
        print(f"ERROR: output directory already exists: {output_dir}", file=sys.stderr)
        return 2
    output_dir.mkdir(parents=True)

    gcc = gcc.resolve()
    env = os.environ.copy()
    env["PATH"] = str(gcc.parent) + os.pathsep + env.get("PATH", "")
    common_flags = ["-std=c11", "-Wall", "-Wextra", "-Werror"]
    failures = 0
    driver_count = 0

    for driver in sorted(path for path in drivers_root.iterdir() if path.is_dir()):
        sources = sorted(path for path in (driver / "src").glob("*.c") if path.is_file())
        if not sources:
            continue
        driver_count += 1
        tests = _test_sources(driver)
        print(f"[{driver.name}] {len(sources)} source file(s)")
        for source in sources:
            object_path = output_dir / driver.name / (source.stem + ".o")
            object_path.parent.mkdir(parents=True, exist_ok=True)
            command = [
                str(gcc),
                *common_flags,
                "-I",
                str((Path(__file__).resolve().parent / "mock_include")),
                "-I",
                str((driver / "src").resolve()),
                "-c",
                str(source.resolve()),
                "-o",
                str(object_path),
            ]
            if not _run(command, env, repo_root):
                print(f"FAIL compile {source.relative_to(repo_root)}")
                failures += 1

        if not tests:
            print(f"NOT RUN {driver.name}: no tests/test_*.c entrypoint found")
            continue
        link_sources = _link_sources(sources, tests)
        for test in tests:
            test_name = test.relative_to(driver).with_suffix("").as_posix().replace("/", "_")
            binary = output_dir / driver.name / test_name
            if os.name == "nt":
                binary = binary.with_suffix(".exe")
            command = [
                str(gcc),
                *common_flags,
                *_include_args(driver, test),
                *(str(source.resolve()) for source in link_sources),
                str(test.resolve()),
                "-o",
                str(binary),
            ]
            if not _run(command, env, repo_root):
                print(f"FAIL build test {test.relative_to(repo_root)}")
                failures += 1
                continue
            if not _run([str(binary)], env, repo_root):
                print(f"FAIL run test {test.relative_to(repo_root)}")
                failures += 1
            else:
                print(f"PASS {test.relative_to(repo_root)}")

    print(
        f"Host driver run: {driver_count} driver(s), output {output_dir}; "
        f"{failures} failure(s)."
    )
    return 1 if failures else 0


def main() -> int:
    repo_root = _repo_root()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output-dir",
        type=Path,
        help="new output directory (must not already exist); defaults to a fresh temporary directory",
    )
    arguments = parser.parse_args()
    if arguments.output_dir is None:
        output_dir = Path(tempfile.gettempdir()) / f"gamebub-host-drivers-{uuid.uuid4().hex}"
    else:
        output_dir = arguments.output_dir
        if not output_dir.is_absolute():
            output_dir = repo_root / output_dir

    gcc = _find_gcc()
    if gcc is None:
        print(
            "ERROR: gcc not found (Windows preference: C:/msys64/ucrt64/bin/gcc.exe)",
            file=sys.stderr,
        )
        return 2
    print(f"Using GCC: {gcc}")
    return run(repo_root, output_dir, gcc)


if __name__ == "__main__":
    raise SystemExit(main())
