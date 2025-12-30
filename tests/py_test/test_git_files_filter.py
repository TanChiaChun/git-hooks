import logging
import os
import subprocess
import sys
from pathlib import Path

import pytest
from pytest_mock import MockerFixture

import git_files_filter


@pytest.fixture(name="files")
def files_fixture() -> list[Path]:
    return [
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


@pytest.mark.parametrize(
    ("language_choice", "expected"),
    [
        (
            git_files_filter.LanguageChoice.PYTHON,
            [Path("src/git_files_filter.py")],
        ),
        (
            git_files_filter.LanguageChoice.PYTHON_BOTH,
            [
                Path("src/git_files_filter.py"),
                Path("tests/py_test/__init__.py"),
                Path("tests/py_test/test_git_files_filter.py"),
            ],
        ),
    ],
)
def test_filter_git_files(
    files: list[Path],
    language_choice: git_files_filter.LanguageChoice,
    expected: list[Path],
) -> None:
    assert git_files_filter.filter_git_files(files, language_choice) == expected


def test_git_files_filter(
    monkeypatch: pytest.MonkeyPatch, files: list[Path], mocker: MockerFixture
) -> None:
    mock_completed_process = mocker.Mock(
        stdout="\n".join([str(file) for file in files]) + "\n"
    )
    monkeypatch.setattr(
        subprocess, "run", lambda *a, **k: mock_completed_process
    )

    assert git_files_filter.get_git_files() == files


@pytest.mark.parametrize(
    ("exception", "expected_exception", "expected_message"),
    [
        (
            subprocess.CalledProcessError(1, ["git", "ls-file"]),
            subprocess.CalledProcessError,
            "Error running git ls-file",
        ),
        (FileNotFoundError, FileNotFoundError, "git not found"),
    ],
)
def test_git_files_filter_except(
    monkeypatch: pytest.MonkeyPatch,
    caplog: pytest.LogCaptureFixture,
    mocker: MockerFixture,
    exception: Exception,
    expected_exception: type[Exception],
    expected_message: str,
) -> None:
    monkeypatch.setattr(subprocess, "run", mocker.Mock(side_effect=exception))

    with pytest.raises(expected_exception):
        git_files_filter.get_git_files()

    assert caplog.record_tuples == [
        ("git_files_filter", logging.ERROR, expected_message)
    ]


@pytest.mark.parametrize(
    ("file_content", "expected"),
    [
        ("#!/usr/bin/env bash\n", True),
        ("\n", False),
    ],
)
def test_is_bash_file(
    tmp_path: Path, file_content: str, expected: bool
) -> None:
    file = tmp_path / "test.sh"
    file.write_text(file_content)

    assert git_files_filter.is_bash_file(file) == expected


def test_is_bash_file_false_dir() -> None:
    assert not git_files_filter.is_bash_file(Path(""))


@pytest.mark.parametrize(
    ("file", "expected"),
    [
        ("mysite/productivity/migrations/0001_initial.py", True),
        ("src/git_files_filter.py", False),
        ("git_files_filter.py", False),
    ],
)
def test_is_in_migrations_dir(file: str, expected: bool) -> None:
    assert git_files_filter.is_in_migrations_dir(Path(file)) == expected


class TestGetFileLanguage:
    @pytest.mark.parametrize(
        ("file", "expected"),
        [
            (Path("file.bats"), git_files_filter.Language.BASH_TEST),
            (Path("file.py"), git_files_filter.Language.PYTHON),
            (Path("migrations", "file.py"), None),
            (Path("test", "file.py"), git_files_filter.Language.PYTHON_TEST),
            (Path("test_file.py"), git_files_filter.Language.PYTHON_TEST),
            (Path("file.sh"), git_files_filter.Language.BASH),
        ],
    )
    def test_get_file_language(
        self, file: Path, expected: git_files_filter.Language
    ) -> None:
        assert git_files_filter.get_file_language(file) == expected

    def test_no_suffix_bash(self, monkeypatch: pytest.MonkeyPatch) -> None:
        monkeypatch.setattr(git_files_filter, "is_bash_file", lambda f: True)

        assert (
            git_files_filter.get_file_language(Path("file"))
            == git_files_filter.Language.BASH
        )
        assert (
            git_files_filter.get_file_language(Path(".file"))
            == git_files_filter.Language.BASH
        )

    def test_none(self, monkeypatch: pytest.MonkeyPatch) -> None:
        monkeypatch.setattr(git_files_filter, "is_bash_file", lambda f: False)

        assert git_files_filter.get_file_language(Path("file")) is None


class TestMain:
    def test_bash(
        self,
        monkeypatch: pytest.MonkeyPatch,
        capsys: pytest.CaptureFixture[str],
        files: list[Path],
    ) -> None:
        monkeypatch.setattr(sys, "argv", ["", "BASH"])
        monkeypatch.setattr(git_files_filter, "get_git_files", lambda: files)
        monkeypatch.setattr(
            git_files_filter,
            "is_bash_file",
            lambda f: f == Path("src/pre-commit"),
        )

        git_files_filter.main()

        assert capsys.readouterr().out == "\n".join(
            ["src/bash.sh", "src/pre-commit", ""]
        )

    def test_bats(
        self,
        monkeypatch: pytest.MonkeyPatch,
        capsys: pytest.CaptureFixture[str],
    ) -> None:
        monkeypatch.setitem(os.environ, "BATS_TMPDIR", "")

        git_files_filter.main()

        assert capsys.readouterr().out == "/test\n"

    def test_called_process_error(
        self,
        monkeypatch: pytest.MonkeyPatch,
        mocker: MockerFixture,
    ) -> None:
        monkeypatch.setattr(sys, "argv", ["", "BASH"])
        mock_get_git_files = mocker.Mock(
            side_effect=subprocess.CalledProcessError(1, ["git", "ls-file"])
        )
        monkeypatch.setattr(
            git_files_filter, "get_git_files", mock_get_git_files
        )

        with pytest.raises(SystemExit):
            git_files_filter.main()
