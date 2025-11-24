import pytest

from codex_lock_broker.broker import Holder, LockBroker, LockConflict, Resource


class Clock:
    def __init__(self, start: float = 0.0) -> None:
        self.now = start

    def __call__(self) -> float:  # pragma: no cover - trivial
        return self.now

    def advance(self, seconds: float) -> None:
        self.now += seconds


def holder(client: str = "cli", session: str = "s1") -> Holder:
    return Holder(client_id=client, session_id=session)


def resource(path: str = "sim/obj_dir") -> Resource:
    return Resource(type="path", id=path)


def test_acquire_and_conflict():
    broker = LockBroker()
    lock1 = broker.acquire(resource(), "write", holder(), ttl_ms=1000)
    assert lock1.intent == "write"
    with pytest.raises(LockConflict):
        broker.acquire(resource(), "write", holder("cli2"), ttl_ms=1000)


def test_force_steals_lock():
    broker = LockBroker()
    broker.acquire(resource(), "write", holder("cli1"), ttl_ms=1000)
    lock2 = broker.acquire(resource(), "write", holder("cli2"), ttl_ms=500, force=True)
    assert lock2.holder.client_id == "cli2"


def test_read_is_compatible():
    broker = LockBroker()
    broker.acquire(resource(), "read", holder("cli1"), ttl_ms=1000)
    lock2 = broker.acquire(resource(), "read", holder("cli2"), ttl_ms=1000)
    assert lock2.intent == "read"


def test_ttl_expiry_and_heartbeat():
    clock = Clock()
    broker = LockBroker(time_fn=clock)
    lock = broker.acquire(resource(), "write", holder(), ttl_ms=1000)
    clock.advance(0.5)
    broker.heartbeat(lock.lock_id, ttl_ms=1000)
    clock.advance(0.6)
    assert broker.list_locks(resource())  # heartbeat extended lease
    clock.advance(1.0)
    assert not broker.list_locks(resource())  # expired after ttl


def test_server_handle_roundtrip():
    from codex_lock_broker.server import BrokerServer

    server = BrokerServer()
    resp1 = server.handle(
        {
            "op": "acquire",
            "resource": {"type": "path", "id": "sim/obj_dir"},
            "intent": "write",
            "holder": {"client_id": "cli", "session_id": "s1"},
            "ttl_ms": 1000,
        }
    )
    assert resp1["ok"] is True
    lock_id = resp1["lock"]["lock_id"]

    resp2 = server.handle({"op": "list", "resource": {"type": "path", "id": "sim/obj_dir"}})
    assert resp2["locks"]

    resp3 = server.handle({"op": "release", "lock_id": lock_id})
    assert resp3["ok"] is True
