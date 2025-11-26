#!/usr/bin/env python3
"""Summarize the render pipeline instrumentation CSV for automation dashboards."""

from __future__ import annotations

import argparse
import csv
from datetime import datetime
from pathlib import Path
from statistics import StatisticsError, mean


def float_or_zero(value: str | None) -> float:
    if value is None or value == "":
        return 0.0
    try:
        return float(value)
    except ValueError:
        return 0.0


def load_rows(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        return []
    with path.open(encoding="utf-8") as fh:
        reader = csv.DictReader(fh)
        return [row for row in reader]


def summarize_baseline(path: Path, frames: int) -> list[str]:
    rows = load_rows(path)
    if not rows:
        return [
            "- render_pipeline_baseline.csv missing; run `cd sim && ./sim_voxel --instrument` to collect metrics."
        ]
    subset = rows[-frames:] if frames > 0 else rows
    if not subset:
        return ["- render_pipeline_baseline.csv has no entries to summarize."]

    ray_loop = [float_or_zero(row.get("ray_loop_ms")) for row in subset]
    hud_present = [float_or_zero(row.get("hud_present_ms")) for row in subset]
    framebuffer_copy = [float_or_zero(row.get("framebuffer_copy_ms")) for row in subset]
    frame_total = [float_or_zero(row.get("frame_total_ms")) for row in subset]
    fps_values = [float_or_zero(row.get("fps")) for row in subset]

    try:
        avg_ray = mean(ray_loop)
        avg_hud = mean(hud_present)
        avg_copy = mean(framebuffer_copy)
        avg_frame = mean(frame_total)
        avg_fps = mean(fps_values)
        min_fps = min(fps_values)
    except StatisticsError:
        return ["- Unable to compute averages from render pipeline instrumentation data."]

    last = subset[-1]
    last_frame = last.get("frame", "<unknown>")
    last_ts = last.get("timestamp_ms")
    last_ts_str = ""
    if last_ts:
        try:
            epoch_ms = int(last_ts)
            last_ts_str = datetime.utcfromtimestamp(epoch_ms / 1000.0).isoformat() + "Z"
        except ValueError:
            last_ts_str = last_ts
    else:
        last_ts_str = "<no timestamp>"

    last_ray = float_or_zero(last.get("ray_loop_ms"))
    last_hud = float_or_zero(last.get("hud_present_ms"))
    last_copy = float_or_zero(last.get("framebuffer_copy_ms"))
    last_frame_total = float_or_zero(last.get("frame_total_ms"))
    last_fps = float_or_zero(last.get("fps"))

    lines = [
        f"- Render baseline ({len(subset)} frames): avg ray loop {avg_ray:.2f} ms, HUD/present {avg_hud:.2f} ms, framebuffer copy {avg_copy:.2f} ms, frame {avg_frame:.2f} ms, avg FPS {avg_fps:.2f}, min FPS {min_fps:.2f}.",
        f"- Last entry: frame {last_frame} @ {last_ts_str}, fps {last_fps:.2f}, ray {last_ray:.2f} ms, HUD/present {last_hud:.2f} ms, copy {last_copy:.2f} ms, frame {last_frame_total:.2f} ms."
    ]
    return lines


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Produce a short summary of render pipeline instrumentation CSV data."
    )
    parser.add_argument(
        "--input",
        "-i",
        default="out/render_pipeline_baseline.csv",
        help="Path to the instrumentation CSV file.",
    )
    parser.add_argument(
        "--frames",
        "-n",
        type=int,
        default=20,
        help="How many recent frames to average when summarizing.",
    )
    args = parser.parse_args()
    summary = summarize_baseline(Path(args.input), args.frames)
    if summary:
        print("\n".join(summary))


if __name__ == "__main__":
    main()
