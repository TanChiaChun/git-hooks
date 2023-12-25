import tempfile
import unittest
from pathlib import Path

from filter_git_files import Language, filter_git_files, is_bash_file


class TestModule(unittest.TestCase):
    def test_filter_git_files(self) -> None:
        files = [
            ".env",
            ".gitignore",
            ".vscode/settings.json",
            "LICENSE",
            "README.md",
            "src/bash.sh",
            "src/filter_git_files.py",
            "src/pre-commit",
            "tests/py_test/__init__.py",
            "tests/py_test/test_filter_git_files.py",
            "tests/test_bash.bats",
            "tests/test_pre-commit.bats",
        ]

        expected = [
            "src/bash.sh",
            "src/pre-commit",
        ]
        self.assertListEqual(expected, filter_git_files(files, Language.BASH))

        expected = [
            "tests/test_bash.bats",
            "tests/test_pre-commit.bats",
        ]
        self.assertListEqual(
            expected, filter_git_files(files, Language.BASH_TEST)
        )

        expected = [
            "src/filter_git_files.py",
            "tests/py_test/__init__.py",
        ]
        self.assertListEqual(expected, filter_git_files(files, Language.PYTHON))

        expected = ["tests/py_test/test_filter_git_files.py"]
        self.assertListEqual(
            expected, filter_git_files(files, Language.PYTHON_TEST)
        )

    def test_is_bash_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdirname:
            file = str(Path(tmpdirname, "pre-commit"))

            with open(file, mode="w", encoding="utf8") as f:
                f.write("#!/usr/bin/env bash\n")
            self.assertTrue(is_bash_file(file))

            with open(file, mode="w", encoding="utf8") as f:
                f.write("\n")
            self.assertFalse(is_bash_file(file))


if __name__ == "__main__":
    unittest.main()
