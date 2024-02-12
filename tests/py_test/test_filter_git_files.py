import io
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock, patch

from filter_git_files import Language, filter_git_files, is_bash_file, main


class TestModule(unittest.TestCase):
    def setUp(self) -> None:
        self.files = [
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

    def test_filter_git_files_bash(self) -> None:
        expected = [
            "src/bash.sh",
            "src/pre-commit",
        ]
        self.assertListEqual(
            expected, filter_git_files(self.files, Language.BASH)
        )

    def test_filter_git_files_bash_test(self) -> None:
        expected = [
            "tests/test_bash.bats",
            "tests/test_pre-commit.bats",
        ]
        self.assertListEqual(
            expected, filter_git_files(self.files, Language.BASH_TEST)
        )

    def test_filter_git_files_python(self) -> None:
        expected = [
            "src/filter_git_files.py",
            "tests/py_test/__init__.py",
        ]
        self.assertListEqual(
            expected, filter_git_files(self.files, Language.PYTHON)
        )

    def test_filter_git_files_python_test(self) -> None:
        expected = ["tests/py_test/test_filter_git_files.py"]
        self.assertListEqual(
            expected, filter_git_files(self.files, Language.PYTHON_TEST)
        )

    def test_filter_git_files_markdown(self) -> None:
        expected = ["README.md"]
        self.assertListEqual(
            expected, filter_git_files(self.files, Language.MARKDOWN)
        )

    def test_is_bash_file_true(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdirname:
            file = str(Path(tmpdirname, "pre-commit"))

            with open(file, mode="w", encoding="utf8") as f:
                f.write("#!/usr/bin/env bash\n")
            self.assertIs(is_bash_file(file), True)

    def test_is_bash_file_false_file(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdirname:
            file = str(Path(tmpdirname, "pre-commit"))

            with open(file, mode="w", encoding="utf8") as f:
                f.write("\n")
            self.assertIs(is_bash_file(file), False)

    def test_is_bash_file_false_dir(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdirname:
            self.assertIs(is_bash_file(tmpdirname), False)

    def test_main_bash(self) -> None:
        patcher_get_git_files = patch(
            "filter_git_files.get_git_files",
            new=Mock(return_value=self.files),
        )
        patcher_get_git_files.start()

        with patch("sys.stdout", new_callable=io.StringIO) as mock_stdout:
            patcher_sys_argv = patch.object(sys, "argv", new=["", "BASH"])
            patcher_sys_argv.start()

            main()
            self.assertEqual(
                mock_stdout.getvalue(),
                "\n".join(["src/bash.sh", "src/pre-commit", ""]),
            )

            patcher_sys_argv.stop()

        patcher_get_git_files.stop()

    def test_main_bash_both(self) -> None:
        patcher_get_git_files = patch(
            "filter_git_files.get_git_files",
            new=Mock(return_value=self.files),
        )
        patcher_get_git_files.start()

        with patch("sys.stdout", new_callable=io.StringIO) as mock_stdout:
            patcher_sys_argv = patch.object(sys, "argv", new=["", "BASH_BOTH"])
            patcher_sys_argv.start()

            main()
            self.assertEqual(
                mock_stdout.getvalue(),
                "\n".join(
                    [
                        "src/bash.sh",
                        "src/pre-commit",
                        "tests/test_bash.bats",
                        "tests/test_pre-commit.bats",
                        "",
                    ]
                ),
            )

            patcher_sys_argv.stop()

        patcher_get_git_files.stop()

    @patch.dict("os.environ", values={"BATS_TMPDIR": ""})
    @patch("sys.stdout", new_callable=io.StringIO)
    def test_main_bats(self, mock_stdout: io.StringIO) -> None:
        main()
        self.assertEqual(mock_stdout.getvalue(), "/test\n")


if __name__ == "__main__":
    unittest.main()
