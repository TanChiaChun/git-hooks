"""Get unittest options.

- Read from Visual Studio Code settings.json if present.
- Generate defaults if not.
"""

import json
import os
from pathlib import Path


def get_vscode_options(p: Path) -> list[str]:
    """Read from Visual Studio Code settings.json.

    Args:
        p:
            Path to settings.json.

    Returns:
        List of unittest options.

    Raises:
        FileNotFoundError:
            settings.json not found.
        json.JSONDecodeError:
            Error decoding settings.json.
    """
    with p.open(encoding="utf8") as f:
        j = json.load(f)
    options: list[str] = j["python.testing.unittestArgs"]
    return options


def get_unittest_options() -> list[str]:
    """Return list of unittest options.

    - For BATS Test, return 1 module test.py.
    - If error reading Visual Studio Code settings.json, return a set of default
    options.
    """
    if "BATS_TEST_FILENAME" in os.environ:
        test_path = Path(os.environ["BATS_TEST_FILENAME"]).parent

        return ["-v", f"{test_path}/test.py"]

    try:
        vscode_options = get_vscode_options(Path(".vscode", "settings.json"))
    except (FileNotFoundError, json.JSONDecodeError):
        vscode_options = ["-v", "-s", "./tests", "-p", "test*.py"]

    return ["discover"] + vscode_options


def main() -> None:
    """Main function."""
    for option in get_unittest_options():
        print(option)


if __name__ == "__main__":
    main()
