import os
import tempfile
import unittest
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

import check_frame  # type: ignore


def write_ppm(path: Path, pixels: bytes, width: int, height: int) -> None:
    header = f"P6\n{width} {height}\n255\n".encode("ascii")
    with open(path, "wb") as f:
        f.write(header)
        f.write(pixels)


class CheckFrameTest(unittest.TestCase):
    def test_identical_images_pass(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            golden = Path(tmp) / "golden.ppm"
            test = Path(tmp) / "test.ppm"
            # 2x1 black pixels
            write_ppm(golden, bytes([0, 0, 0, 0, 0, 0]), 2, 1)
            write_ppm(test, bytes([0, 0, 0, 0, 0, 0]), 2, 1)
            rc = check_frame.main(["check_frame", str(golden), str(test)])
            self.assertEqual(rc, 0)

    def test_different_images_fail(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            golden = Path(tmp) / "golden.ppm"
            test = Path(tmp) / "test.ppm"
            # 2x1 black vs bright red to exceed thresholds
            write_ppm(golden, bytes([0, 0, 0, 0, 0, 0]), 2, 1)
            write_ppm(test, bytes([255, 0, 0, 255, 0, 0]), 2, 1)
            rc = check_frame.main(["check_frame", str(golden), str(test)])
            self.assertNotEqual(rc, 0)


if __name__ == "__main__":
    unittest.main()
