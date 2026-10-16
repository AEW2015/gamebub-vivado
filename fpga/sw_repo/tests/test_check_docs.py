"""Unit tests for the GitHub Markdown link checker."""

from __future__ import annotations

import contextlib
import io
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import check_docs  # noqa: E402
import run_host  # noqa: E402


class CheckDocsTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp_dir = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp_dir.cleanup)
        self.root = Path(self.temp_dir.name)
        self.docs = self.root / "gamebub-source" / "docs" / "vivado"
        self.docs.mkdir(parents=True)

    def write_doc(self, content: str, name: str = "README.md") -> Path:
        path = self.docs / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        return path

    def check(self) -> list[str]:
        with contextlib.redirect_stdout(io.StringIO()):
            return check_docs.check(self.root)

    def check_root(self, root: Path) -> list[str]:
        with contextlib.redirect_stdout(io.StringIO()):
            return check_docs.check(root)

    def test_relative_markdown_and_image_targets(self) -> None:
        (self.docs / "guide.md").write_text("Guide\n", encoding="utf-8")
        images = self.docs / "assets"
        images.mkdir()
        (images / "panel.png").write_bytes(b"fixture")
        self.write_doc(
            "[guide](guide.md#overview) ![panel](assets/panel.png) "
            "[web](https://example.invalid) [mail](mailto:docs@example.invalid) [top](#top)"
        )

        self.assertEqual(self.check(), [])

    def test_direct_source_repository_root_is_supported(self) -> None:
        source_root = self.root / "standalone-source"
        docs = source_root / "docs" / "vivado"
        docs.mkdir(parents=True)
        (docs / "target.md").write_text("Target\n", encoding="utf-8")
        (docs / "README.md").write_text("[target](target.md)\n", encoding="utf-8")

        self.assertEqual(self.check_root(source_root), [])

    def test_host_runner_resolves_direct_and_legacy_roots(self) -> None:
        direct_root = self.root / "direct"
        (direct_root / "fpga" / "sw_repo").mkdir(parents=True)
        legacy_root = self.root / "legacy"
        legacy_source = legacy_root / "gamebub-source"
        (legacy_source / "fpga" / "sw_repo").mkdir(parents=True)

        self.assertEqual(run_host._source_root(direct_root), direct_root)
        self.assertEqual(run_host._source_root(legacy_root), legacy_source)

    def test_missing_relative_target_is_reported(self) -> None:
        self.write_doc("[missing](not-here.md)")

        errors = self.check()

        self.assertEqual(len(errors), 1)
        self.assertIn("missing local link target: not-here.md", errors[0])

    def test_absolute_windows_target_is_rejected(self) -> None:
        self.write_doc(r"[private](C:\Users\example\guide.md)")

        errors = self.check()

        self.assertEqual(len(errors), 1)
        self.assertIn("absolute Windows filesystem link", errors[0])

    def test_fences_balance_and_codeblock_pseudo_links_are_ignored(self) -> None:
        (self.docs / "real.md").write_text("Real\n", encoding="utf-8")
        self.write_doc(
            "```text\n"
            "[pseudo missing](no-such-file.md)\n"
            "![pseudo absolute](C:/private/image.png)\n"
            "```\n"
            "[real](real.md)\n"
        )

        self.assertEqual(self.check(), [])

    def test_unclosed_fence_is_reported(self) -> None:
        self.write_doc("~~~tcl\nputs {example}\n")

        errors = self.check()

        self.assertEqual(len(errors), 1)
        self.assertIn("unclosed fenced code block", errors[0])


if __name__ == "__main__":
    unittest.main()
