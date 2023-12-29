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
    """
    with open(p, encoding="utf8") as f:
        j = json.load(f)
    options: list[str] = j["python.testing.unittestArgs"]
    return options


def get_unittest_options() -> list[str]:
    """Return list of unittest options."""
    options = []
    settings_path = Path(".vscode/settings.json")

    if "BATS_TEST_FILENAME" in os.environ:
        test_path = Path(os.environ["BATS_TEST_FILENAME"]).parent
        options.extend(["-v", f"{test_path}/test.py"])
    elif settings_path.is_file():
        options.append("discover")
        options.extend(get_vscode_options(settings_path))
    else:
        options.extend(["discover", "-v", "-s", "./tests", "-p", "test*.py"])

    return options


def main() -> None:
    """Main function."""
    for option in get_unittest_options():
        print(option)


if __name__ == "__main__":
    main()
