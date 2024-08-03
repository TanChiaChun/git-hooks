import io
import sys
import tempfile
import unittest
from unittest.mock import Mock, mock_open, patch

from git_files_filter import (
    Language,
    filter_git_files,
    is_bash_file,
    is_in_migrations_dir,
    main,
)


class TestModule(unittest.TestCase):
    def setUp(self) -> None:
        self.files = [
            ".env",
            ".gitignore",
            ".vscode/settings.json",
            "LICENSE",
            "README.md",
            "src/bash.sh",
            "src/git_files_filter.py",
            "src/pre-commit",
            "tests/py_test/__init__.py",
            "tests/py_test/test_git_files_filter.py",
            "tests/test_bash.bats",
            "tests/test_pre-commit.bats",
            "mysite/productivity/migrations/0001_initial.py",
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
            "src/git_files_filter.py",
            "tests/py_test/__init__.py",
        ]
        self.assertListEqual(
            expected, filter_git_files(self.files, Language.PYTHON)
        )

    def test_filter_git_files_python_test(self) -> None:
        expected = ["tests/py_test/test_git_files_filter.py"]
        self.assertListEqual(
            expected, filter_git_files(self.files, Language.PYTHON_TEST)
        )

    def test_filter_git_files_markdown(self) -> None:
        expected = ["README.md"]
        self.assertListEqual(
            expected, filter_git_files(self.files, Language.MARKDOWN)
        )

    @patch(
        "git_files_filter.open",
        new=mock_open(read_data="#!/usr/bin/env bash\n"),
    )
    @patch("pathlib.Path.is_file", new=Mock(return_value=True))
    def test_is_bash_file_true(self) -> None:
        self.assertIs(is_bash_file(""), True)

    @patch("git_files_filter.open", new=mock_open(read_data="\n"))
    def test_is_bash_file_false_file(self) -> None:
        self.assertIs(is_bash_file(""), False)

    def test_is_bash_file_false_dir(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdirname:
            self.assertIs(is_bash_file(tmpdirname), False)

    def test_is_in_migrations_dir_true(self) -> None:
        self.assertIs(
            is_in_migrations_dir(
                "mysite/productivity/migrations/0001_initial.py"
            ),
            True,
        )

    def test_is_in_migrations_dir_false_dir_path(self) -> None:
        self.assertIs(
            is_in_migrations_dir("src/git_files_filter.py"),
            False,
        )

    def test_is_in_migrations_dir_false_root_path(self) -> None:
        self.assertIs(
            is_in_migrations_dir("git_files_filter.py"),
            False,
        )

    @patch.object(sys, "argv", new=["", "BASH"])
    @patch("sys.stdout", new_callable=io.StringIO)
    def test_main_bash(self, mock_stdout: io.StringIO) -> None:
        with patch(
            "git_files_filter.get_git_files", new=Mock(return_value=self.files)
        ):
            main()

        self.assertEqual(
            mock_stdout.getvalue(),
            "\n".join(["src/bash.sh", "src/pre-commit", ""]),
        )

    @patch.object(sys, "argv", new=["", "BASH_BOTH"])
    @patch("sys.stdout", new_callable=io.StringIO)
    def test_main_bash_both(self, mock_stdout: io.StringIO) -> None:
        with patch(
            "git_files_filter.get_git_files", new=Mock(return_value=self.files)
        ):
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

    @patch.dict("os.environ", values={"BATS_TMPDIR": ""})
    @patch("sys.stdout", new_callable=io.StringIO)
    def test_main_bats(self, mock_stdout: io.StringIO) -> None:
        main()
        self.assertEqual(mock_stdout.getvalue(), "/test\n")


if __name__ == "__main__":
    unittest.main()
