import unittest

from filter_git_files import Language, filter_git_files


class TestModule(unittest.TestCase):
    def test_filter_git_files(self) -> None:
        files = [
            ".env",
            ".gitignore",
            ".vscode/settings.json",
            "LICENSE",
            "README.md",
            "src/bash.sh",
            "src/filter_git_files.py",
            "src/pre-commit",
            "tests/py_test/__init__.py",
            "tests/py_test/test_filter_git_files.py",
            "tests/test_bash.bats",
            "tests/test_pre-commit.bats",
        ]

        expected = ["src/bash.sh"]
        self.assertListEqual(expected, filter_git_files(files, Language.BASH))

        expected = [
            "src/filter_git_files.py",
            "tests/py_test/__init__.py",
            "tests/py_test/test_filter_git_files.py",
        ]
        self.assertListEqual(expected, filter_git_files(files, Language.PYTHON))


if __name__ == "__main__":
    unittest.main()
