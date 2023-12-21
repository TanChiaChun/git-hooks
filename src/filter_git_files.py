"""Run git ls-files & filter based on language."""

import subprocess


def main() -> None:
    """Main function."""
    p = subprocess.run(["git", "ls-files"], capture_output=True, check=True)


if __name__ == "__main__":
    main()
