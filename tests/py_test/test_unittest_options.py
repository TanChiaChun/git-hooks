import io
import json
import logging
import unittest
from pathlib import Path
from unittest.mock import Mock, mock_open, patch

from unittest_options import (
    get_unittest_options,
    get_vscode_options,
    logger,
    main,
)


class BaseFixtureTestCase(unittest.TestCase):
    def setUp(self) -> None:
        self.options = ["-v", "-s", "./tests/tests", "-p", "test*.py"]


class TestGetVscodeOptions(BaseFixtureTestCase):
    def test_pass(self) -> None:
        mock_path = Mock()
        mock_path.open = mock_open(
            read_data=json.dumps({"python.testing.unittestArgs": self.options})
        )

        self.assertListEqual(get_vscode_options(mock_path), self.options)

    def test_file_not_found_error(self) -> None:
        mock_path = Mock()
        mock_path.open.side_effect = FileNotFoundError
        mock_path.resolve.return_value = Path("file")

        with self.assertLogs(logger=logger, level=logging.WARNING) as cm:
            with self.assertRaises(FileNotFoundError):
                get_vscode_options(mock_path)

            self.assertEqual(cm.records[0].getMessage(), "file not found.")

    def test_json_decode_error(self) -> None:
        mock_path = Mock()
        mock_path.open = mock_open(read_data="")
        mock_path.resolve.return_value = Path("file")

        with self.assertLogs(logger=logger, level=logging.WARNING) as cm:
            with self.assertRaises(json.JSONDecodeError):
                get_vscode_options(mock_path)

            self.assertEqual(cm.records[0].getMessage(), "Error decoding file.")

    def test_key_error(self) -> None:
        mock_path = Mock()
        mock_path.open = mock_open(read_data=json.dumps({"key": "value"}))

        with self.assertLogs(logger=logger, level=logging.WARNING) as cm:
            with self.assertRaises(KeyError):
                get_vscode_options(mock_path)

            self.assertEqual(
                cm.records[0].getMessage(),
                "python.testing.unittestArgs key not found.",
            )


class TestGetUnittestOptions(BaseFixtureTestCase):
    def test_pass(self) -> None:
        with patch(
            "unittest_options.get_vscode_options",
            new=Mock(return_value=self.options),
        ):
            expected = ["discover"] + self.options
            self.assertListEqual(get_unittest_options(), expected)

    @patch.dict("os.environ", values={"BATS_TEST_FILENAME": ""})
    def test_bats(self) -> None:
        self.assertListEqual(get_unittest_options(), ["-v", "./test.py"])

    def test_file_not_found_error(self) -> None:
        with patch(
            "unittest_options.get_vscode_options",
            new=Mock(side_effect=FileNotFoundError),
        ):
            self.assertListEqual(
                get_unittest_options(),
                ["discover", "-v", "-s", "./tests", "-p", "test*.py"],
            )


class TestModule(BaseFixtureTestCase):
    @patch("sys.stdout", new_callable=io.StringIO)
    def test_main(self, mock_stdout: io.StringIO) -> None:
        with patch(
            "unittest_options.get_unittest_options",
            new=Mock(return_value=["discover"] + self.options),
        ):
            main()
        self.assertEqual(
            mock_stdout.getvalue(),
            "discover\n-v\n-s\n./tests/tests\n-p\ntest*.py\n",
        )


if __name__ == "__main__":
    unittest.main()
