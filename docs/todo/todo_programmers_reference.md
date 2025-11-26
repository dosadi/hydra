# Programmers Reference TODOs

Goal: provide a concise, searchable reference for Hydra contributors (register map, driver expectations, automation hints) so engineers can quickly orient themselves without chasing scattered docs.

- **TODO [P1]:** Collect the stable CSR/register map, DMA commands, IRQ bits, and port descriptions into a single reference file (linked from `docs/hydra_spec.md`) and keep it updated whenever RTL or driver APIs change.
- **TODO [P1]:** Build an indexed “shortcuts” table that points to the most-used artifacts (`docs/rtl_bus_phase_plan.md`, `docs/hdmi_scanout_architecture.md`, `docs/todo/todo_dma_controller.md`), tagged with keywords and ownership, so programmers can find the right doc quickly.
- **TODO [P2]:** Add quick-start snippets (bash commands, python APIs, litex shell invocation) plus expected outputs so new devs can reproduce builds/tests without hunting through `README.md` sections.
- **TODO [P2]:** Document the automation hooks (meta refresh, dashboards, dependency map) inline so developers understand how TODO metadata, rebalance, and AI dashboards tie into their code changes.
- **TODO [P3]:** Produce a printable cheatsheet (markdown + generated PDF) summarizing build/test commands, debug port expectations, and automation reminders; store it under `docs/todo/` or `docs/archive/`.
