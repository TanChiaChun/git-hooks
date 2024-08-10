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
        path_mock = Mock()
        path_mock.open = mock_open(read_data=self.settings_data)

        self.assertListEqual(get_vscode_options(path_mock), self.options)

    def test_get_vscode_options_file_not_found_error(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdirname:
            p = Path(tmpdirname, "file")
            with self.assertRaises(FileNotFoundError), self.assertLogs(
                "unittest_options", "WARNING"
            ) as cm:
                get_vscode_options(p)

                self.assertEqual(
                    cm.records[0].getMessage(),
                    f"{p.resolve().as_posix()} not found.",
                )

    def test_get_vscode_options_json_decode_error(self) -> None:
        path_mock = Mock()
        path_mock.open = mock_open(read_data="")
        path_mock.resolve.return_value = Path("file")

        with self.assertRaises(json.JSONDecodeError), self.assertLogs(
            "unittest_options", "WARNING"
        ) as cm:
            get_vscode_options(path_mock)

            self.assertEqual(cm.records[0].getMessage(), "Error decoding file.")

    def test_get_vscode_options_key_error(self) -> None:
        path_mock = Mock()
        path_mock.open = mock_open(read_data=json.dumps({"key": "value"}))

        with self.assertRaises(KeyError), self.assertLogs(
            "unittest_options", "WARNING"
        ) as cm:
            get_vscode_options(path_mock)

            self.assertEqual(
                cm.records[0].getMessage(),
                "python.testing.unittestArgs key not found.",
            )

    def test_get_unittest_options(self) -> None:
        with patch(
            "pathlib.Path.open",
            new=mock_open(read_data=self.settings_data),
        ):
            expected = ["discover"]
            expected.extend(self.options)
            self.assertListEqual(get_unittest_options(), expected)

    @patch.dict("os.environ", values={"BATS_TEST_FILENAME": ""})
    def test_get_unittest_options_bats(self) -> None:
        self.assertListEqual(get_unittest_options(), ["-v", "./test.py"])

    @patch("pathlib.Path.open", new=Mock(side_effect=FileNotFoundError))
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
            "pathlib.Path.open",
            new=mock_open(read_data=self.settings_data),
        ):
            main()
        self.assertEqual(
            mock_stdout.getvalue(),
            "discover\n-v\n-s\n./tests/tests\n-p\ntest*.py\n",
        )


if __name__ == "__main__":
    unittest.main()
