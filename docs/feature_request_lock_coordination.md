# Feature Request: Multi-Invocation Safety for Codex CLI

## Problem
- Multiple Codex sessions on the same repo can clobber edits and build outputs (e.g., `sim/obj_dir`) with no contention warning.
- Users get silent overwrites, broken builds, and unclear ownership when two CLIs share one `.git` and filesystem.

## Goals
- Advisory locks for writes/builds with clear prompts on contention.
- Optional session-scoped outputs to avoid clobbering build artifacts.
- Graceful fallback to optimistic mode when locking is unavailable.

## Proposal (high level)
- Local lock broker (Unix socket, e.g., `~/.codex/locks.sock`) with `acquire`/`heartbeat`/`release`/`list`/`events`; intents `read|write|exclusive-build`; TTL+heartbeat; FIFO waiters; wait/force semantics.
- Per-repo policy file `repo/.codex/lock-policy.json`: default mode, max TTL, allow_force roles, per-path intents (e.g., `sim/obj_dir` requires `exclusive-build`), build-output namespacing toggle.
- Client UX: startup detects shared `.git`; prompts wait/read-only/new worktree/force; edits take `write` lock + drift check; builds take `exclusive-build` or auto-namespace outputs (`.codex/sessions/<session>/...`) if conflicted; CI flags `--locks=off|force`.
- Optional HTTP/SSE bridge using the same schema for future remote coordination.

## Rollout sketch
1) Opt-in (`CODEX_LOCKS=on`) with warnings and drift checks.
2) Default-on for build outputs + drift checks for edits; locking still advisory.
3) Optional remote bridge; same API over HTTP/SSE.

## Risks to validate
- Stale locks (TTL/heartbeat/force-after-expiry).
- Hardcoded build paths (namespacing opt-in with warnings).
- Broker unavailable (fallback to optimistic, surface status).
- Deadlock/starvation (single-resource locks + FIFO waiters).
