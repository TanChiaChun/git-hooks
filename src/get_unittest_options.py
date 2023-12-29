"""Get unittest options.

- Read from Visual Studio Code settings.json if present.
- Generate defaults if not.
"""


import json
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


def main() -> None:
    """Main function."""
    options = ["-v", "-s", "./tests", "-p", "test*.py"]
    p = Path(".vscode/settings.json")
    if p.is_file():
        options = get_vscode_options(p)

    for option in options:
        print(option)


if __name__ == "__main__":
    main()
