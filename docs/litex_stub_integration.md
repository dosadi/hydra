# LiteX Stub Integration Notes

This page collects the supporting documentation for the newly added LiteX stub RTL and automated tests (`rtl/litex/litex_pcie_bridge.sv`, `rtl/litex/litex_dma_engine.sv`, `scripts/test_litex_stubs.sh`).

## Purpose

- Provide lightweight placeholders that align with the future LiteX PCIe + DMA engine while allowing the renderer/driver teams to exercise partial setups today.
- Give QA/build automation a scope for linting and regression checks before the real LiteX IP lands.

## Running the stub suite

```bash
./scripts/test_litex_stubs.sh
```

This script runs `verilator --lint-only` on the stub RTL files, reports warnings/errors, and can be wired into CI via `scripts/automation_watchdog.sh` or a dedicated job.

## TODO cross links

- `docs/todo/todo_ip_integration.md` now references the stubs and automation script.
- `docs/todo/todo_dma_pcie.md` and `docs/todo/todo_build_tooling.md` plan to rely on the eventual LiteX versions, which will replace these helpers.
- Add future sections in this doc when LiteX IP replaces the stubs or when the tests evolve into functional verification.
