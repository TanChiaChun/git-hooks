"""Get unittest options.

- Read from Visual Studio Code settings.json if present.
- Generate defaults if not.
"""

import json
import logging
import os
from pathlib import Path

logger = logging.getLogger(__name__)


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
    try:
        with p.open(encoding="utf8") as f:
            try:
                j = json.load(f)
            except json.JSONDecodeError:
                logger.warning("Error decoding %s.", p.resolve().as_posix())
                raise

    except FileNotFoundError:
        logger.warning("%s not found.", p.resolve().as_posix())
        raise

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
    logging.basicConfig()

    for option in get_unittest_options():
        print(option)


if __name__ == "__main__":
    main()
