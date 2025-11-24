import argparse
import asyncio
import json
import os
from pathlib import Path
from typing import Any, Dict, Optional

from .broker import Holder, LockBroker, LockConflict, LockNotFound, Resource


def _resource_from_dict(data: Dict[str, Any]) -> Resource:
    return Resource(type=data["type"], id=data["id"])


def _holder_from_dict(data: Dict[str, Any]) -> Holder:
    return Holder(
        client_id=data["client_id"],
        session_id=data["session_id"],
        user=data.get("user"),
        host=data.get("host"),
        meta=data.get("meta", {}) or {},
    )


class BrokerServer:
    def __init__(self, broker: Optional[LockBroker] = None) -> None:
        self.broker = broker or LockBroker()

    def handle(self, msg: Dict[str, Any]) -> Dict[str, Any]:
        op = msg.get("op")
        try:
            if op == "acquire":
                resource = _resource_from_dict(msg["resource"])
                holder = _holder_from_dict(msg["holder"])
                lock = self.broker.acquire(
                    resource=resource,
                    intent=msg["intent"],
                    holder=holder,
                    ttl_ms=int(msg["ttl_ms"]),
                    force=bool(msg.get("force", False)),
                )
                return {"ok": True, "lock": lock.to_dict()}
            if op == "heartbeat":
                lock = self.broker.heartbeat(
                    lock_id=msg["lock_id"],
                    ttl_ms=int(msg["ttl_ms"]),
                )
                return {"ok": True, "lock": lock.to_dict()}
            if op == "release":
                self.broker.release(lock_id=msg["lock_id"])
                return {"ok": True}
            if op == "list":
                resource = msg.get("resource")
                lock_resource = _resource_from_dict(resource) if resource else None
                locks = [l.to_dict() for l in self.broker.list_locks(resource=lock_resource)]
                return {"ok": True, "locks": locks}
            return {"ok": False, "error": "bad_request", "detail": "unknown op"}
        except KeyError as exc:
            return {"ok": False, "error": "bad_request", "detail": f"missing {exc}"}
        except ValueError as exc:
            return {"ok": False, "error": "bad_request", "detail": str(exc)}
        except LockConflict as exc:
            return {"ok": False, "error": "conflict", "holder": exc.holder.to_dict()}
        except LockNotFound:
            return {"ok": False, "error": "not_found"}


async def _serve(socket_path: Path, server: BrokerServer) -> None:
    if socket_path.exists():
        socket_path.unlink()
    socket_path.parent.mkdir(parents=True, exist_ok=True)

    async def handle_client(reader: asyncio.StreamReader, writer: asyncio.StreamWriter) -> None:
        peer = writer.get_extra_info("peername")
        while not reader.at_eof():
            raw = await reader.readline()
            if not raw:
                break
            try:
                msg = json.loads(raw.decode().strip())
            except json.JSONDecodeError:
                writer.write(b'{"ok":false,"error":"bad_json"}\n')
                await writer.drain()
                continue
            resp = server.handle(msg)
            writer.write((json.dumps(resp) + "\n").encode())
            await writer.drain()
        writer.close()
        await writer.wait_closed()
        if peer:
            _ = peer

    unix_server = await asyncio.start_unix_server(handle_client, path=str(socket_path))
    async with unix_server:
        await unix_server.serve_forever()


def main() -> None:
    parser = argparse.ArgumentParser(description="Codex lock broker (prototype)")
    parser.add_argument(
        "--socket",
        default=os.path.expanduser("~/.codex/locks.sock"),
        help="Unix domain socket path",
    )
    args = parser.parse_args()
    server = BrokerServer()
    try:
        asyncio.run(_serve(Path(args.socket), server))
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
