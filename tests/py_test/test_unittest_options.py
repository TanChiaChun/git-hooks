import io
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import Mock, mock_open, patch

from unittest_options import get_unittest_options, get_vscode_options, main


class TestModule(unittest.TestCase):
    def setUp(self) -> None:
        self.options = ["-v", "-s", "./tests/tests", "-p", "test*.py"]
        self.settings_data = json.dumps(
            {"python.testing.unittestArgs": self.options}
        )

    def test_get_vscode_options(self) -> None:
        with patch(
            "unittest_options.open",
            new=mock_open(read_data=self.settings_data),
        ):
            self.assertListEqual(get_vscode_options(Path("")), self.options)

    def test_get_vscode_options_file_not_found_error(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdirname:
            with self.assertRaises(FileNotFoundError):
                get_vscode_options(Path(tmpdirname, "file"))

    @patch("unittest_options.open", new=mock_open(read_data=""))
    def test_get_vscode_options_json_decode_error(self) -> None:
        with self.assertRaises(json.JSONDecodeError):
            get_vscode_options(Path(""))

    def test_get_unittest_options(self) -> None:
        with patch(
            "unittest_options.open",
            new=mock_open(read_data=self.settings_data),
        ):
            expected = ["discover"]
            expected.extend(self.options)
            self.assertListEqual(get_unittest_options(), expected)

    @patch.dict("os.environ", values={"BATS_TEST_FILENAME": ""})
    def test_get_unittest_options_bats(self) -> None:
        self.assertListEqual(get_unittest_options(), ["-v", "./test.py"])

    @patch("unittest_options.open", new=Mock(side_effect=FileNotFoundError))
    def test_get_unittest_options_file_not_found_error(self) -> None:
        self.assertListEqual(
            get_unittest_options(),
            ["discover", "-v", "-s", "./tests", "-p", "test*.py"],
        )

    @patch(
        "json.load",
        new=Mock(side_effect=json.JSONDecodeError("Expecting value", "", 0)),
    )
    def test_get_unittest_options_json_decode_error(self) -> None:
        with patch(
            "unittest_options.open",
            new=mock_open(read_data=self.settings_data),
        ):
            self.assertListEqual(
                get_unittest_options(),
                ["discover", "-v", "-s", "./tests", "-p", "test*.py"],
            )

    @patch("sys.stdout", new_callable=io.StringIO)
    def test_main(self, mock_stdout: io.StringIO) -> None:
        with patch(
            "unittest_options.open",
            new=mock_open(read_data=self.settings_data),
        ):
            main()
        self.assertEqual(
            mock_stdout.getvalue(),
            "discover\n-v\n-s\n./tests/tests\n-p\ntest*.py\n",
        )


if __name__ == "__main__":
    unittest.main()
