# TODO Rebalance Policy

This policy keeps the TODO tracker system balanced by nudging contributors to add new items to the shorter lists when the large trackers are already heavy. It backs that decision with tooling so you can quickly spot undersized files before you add TODOs.

## 1. Use the rebalance script

Run the helper any time you finish a TODO batch or start a new push:

```bash
python3 scripts/todo_rebalance.py
```

It prints the average TODO count and highlights trackers whose TODO volume is less than 65% of the average. These are signals that the quieter trackers can absorb the next round of work (whether a quick fix, a deeper investigation, or a larger feature) so the system stays uniformly detailed.

## 2. Use the flagged tracker for whatever growth it needs

When the script flags a file as under-indexed:

- Add **a few concrete TODOs** (any priority) that describe deliverables ranging from quick fixes to exploratory efforts or even multi-week features; the goal is to keep the tracker expressive.
- Link back to larger trackers when the work relates (e.g., note how a new `todo_site_wiki.md` entry references `todo_documentation.md`).
- Treat the flagged trackers as overflow slots for whatever scale of work the project needs—whether the next brief bugfix or a larger architecture spike. They ensure coverage remains balanced without dictating task size.

## 3. Refresh the distribution regularly

Schedule the rebalance script alongside your weekly plan, especially after merging large batches into `todo_master.md`, `todo_rendering.md`, or `todo_dma_pcie.md`. If everything passes the 65% check, let the big trackers absorb the bulk of items for that sprint; otherwise, seed the quiet trackers until the ratios align.

## 4. Example contributions

- Add simple lab enforcement steps to `todo_board_level.md` (P3) when the board tracker gets stale.
- Populate `todo_site_wiki.md` with small “freshness” updates after documentation sprints to keep the wiki area visible.
- Extend `todo_xschem.md` with a short checklist whenever the schematic or symbols change, even if the rest of the TODOs are long.

Use this policy to keep the tracker grid even and encourage contributors to explore the edges of the TODO ecosystem.
