import io
import logging
import subprocess
import sys
import unittest
from pathlib import Path
from unittest.mock import Mock, mock_open, patch

from git_files_filter import (
    Language,
    LanguageChoice,
    filter_git_files,
    get_file_language,
    get_git_files,
    is_bash_file,
    is_in_migrations_dir,
    logger,
    main,
)


class BaseFixtureTestCase(unittest.TestCase):
    def setUp(self) -> None:
        self.files = [
            Path(".env"),
            Path(".gitignore"),
            Path(".vscode/settings.json"),
            Path("LICENSE"),
            Path("README.md"),
            Path("src/bash.sh"),
            Path("src/git_files_filter.py"),
            Path("src/pre-commit"),
            Path("tests/py_test/__init__.py"),
            Path("tests/py_test/test_git_files_filter.py"),
            Path("tests/test_bash.bats"),
            Path("tests/test_pre-commit.bats"),
            Path("mysite/productivity/migrations/0001_initial.py"),
        ]


class TestGetGitFiles(BaseFixtureTestCase):
    def test_pass(self) -> None:
        mock_completed_process = Mock(
            stdout="\n".join([str(file) for file in self.files]) + "\n"
        )
        with patch(
            "subprocess.run", new=Mock(return_value=mock_completed_process)
        ):
            self.assertListEqual(get_git_files(), self.files)

    @patch("subprocess.run", new=Mock(side_effect=FileNotFoundError))
    def test_git_not_found(self) -> None:
        with self.assertLogs(logger=logger, level=logging.ERROR) as cm:
            with self.assertRaises(FileNotFoundError):
                get_git_files()

            self.assertEqual(cm.records[0].getMessage(), "git not found")

    def test_called_process_error(self) -> None:
        mock_process = Mock(
            side_effect=subprocess.CalledProcessError(1, ["git", "ls-file"])
        )
        with patch("subprocess.run", new=mock_process), self.assertLogs(
            logger=logger, level=logging.ERROR
        ) as cm:
            with self.assertRaises(subprocess.CalledProcessError):
                get_git_files()

            self.assertEqual(
                cm.records[0].getMessage(), "Error running git ls-file"
            )


class TestGetFileLanguage(unittest.TestCase):
    @patch("git_files_filter.is_bash_file", new=Mock(return_value=False))
    def test_none(self) -> None:
        self.assertIs(get_file_language(Path("file")), None)

    def test_sh(self) -> None:
        self.assertIs(get_file_language(Path("file.sh")), Language.BASH)

    def test_bats(self) -> None:
        self.assertIs(get_file_language(Path("file.bats")), Language.BASH_TEST)

    def test_md(self) -> None:
        self.assertIs(get_file_language(Path("file.md")), Language.MARKDOWN)

    def test_py_test_file(self) -> None:
        self.assertIs(
            get_file_language(Path("test_file.py")), Language.PYTHON_TEST
        )

    def test_py_test_dir(self) -> None:
        self.assertIs(
            get_file_language(Path("test", "file.py")), Language.PYTHON_TEST
        )

    def test_py(self) -> None:
        self.assertIs(get_file_language(Path("file.py")), Language.PYTHON)

    def test_py_migrations(self) -> None:
        self.assertIs(get_file_language(Path("migrations", "file.py")), None)

    @patch("git_files_filter.is_bash_file", new=Mock(return_value=True))
    def test_no_suffix_bash(self) -> None:
        self.assertIs(get_file_language(Path("file")), Language.BASH)
        self.assertIs(get_file_language(Path(".file")), Language.BASH)


class TestIsBashFile(unittest.TestCase):
    def test_true(self) -> None:
        mock_file = Mock()
        mock_file.is_file.return_value = True
        mock_file.open = mock_open(read_data="#!/usr/bin/env bash\n")

        self.assertIs(is_bash_file(mock_file), True)

    def test_false_file(self) -> None:
        mock_file = Mock()
        mock_file.is_file.return_value = True
        mock_file.open = mock_open(read_data="\n")

        self.assertIs(is_bash_file(mock_file), False)

    def test_false_dir(self) -> None:
        self.assertIs(is_bash_file(Path("")), False)


class TestIsInMigrationsDir(unittest.TestCase):
    def test_true(self) -> None:
        self.assertIs(
            is_in_migrations_dir(
                Path("mysite/productivity/migrations/0001_initial.py")
            ),
            True,
        )

    def test_false_dir_path(self) -> None:
        self.assertIs(
            is_in_migrations_dir(Path("src/git_files_filter.py")),
            False,
        )

    def test_false_root_path(self) -> None:
        self.assertIs(
            is_in_migrations_dir(Path("git_files_filter.py")),
            False,
        )


class TestMain(BaseFixtureTestCase):
    @patch.object(sys, "argv", new=["", "BASH"])
    @patch("sys.stdout", new_callable=io.StringIO)
    def test_bash(self, mock_stdout: io.StringIO) -> None:
        mock_is_bash_file = Mock(
            side_effect=lambda x: x == Path("src/pre-commit")
        )
        with patch(
            "git_files_filter.get_git_files", new=Mock(return_value=self.files)
        ), patch("git_files_filter.is_bash_file", new=mock_is_bash_file):
            main()

        self.assertEqual(
            mock_stdout.getvalue(),
            "\n".join(["src/bash.sh", "src/pre-commit", ""]),
        )

    @patch.dict("os.environ", values={"BATS_TMPDIR": ""})
    @patch("sys.stdout", new_callable=io.StringIO)
    def test_bats(self, mock_stdout: io.StringIO) -> None:
        main()
        self.assertEqual(mock_stdout.getvalue(), "/test\n")

    @patch.object(sys, "argv", new=["", "BASH"])
    def test_called_process_error(self) -> None:
        mock_get_git_files = Mock(
            side_effect=subprocess.CalledProcessError(1, ["git", "ls-file"])
        )
        with patch("git_files_filter.get_git_files", new=mock_get_git_files):
            with self.assertRaises(SystemExit):
                main()


class TestModule(BaseFixtureTestCase):
    def test_filter_git_files_python(self) -> None:
        expected = [Path("src/git_files_filter.py")]
        self.assertListEqual(
            filter_git_files(self.files, LanguageChoice.PYTHON), expected
        )

    def test_filter_git_files_python_both(self) -> None:
        expected = [
            Path("src/git_files_filter.py"),
            Path("tests/py_test/__init__.py"),
            Path("tests/py_test/test_git_files_filter.py"),
        ]
        self.assertListEqual(
            filter_git_files(self.files, LanguageChoice.PYTHON_BOTH), expected
        )


if __name__ == "__main__":
    unittest.main()
