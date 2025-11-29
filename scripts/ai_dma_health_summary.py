#!/usr/bin/env python3
"""Summarize DMA fixture trace for the AI dashboard."""

from __future__ import annotations

import json
from pathlib import Path

TRACE_PATH = Path("out") / "dma_controller_trace.json"
OUT_PATH = Path("out") / "ai_dma_health.txt"


def load_trace() -> dict:
    if not TRACE_PATH.exists():
        return {"bursts": []}
    return json.loads(TRACE_PATH.read_text(encoding="utf-8"))


def summarize(trace: dict) -> str:
    bursts = trace.get("bursts", [])
    total_beats = sum(len(burst.get("beats", [])) for burst in bursts)
    summary = [
        f"bursts={len(bursts)}",
        f"beats={total_beats}",
        f"status={trace.get('status', 'unknown')}",
    ]
    return ", ".join(summary)


def main() -> None:
    trace = load_trace()
    summary = summarize(trace)
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    OUT_PATH.write_text(summary + "\n")
    print(f"AI DMA health summary written to {OUT_PATH}")


if __name__ == "__main__":
    main()
