"""Run git ls-files & filter based on language."""

import argparse
import logging
import os
import re
import subprocess
import sys
from enum import Enum
from pathlib import Path

logger = logging.getLogger(__name__)


class Language(Enum):
    """Languages with their file extensions."""

    BASH = r".+\.sh$"
    BASH_TEST = r".+\.bats$"
    PYTHON = r"(?!test).+\.py$"
    PYTHON_TEST = r"test.+\.py$"
    MARKDOWN = r".+\.md$"


class LanguageChoice(Enum):
    """Choice of Languages."""

    BASH = [Language.BASH]
    BASH_TEST = [Language.BASH_TEST]
    BASH_BOTH = [Language.BASH, Language.BASH_TEST]
    PYTHON = [Language.PYTHON]
    PYTHON_TEST = [Language.PYTHON_TEST]
    PYTHON_BOTH = [Language.PYTHON, Language.PYTHON_TEST]
    MARKDOWN = [Language.MARKDOWN]


def filter_git_files(files: list[str], language: Language) -> list[str]:
    """Filter git files by language.

    Args:
        files:
            List of git files.
        language:
            Language enum.

    Returns:
        List of filtered files.
    """
    filtered_files = [
        file for file in files if re.match(language.value, Path(file).name)
    ]

    if language is Language.BASH:
        files_no_extension = [
            file for file in files if "." not in Path(file).name
        ]
        filtered_files.extend(
            [file for file in files_no_extension if is_bash_file(file)]
        )
    elif language is Language.PYTHON:
        filtered_files = [
            file for file in filtered_files if not is_in_migrations_dir(file)
        ]

    return filtered_files


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


def is_bash_file(file: str) -> bool:
    """Read first line of file, return True if bash is present.

    Args:
        file:
            File to read.

    Returns:
        True if bash is present in first line of file, False if no.
    """
    if Path(file).is_file():
        with open(file, encoding="utf8") as f:
            first_line = f.readline()

        if "bash" in first_line:
            return True

    return False


def is_in_migrations_dir(file: str) -> bool:
    """Check if file is inside a 'migrations' directory.

    E.g. Django generated migration file.

    Args:
        file:
            File path.

    Returns:
        True if file inside 'migrations' directory, False if no.
    """
    path_parts = Path(file).parts

    if (len(path_parts) > 1) and (path_parts[-2] == "migrations"):
        return True

    return False


def print_filtered_files(
    git_files: list[Path], language_choice: LanguageChoice
) -> None:
    """Print filtered Git files.

    Args:
        git_files:
            List of git files.
        language_choice:
            `LanguageChoice` Enum.
    """
    files = [str(file) for file in git_files]
    filtered_files = []
    for language in language_choice.value:
        filtered_files.extend(filter_git_files(files, language))

    for file in filtered_files:
        print(file)


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

    print_filtered_files(git_files, LanguageChoice[args.language_choice])


if __name__ == "__main__":
    main()
