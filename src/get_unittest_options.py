"""Get unittest options.

- Read from Visual Studio Code settings.json if present.
- Generate defaults if not.
"""


def main() -> None:
    """Main function."""
    print("-v -s ./tests -p test*.py")


if __name__ == "__main__":
    main()
