# RFC: Lock Coordination and Session-Scoped Outputs for Codex CLI

## Problem
- Multiple Codex CLI invocations on the same repo can clobber edits and build outputs (e.g., `sim/obj_dir`) without any contention warning.
- Shared `.git`/workspace state is not detected; users lose work or get broken artifacts with no indication of ownership.

## Goals
- Serialize high-risk operations (writes/builds) with advisory locks and clear UX.
- Provide optional session-scoped outputs to avoid artifact collisions.
- Degrade gracefully to optimistic mode when locking is unavailable.
- Keep overhead low; no heavy dependencies.

## Non-goals
- Replacing git conflict resolution or branching.
- Strong distributed guarantees across untrusted hosts.
- Multi-resource transactional locks.

## API Surface (Lock Coordination API)
- Ops: `acquire`, `heartbeat`, `release`, `list`, `events`.
- Resource: `{type: repo|path|ref|build-output, id}`.
- Intents: `read`, `write`, `exclusive-build`.
- Params: `ttl_ms`, `wait_ms`, `force`, `metadata`.
- Responses: success `{lock_id, expires_at}`; conflict `409 {holder, retry_after_ms, wait_position?}`; wait timeout `408`; policy `403`.
- Events: `lock_acquired|released|expired|denied` via subscription (JSON lines or SSE).

## Policy / Config
- Repo file: `.codex/lock-policy.json`.
- Fields: `default_mode` (optimistic|strict), `max_ttl_ms`, `allow_force` roles, per-path intents (e.g., `sim/obj_dir` requires `exclusive-build`), `namespacing.build_outputs` toggle.
- Defaults: optimistic mode, enforce `exclusive-build` for known output dirs when policy present.

## Client UX
- Startup: detect shared `.git`; connect to broker. If repo lock held, prompt `[W]ait / [R]ead-only / [N]ew worktree / [F]orce (policy-gated)`.
- Edit: acquire `write` on file/dir; on conflict prompt wait/read-only/worktree. Store hash/mtime snapshot; on save, drift check and prompt reload/merge if changed.
- Build: acquire `exclusive-build` on build dir; on conflict prompt wait or auto-namespace outputs to `.codex/sessions/<session>/...`. Show holder info.
- CI/non-interactive: flags `--locks=off|force`, bounded waits.
- Status: indicate broker availability and fallback mode.

## Broker Design (Local-first)
- On-demand Unix socket `~/.codex/locks.sock`, perms 0600; single-user trusted model.
- In-memory tables: `resource_key -> {current_lock, wait_queue}`; FIFO waiters.
- TTL + heartbeat; expiries via timer wheel/heap.
- Append-only journal for crash recovery; replay on start, drop expired; rotate/compact.
- Event fan-out per connection; drop on backpressure.
- Optional HTTP/SSE bridge reusing the same schema.

## Rollout
1) Opt-in (`CODEX_LOCKS=on`) with warnings + drift checks.
2) Default-on for build outputs; edits still advisory with drift checks.
3) Optional remote bridge; same API over HTTP/SSE.

## Risks / Mitigations
- Stale locks: TTL + heartbeat + expiry + force-after-expiry policy.
- Deadlock/starvation: single-resource locks + FIFO; canonical acquire order if expanded.
- Hardcoded build paths: namespacing opt-in with warnings.
- Broker unavailable: fallback to optimistic mode; surface status loudly.
- Policy misconfig: enforce max TTL and allowed intents/force roles.

## Testing
- Unit: intent matrix, TTL/expiry, wait queue ordering, force/policy enforcement, journal replay.
- Integration: two clients contending; heartbeat loss; crash/restart recovery.
- Policy: required `exclusive-build`; namespacing fallback.
- Load: many short-TTL locks; event backpressure.

## Open Questions
- Should build-output namespacing be auto-on or warn-only for repos with hardcoded paths?
- Default TTL and max TTL limits?
- Force rules for CI vs interactive users?
- Do we surface holder identity (user/host/pid) by default or behind a consent flag?

## Prototype Plan
- Implement local broker (Unix socket JSON-lines) with `acquire`/`heartbeat`/`release`/`events`, TTL, FIFO waiters, journal.
- Client helper lib for Codex CLI: connect, acquire with wait/force, drift check helper, session IDs, namespacing helper.
- CLI hooks: startup prompt on shared `.git`; edit/build wrappers; CI flags.
- Include template policy file and minimal HTTP/SSE bridge stub for future work.
