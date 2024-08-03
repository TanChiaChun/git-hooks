import io
import json
import unittest
from pathlib import Path
from unittest.mock import Mock, mock_open, patch

from unittest_options import get_unittest_options, get_vscode_options, main


class TestModule(unittest.TestCase):
    def test_get_vscode_options(self) -> None:
        options = ["-v", "-s", "./tests/tests", "-p", "test*.py"]
        settings_data = {"python.testing.unittestArgs": options}
        with patch(
            "unittest_options.open",
            new=mock_open(read_data=json.dumps(settings_data)),
        ):
            self.assertListEqual(get_vscode_options(Path("")), options)

    @patch.dict("os.environ", values={"BATS_TEST_FILENAME": ""})
    def test_get_unittest_options(self) -> None:
        self.assertListEqual(get_unittest_options(), ["-v", "./test.py"])

    @patch("pathlib.Path.is_file", new=Mock(return_value=False))
    @patch("sys.stdout", new_callable=io.StringIO)
    def test_main(self, mock_stdout: io.StringIO) -> None:
        main()
        self.assertEqual(
            mock_stdout.getvalue(),
            "discover\n-v\n-s\n./tests\n-p\ntest*.py\n",
        )


if __name__ == "__main__":
    unittest.main()
