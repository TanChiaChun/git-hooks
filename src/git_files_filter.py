"""Run git ls-files & filter based on language."""

import argparse
import logging
import os
import subprocess
import sys
from enum import Enum, auto
from pathlib import Path
from typing import Optional

logger = logging.getLogger(__name__)


class Language(Enum):
    """Languages."""

    BASH = auto()
    BASH_TEST = auto()
    PYTHON = auto()
    PYTHON_TEST = auto()


class LanguageChoice(Enum):
    """Choice of Languages."""

    BASH = [Language.BASH]
    BASH_TEST = [Language.BASH_TEST]
    BASH_BOTH = [Language.BASH, Language.BASH_TEST]
    PYTHON = [Language.PYTHON]
    PYTHON_TEST = [Language.PYTHON_TEST]
    PYTHON_BOTH = [Language.PYTHON, Language.PYTHON_TEST]


def filter_git_files(
    git_files: list[Path], language_choice: LanguageChoice
) -> list[Path]:
    """Filter git files by Language choice.

    Args:
        git_files:
            List of git files.
        language_choice:
            `LanguageChoice` Enum.

    Returns:
        List of filtered files.
    """
    return [
        file
        for file in git_files
        if get_file_language(file) in language_choice.value
    ]


def get_file_language(file: Path) -> Optional[Language]:
    """Determine Language of file.

    Args:
        file:
            File path.

    Returns:
        `Language` enum if match, `None` otherwise.
    """
    file_language = None

    if file.suffix:
        match file.suffix:
            case ".sh":
                file_language = Language.BASH
            case ".bats":
                file_language = Language.BASH_TEST
            case ".py":
                if file.name.startswith("test") or file.parts[0].startswith(
                    "test"
                ):
                    file_language = Language.PYTHON_TEST
                elif not is_in_migrations_dir(file):
                    file_language = Language.PYTHON
    else:
        if is_bash_file(file):
            file_language = Language.BASH

    return file_language


def get_git_files() -> list[Path]:
    """Run git ls-files & return list of files.

    Returns:
        List of files.

    Raises:
        FileNotFoundError:
            `git` not found.

        subprocess.CalledProcessError:
            Error running `git ls-file`.
    """
    try:
        p = subprocess.run(
            ["git", "ls-files"], capture_output=True, check=True, text=True
        )
    except FileNotFoundError:
        logger.error("git not found")
        raise
    except subprocess.CalledProcessError:
        logger.error("Error running git ls-file")
        raise

    return [Path(file) for file in p.stdout.splitlines()]


def is_bash_file(file: Path) -> bool:
    """Read first line of file, return True if bash is present.

    Args:
        file:
            File to read.

    Returns:
        True if bash is present in first line of file, False if no.
    """
    if file.is_file():
        with file.open(encoding="utf8") as f:
            first_line = f.readline()

        return "bash" in first_line

    return False


def is_in_migrations_dir(file: Path) -> bool:
    """Check if file is inside a 'migrations' directory.

    E.g. Django generated migration file.

    Args:
        file:
            File path.

    Returns:
        True if file inside 'migrations' directory, False if no.
    """
    return (len(file.parts) > 1) and (file.parts[-2] == "migrations")


def main() -> None:
    """Main function."""
    if "BATS_TMPDIR" in os.environ:
        print(f"{os.environ['BATS_TMPDIR']}/test")
        return

    logging.basicConfig()

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "language_choice",
        choices=[name for name, member in LanguageChoice.__members__.items()],
    )
    args = parser.parse_args()

    try:
        git_files = get_git_files()
    except (FileNotFoundError, subprocess.CalledProcessError):
        sys.exit(1)

    for file in filter_git_files(
        git_files, LanguageChoice[args.language_choice]
    ):
        print(file.as_posix())


if __name__ == "__main__":
    main()
