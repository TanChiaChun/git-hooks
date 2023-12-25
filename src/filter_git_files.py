"""Run git ls-files & filter based on language."""

import re
import subprocess
from enum import Enum
from pathlib import Path


class Language(Enum):
    """Languages with their file extensions."""

    BASH = r".+\.sh"
    BASH_TEST = r".+\.bats"
    PYTHON = r"(?!test).+\.py"
    PYTHON_TEST = r"test.+\.py"


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

    return filtered_files


def get_git_files() -> list[str]:
    """Run git ls-files & return list of files.

    Returns:
        List of files.
    """
    p = subprocess.run(
        ["git", "ls-files"], capture_output=True, check=True, text=True
    )
    return p.stdout.splitlines()


def is_bash_file(file: str) -> bool:
    """Read first line of file, return True if bash is present.

    Args:
        file:
            File to read.

    Returns:
        True if bash is present in first line of file, False if no.
    """
    with open(file, encoding="utf8") as f:
        first_line = f.readline()

    if "bash" in first_line:
        return True

    return False


def main() -> None:
    """Main function."""
    files = get_git_files()


if __name__ == "__main__":
    main()
