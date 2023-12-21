"""Run git ls-files & filter based on language."""

import subprocess
from enum import Enum


class Language(Enum):
    """Languages with their file extensions."""

    BASH = ".sh"
    PYTHON = ".py"


def get_git_files() -> list[str]:
    """Run git ls-files & return list of files.

    Returns:
        List of files.
    """
    p = subprocess.run(
        ["git", "ls-files"], capture_output=True, check=True, text=True
    )
    return p.stdout.split("\n")


def main() -> None:
    """Main function."""
    files = get_git_files()


if __name__ == "__main__":
    main()
