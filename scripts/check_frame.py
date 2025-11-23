#!/usr/bin/env python3
import sys
from typing import Tuple


def read_ppm(path: str) -> Tuple[int, int, bytes]:
    with open(path, "rb") as f:
        magic = f.readline().strip()
        if magic != b"P6":
            raise ValueError(f"{path}: unsupported PPM magic {magic!r}, expected P6")
        # Skip comments
        def next_token() -> bytes:
            line = f.readline()
            while line.startswith(b"#"):
                line = f.readline()
            return line

        dims = next_token().split()
        if len(dims) != 2:
            raise ValueError(f"{path}: bad dims line {dims!r}")
        w, h = int(dims[0]), int(dims[1])
        maxval = int(next_token().strip())
        if maxval != 255:
            raise ValueError(f"{path}: unsupported maxval {maxval}, expected 255")
        data = f.read(w * h * 3)
        if len(data) != w * h * 3:
            raise ValueError(f"{path}: short data, expected {w*h*3} bytes, got {len(data)}")
        return w, h, data


def stats(w: int, h: int, data: bytes) -> Tuple[Tuple[float, float, float], Tuple[int, int, int]]:
    n = w * h
    sr = sg = sb = 0
    maxr = maxg = maxb = 0
    for i in range(0, len(data), 3):
        r, g, b = data[i], data[i+1], data[i+2]
        sr += r
        sg += g
        sb += b
        if r > maxr: maxr = r
        if g > maxg: maxg = g
        if b > maxb: maxb = b
    return (sr / n, sg / n, sb / n), (maxr, maxg, maxb)


def diff(a: bytes, b: bytes) -> Tuple[float, float]:
    if len(a) != len(b):
        raise ValueError("Buffers differ in length")
    n = len(a) // 3
    sad = 0
    maxd = 0
    for i in range(0, len(a), 3):
        dr = abs(a[i]   - b[i])
        dg = abs(a[i+1] - b[i+1])
        db = abs(a[i+2] - b[i+2])
        d = max(dr, dg, db)
        sad += dr + dg + db
        if d > maxd:
            maxd = d
    return sad / (3*n), maxd


def main(argv: list) -> int:
    if len(argv) != 3:
        print(f"Usage: {argv[0]} GOLDEN.ppm TEST.ppm", file=sys.stderr)
        return 2
    gw, gh, gdata = read_ppm(argv[1])
    tw, th, tdata = read_ppm(argv[2])
    if (gw, gh) != (tw, th):
        print(f"dim mismatch: golden={gw}x{gh} test={tw}x{th}", file=sys.stderr)
        return 1
    gavg, gmax = stats(gw, gh, gdata)
    tavg, tmax = stats(tw, th, tdata)
    sad, maxd = diff(gdata, tdata)
    print(f"golden avg RGB={gavg} max={gmax}")
    print(f"test   avg RGB={tavg} max={tmax}")
    print(f"mean abs diff per channel={sad:.3f}, max per-pixel diff={maxd}")
    # Fail if we diverge too much from golden
    if sad > 2.0 or maxd > 16:
        print("FAIL: image differs from golden beyond thresholds", file=sys.stderr)
        return 1
    print("OK: image within thresholds")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
