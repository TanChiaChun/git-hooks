"""Run git ls-files & filter based on language."""

import re
import subprocess
from enum import Enum
from pathlib import Path


class Language(Enum):
    """Languages with their file extensions."""

    BASH = r".+\.sh"
    PYTHON = r".+\.py"


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
    return [file for file in files if re.match(language.value, Path(file).name)]


def get_git_files() -> list[str]:
    """Run git ls-files & return list of files.

    Returns:
        List of files.
    """
    p = subprocess.run(
        ["git", "ls-files"], capture_output=True, check=True, text=True
    )
    return p.stdout.splitlines()


def main() -> None:
    """Main function."""
    files = get_git_files()


if __name__ == "__main__":
    main()
