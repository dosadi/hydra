# HBM Integration TODOs

Planning and validation tasks for adding HBM (High Bandwidth Memory) support to the Hydra bus and packaging stack.

- TODO [P0]: Define the target HBM configuration (channels, stack height, interface width) and document it in `docs/hdmi_scanout_architecture.md` or a dedicated integration plan.
- TODO [P1]: Map the Hydra memory subsystem requirements to an open-source PHY capable of servicing HBM lanes; record vendor/OSS options and licensing constraints in `docs/todo/todo_support_and_licensing.md`.
- TODO [P1]: Design the AXI4/AXI-Stream timing constraints for access across the HBM channels and capture them in `todo_dependency_map.md` so RTL/design tasks stay synchronized.
- TODO [P2]: Add testbenches or cocotb fixtures that model HBM channel behavior during large framebuffer transfers/constants and feed their coverage results into `out/fps_health.json`.
- TODO [P1]: Extend the bus interconnect TODOs with HBM-specific arbitration—something like dedicated QoS or channel locking—to avoid competition with LiteDMA traffic.
- TODO [P2]: Collaborate with `todo_ic_packaging.md` to ensure HBM stack cooling, retimer, and power delivery plans are documented before layout signoff.
- TODO [P3]: Define the board bring-up sequence for HBM (training, calibration, rescan, errors) and capture the procedures in `docs/hardware_test_plan.md` plus `docs/todo/todo_hardware_validation.md`.
- TODO [P2]: Evaluate how HBM integration impacts `todo_simulation_viewer.md` (memory bandwidth simulation) and `todo_system_fps.md` (latency/throughput) so viewer profiling accounts for the new memory tier.
