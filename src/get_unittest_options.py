"""Get unittest options.

- Read from Visual Studio Code settings.json if present.
- Generate defaults if not.
"""


def main() -> None:
    """Main function."""
    options = ["-v", "-s", "./tests", "-p", "test*.py"]

    for option in options:
        print(option)


if __name__ == "__main__":
    main()
