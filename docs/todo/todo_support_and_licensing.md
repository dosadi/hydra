# Support & Licensing TODOs

Tracks field support readiness, licensing compliance, and long-term maintenance commitments for Hydra deployments.

## P1 - Support Readiness
- **TODO [P1]:** Publish a support escalation matrix (phone/email, response time, ticket routing) and link it from `docs/todo/todo_go_to_market.md`.
- **TODO [P1]:** Create a “support readout” document that lists monitoring dashboards, CLI health checks, and auto-reporting scripts so support teams see Hydra health without delving into internals.
- **TODO [P1]:** Add readiness checklists for field engineers (pre-flight, deploy, rollback) and record them within this tracker so procedural TODOs show in automation summaries.
- **TODO [P1]:** Provide downloadable support kits (scripts, docs, logs) packaged per release plus instructions on how to run `scripts/automation_watchdog.sh`/dashboard scripts in customer environments.

## P2 - Licensing & Compliance
- **TODO [P2]:** Maintain a licensing matrix covering Hydra components (RTL, drivers, docs, third-party IP) and reflect it in the repo (LICENSES.md) plus this tracker with automation references.
- **TODO [P2]:** Add a script that validates license headers (`scripts/check_license_headers.py`) and extend `scripts/automation_watchdog.sh` to fail when the headers shift or a new file lacks the required notices.
- **TODO [P2]:** Document export control / ECCN obligations (if any) and tie them to the support/legal workflow (tickets, approvals) so the licensing tracker warns when builds touch restricted components.
- **TODO [P2]:** Provide a “dual-license decision log” recording when new features require re-licensing or third-party approval, with entries noted inside this tracker for automation reference.

## P3 - Community Support / Ecosystem
- **TODO [P3]:** Build a community support board (forum, Discord, GitHub Discussions) and note the onboarding steps (moderation guidelines, response SLAs) inside this tracker.
- **TODO [P3]:** Publish a licensing FAQ (dual licenses, third-party IP) referencing this tracker so the community can see what constraints apply to contributions.
- **TODO [P3]:** Add a volunteer support roster and tag their focus areas (docs, driver builds, hardware tests) inside this tracker so community events display real owners in the AI dashboard summary.
