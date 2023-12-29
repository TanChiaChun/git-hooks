import io
import json
import unittest
from pathlib import Path
from unittest.mock import Mock, mock_open, patch

from get_unittest_options import get_unittest_options, get_vscode_options, main


class TestModule(unittest.TestCase):
    def test_get_vscode_options(self) -> None:
        options = ["-v", "-s", "./tests/tests", "-p", "test*.py"]
        settings_data = {"python.testing.unittestArgs": options}
        with patch(
            "get_unittest_options.open",
            new=mock_open(read_data=json.dumps(settings_data)),
        ):
            self.assertListEqual(get_vscode_options(Path("")), options)

    @patch.dict("os.environ", values={"BATS_TEST_FILENAME": ""})
    def test_get_unittest_options(self) -> None:
        self.assertListEqual(get_unittest_options(), ["-v", "./test.py"])

    @patch("pathlib.Path.is_file", new=Mock(return_value=False))
    def test_main(self) -> None:
        with patch("sys.stdout", new_callable=io.StringIO) as mock_stdout:
            main()
            self.assertEqual(
                mock_stdout.getvalue(),
                "dscover\n-v\n-s\n./tests\n-p\ntest*.py\n",
            )


if __name__ == "__main__":
    unittest.main()
