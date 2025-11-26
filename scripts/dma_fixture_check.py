#!/usr/bin/env python3
"""Validate DMA fixture trace outputs for regressions."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Iterable

TRACE_PATH = Path("out") / "dma_controller_trace.json"


class TraceError(Exception):
    pass


def load_trace() -> dict:
    if not TRACE_PATH.exists():
        raise TraceError(f"Trace file missing: {TRACE_PATH}")
    return json.loads(TRACE_PATH.read_text(encoding="utf-8"))


def validate_burst(burst: dict) -> None:
    if not burst.get("beats"):
        raise TraceError(f"Burst {burst.get('burst_id')} has no beats")
    last_set = False
    for beat in burst["beats"]:
        if last_set and not beat.get("wlast"):
            raise TraceError(f"WLAST not set after final beat in burst {burst['burst_id']}")
        last_set = beat.get("wlast", False)


def validate_trace(trace: dict) -> None:
    if trace.get("status") != "ok":
        raise TraceError("Trace status is not ok")
    bursts = trace.get("bursts", [])
    if not bursts:
        raise TraceError("No bursts recorded in trace")
    for burst in bursts:
        validate_burst(burst)


def main() -> None:
    trace = load_trace()
    validate_trace(trace)
    print("DMA fixture trace validation passed.")


if __name__ == "__main__":
    main()
