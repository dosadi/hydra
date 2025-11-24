import time
import uuid
from dataclasses import dataclass, field
from typing import Callable, Dict, List, Optional


VALID_INTENTS = {"read", "write", "exclusive-build"}


@dataclass
class Resource:
    type: str
    id: str


@dataclass
class Holder:
    client_id: str
    session_id: str
    user: Optional[str] = None
    host: Optional[str] = None
    meta: Dict[str, str] = field(default_factory=dict)


@dataclass
class Lock:
    lock_id: str
    resource: Resource
    intent: str
    holder: Holder
    expires_at: float
    acquired_at: float = field(default_factory=time.monotonic)

    def to_dict(self) -> Dict[str, object]:
        return {
            "lock_id": self.lock_id,
            "resource": {"type": self.resource.type, "id": self.resource.id},
            "intent": self.intent,
            "holder": vars(self.holder),
            "expires_at": self.expires_at,
            "acquired_at": self.acquired_at,
        }


class LockConflict(Exception):
    def __init__(self, holder: Lock):
        super().__init__("lock conflict")
        self.holder = holder


class LockNotFound(Exception):
    pass


class LockBroker:
    """Single-process lock broker with simple intent compatibility."""

    def __init__(self, time_fn: Callable[[], float] = time.monotonic) -> None:
        self._time = time_fn
        self._locks: Dict[str, Lock] = {}

    def _resource_key(self, resource: Resource) -> str:
        return f"{resource.type}:{resource.id}"

    def _is_compatible(self, new_intent: str, held_intent: str) -> bool:
        if new_intent == "read" and held_intent == "read":
            return True
        return False

    def _expire_stale(self, now: float) -> None:
        stale = [key for key, lock in self._locks.items() if lock.expires_at <= now]
        for key in stale:
            del self._locks[key]

    def acquire(
        self,
        resource: Resource,
        intent: str,
        holder: Holder,
        ttl_ms: int,
        force: bool = False,
        now: Optional[float] = None,
    ) -> Lock:
        if intent not in VALID_INTENTS:
            raise ValueError(f"invalid intent {intent}")
        if ttl_ms <= 0:
            raise ValueError("ttl_ms must be > 0")

        now = self._time() if now is None else now
        self._expire_stale(now)

        key = self._resource_key(resource)
        current = self._locks.get(key)

        if current and not self._is_compatible(intent, current.intent):
            if not force:
                raise LockConflict(current)
            del self._locks[key]

        lock = Lock(
            lock_id=str(uuid.uuid4()),
            resource=resource,
            intent=intent,
            holder=holder,
            expires_at=now + (ttl_ms / 1000.0),
            acquired_at=now,
        )
        self._locks[key] = lock
        return lock

    def heartbeat(self, lock_id: str, ttl_ms: int, now: Optional[float] = None) -> Lock:
        now = self._time() if now is None else now
        self._expire_stale(now)
        lock = self._find_by_id(lock_id)
        lock.expires_at = now + (ttl_ms / 1000.0)
        return lock

    def release(self, lock_id: str, now: Optional[float] = None) -> None:
        now = self._time() if now is None else now
        self._expire_stale(now)
        key = None
        for k, lock in self._locks.items():
            if lock.lock_id == lock_id:
                key = k
                break
        if key is None:
            raise LockNotFound(lock_id)
        del self._locks[key]

    def list_locks(self, resource: Optional[Resource] = None, now: Optional[float] = None) -> List[Lock]:
        now = self._time() if now is None else now
        self._expire_stale(now)
        if resource is None:
            return list(self._locks.values())
        key = self._resource_key(resource)
        lock = self._locks.get(key)
        return [lock] if lock else []

    def _find_by_id(self, lock_id: str) -> Lock:
        for lock in self._locks.values():
            if lock.lock_id == lock_id:
                return lock
        raise LockNotFound(lock_id)
