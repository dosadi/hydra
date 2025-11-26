# Memory System TODOs

Coordinates HBM, DRAM, internal buffers, and compression so the renderer, HDMI path, and DMA controller all share the same memory assumptions.

- TODO [P0]: Expand `docs/rtl_bus_phase_plan.md` with the full memory hierarchy diagram, connect it to `docs/todo/todo_hbm_integration.md`, and capture which bus sectors own each tier.
- TODO [P1]: Define how framebuffers, depth buffers, and blitter scratch spaces are laid out in DRAM/HBM so `todo_rendering_pipeline.md`, `todo_bus_infrastructure.md`, and `todo_dma_controller.md` can agree on address maps.
- TODO [P1]: Investigate where hardware RLE compression (see `todo_compression.md`) can sit in the memory path to support hollow objects/memory savings while keeping DMA performance predictable.
- TODO [P2]: Add simulation fixtures that replay large transfers across the memory tiers and log bandwidth vs latency so `out/fps_health.json` and `out/memory_health.json` can show regression trends.
- TODO [P3]: Document the dual open-source/closed-source path for memory PHYs (HBM vs vendor DDR) inside this tracker so integrators know how to plug in proprietary PHYs without changing the RTL bus contracts.
