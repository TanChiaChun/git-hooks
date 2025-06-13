"""Get unittest options.

- Read from Visual Studio Code settings.json if present.
- Generate defaults if not.
"""

import json
import logging
import os
from pathlib import Path

logger = logging.getLogger(__name__)


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
    except (FileNotFoundError, json.JSONDecodeError, KeyError):
        vscode_options = ["-v", "-s", "./tests", "-p", "test*.py"]

    return ["discover"] + vscode_options


def get_vscode_options(settings_path: Path) -> list[str]:
    """Read from Visual Studio Code settings.json.

    Args:
        settings_path:
            Path to settings.json.

    Returns:
        List of unittest options.

    Raises:
        FileNotFoundError:
            settings.json not found.
        json.JSONDecodeError:
            Error decoding settings.json.
        KeyError:
            python.testing.unittestArgs key not found.
    """
    try:
        with settings_path.open(encoding="utf8") as f:
            try:
                settings = json.load(f)
            except json.JSONDecodeError:
                logger.warning(
                    "Error decoding %s.", settings_path.resolve().as_posix()
                )
                raise

    except FileNotFoundError:
        logger.warning("%s not found.", settings_path.resolve().as_posix())
        raise

    try:
        options: list[str] = settings["python.testing.unittestArgs"]
    except KeyError:
        logger.warning("python.testing.unittestArgs key not found.")
        raise

    return options


def main() -> None:
    """Main function."""
    logging.basicConfig()

    for option in get_unittest_options():
        print(option)


if __name__ == "__main__":
    main()
