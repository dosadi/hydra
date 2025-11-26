# TODO Rebalance Policy

This policy keeps the TODO tracker system balanced by nudging contributors to add new items to the shorter lists when the large trackers are already heavy. It backs that decision with tooling so you can quickly spot undersized files before you add TODOs.

## 1. Use the rebalance script

Run the helper any time you finish a TODO batch or start a new push:

```bash
python3 scripts/todo_rebalance.py
```

It prints the average TODO count and highlights trackers whose TODO volume is less than 65% of the average. These are the places that should absorb the next “small bite” of work so the system stays uniformly detailed.

## 2. Prefer “micro-trackers” for short bursts

When the script flags a file:

- Add **1–3 concrete TODOs** (P1/P2 ideally) that describe observable deliverables (e.g., “Document new hazard log template for board lab sessions”).
- Link back to larger trackers when the work relates (e.g., note how a new `todo_site_wiki.md` entry references `todo_documentation.md`).
- Keep each TODO short and actionable to make it easy for contributors to pick up; these trackers act as fairness reservoirs for the big ones.

## 3. Refresh the distribution regularly

Schedule the rebalance script alongside your weekly plan, especially after merging large batches into `todo_master.md`, `todo_rendering.md`, or `todo_dma_pcie.md`. If everything passes the 65% check, let the big trackers absorb the bulk of items for that sprint; otherwise, seed the quiet trackers until the ratios align.

## 4. Example contributions

- Add simple lab enforcement steps to `todo_board_level.md` (P3) when the board tracker gets stale.
- Populate `todo_site_wiki.md` with small “freshness” updates after documentation sprints to keep the wiki area visible.
- Extend `todo_xschem.md` with a short checklist whenever the schematic or symbols change, even if the rest of the TODOs are long.

Use this policy to keep the tracker grid even and encourage contributors to explore the edges of the TODO ecosystem.
