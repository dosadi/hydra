#!/usr/bin/env python3
"""Produce a placeholder depth buffer health summary for automation dashboards."""

from __future__ import annotations

import json
from datetime import datetime
from pathlib import Path

OUT_JSON = Path("out") / "depth_stats.json"
OUT_TXT = Path("out") / "depth_status.txt"
HISTOGRAM_PATH = Path("out") / "frame_dump_depth_histogram.json"


def load_histogram() -> dict[str, list[float]]:
    if HISTOGRAM_PATH.exists():
        return json.loads(HISTOGRAM_PATH.read_text(encoding="utf-8"))
    # fallback synthetic histogram
    bins = [i * 256 for i in range(0, 17)]
    counts = [10 + i * 5 for i in range(len(bins) - 1)]
    return {"bins": bins, "counts": counts}


def summarize_histogram(hist: dict[str, list[float]]) -> dict[str, float]:
    bins = hist["bins"]
    counts = hist["counts"]
    total = sum(counts)
    if total == 0:
        return {
            "min_depth": bins[0],
            "max_depth": bins[-1],
            "mean_depth": (bins[0] + bins[-1]) / 2,
            "std_dev": 0.0,
        }
    midpoints = [(bins[i] + bins[i + 1]) / 2 for i in range(len(counts))]
    weighted = sum(mid * cnt for mid, cnt in zip(midpoints, counts))
    mean = weighted / total
    variance = sum(cnt * (mid - mean) ** 2 for mid, cnt in zip(midpoints, counts)) / total
    return {
        "min_depth": bins[0],
        "max_depth": bins[-1],
        "mean_depth": mean,
        "std_dev": variance**0.5,
    }


def build_stats() -> dict[str, float]:
    hist = load_histogram()
    summary = summarize_histogram(hist)
    summary.update(
        {
            "generated": datetime.utcnow().isoformat() + "Z",
            "total_samples": sum(hist.get("counts", [])),
            "last_reset_ms": 17,
        }
    )
    return summary


def main() -> None:
    stats = build_stats()
    OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUT_JSON.write_text(json.dumps(stats, indent=2))
    OUT_TXT.write_text(
        f"{stats['generated']}: depth range {stats['min_depth']}..{stats['max_depth']}, "
        f"mean {stats['mean_depth']:.1f}, std {stats['std_dev']:.1f}\n"
    )
    print(f"Depth health summary written to {OUT_JSON} + {OUT_TXT}")


if __name__ == "__main__":
    main()
