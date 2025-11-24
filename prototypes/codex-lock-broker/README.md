# Codex Lock Broker (Prototype)

Prototype of a local lock broker + session-scoped output helper for Codex CLI. It is intentionally small and single-user; the goal is to validate the API and UX, not production hardening.

## What it does
- Advisory locks over a Unix socket using JSON-lines messages (`acquire`, `heartbeat`, `release`, `list`).
- Intents: `read`, `write`, `exclusive-build` with simple compatibility rules.
- TTL + heartbeat for leases; optional `force` to steal on conflict.
- Minimal server (`python -m codex_lock_broker.server`) and library (`LockBroker`) for tests.

## Quick start
```bash
cd prototypes/codex-lock-broker
python -m pip install -e .[dev]
pytest
# Run broker (default socket: ~/.codex/locks.sock)
python -m codex_lock_broker.server
```

## Message shape (JSON line)
```json
{"op":"acquire","resource":{"type":"path","id":"sim/obj_dir"},"intent":"exclusive-build","holder":{"client_id":"cli","session_id":"s1"},"ttl_ms":60000,"force":false}
```

Responses:
- Success: `{"ok":true,"lock":{"lock_id":"...","resource":...,"intent":"write","expires_at":12345.6,"holder":...}}`
- Conflict: `{"ok":false,"error":"conflict","holder":{...}}`
- Not found: `{"ok":false,"error":"not_found"}`
- Invalid: `{"ok":false,"error":"bad_request","detail":"..."}`

## CI template
See `.github/workflows/ci.yml` for a simple lint/test workflow (Python + pytest).
