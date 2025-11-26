#!/usr/bin/env python3
"""Generate a placeholder DMA fixture trace for hydra regression planning."""

from __future__ import annotations

import json
from datetime import datetime
from pathlib import Path

TRACE_PATH = Path("out") / "dma_controller_trace.json"


def create_trace() -> None:
    TRACE_PATH.parent.mkdir(parents=True, exist_ok=True)
    burst_template = {
        "burst_id": 1,
        "awaddr": "0x10000000",
        "awlen": 7,
        "beats": [],
    }
    for beat in range(burst_template["awlen"] + 1):
        burst_template["beats"].append(
            {
                "beat": beat,
                "awvalid": True,
                "awready": True,
                "wdata": f"0x{0xdeadbeef + beat:08x}",
                "wlast": beat == burst_template["awlen"],
            }
        )
    trace = {
        "generated": datetime.utcnow().isoformat() + "Z",
        "fixture": "dma_trace_stub",
        "bursts": [burst_template],
        "status": "ok",
    }
    TRACE_PATH.write_text(json.dumps(trace, indent=2))
    print(f"Created placeholder DMA fixture trace at {TRACE_PATH}")


def main() -> None:
    create_trace()


if __name__ == "__main__":
    main()
