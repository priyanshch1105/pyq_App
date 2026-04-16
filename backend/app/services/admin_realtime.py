from __future__ import annotations

import asyncio
from datetime import datetime, timedelta, timezone
from typing import Any
from uuid import UUID

from fastapi import WebSocket


class AdminRealtimeTracker:
    def __init__(self, activity_window_seconds: int = 300) -> None:
        self.activity_window = timedelta(seconds=activity_window_seconds)
        self._last_seen: dict[UUID, dict[str, Any]] = {}
        self._dashboard_connections: set[WebSocket] = set()
        self._announcement_connections: set[WebSocket] = set()
        self._lock = asyncio.Lock()

    def _now(self) -> datetime:
        return datetime.now(timezone.utc).replace(tzinfo=None)

    async def touch_user(self, user_id: UUID, email: str) -> None:
        async with self._lock:
            self._last_seen[user_id] = {
                "email": email,
                "last_seen": self._now(),
            }

    async def active_user_samples(self, limit: int = 10) -> list[dict[str, Any]]:
        async with self._lock:
            self._prune_locked()
            rows = sorted(
                (
                    {
                        "user_id": user_id,
                        "email": payload["email"],
                        "last_seen": payload["last_seen"],
                    }
                    for user_id, payload in self._last_seen.items()
                ),
                key=lambda row: row["last_seen"],
                reverse=True,
            )
            return rows[:limit]

    async def active_user_count(self) -> int:
        async with self._lock:
            self._prune_locked()
            return len(self._last_seen)

    async def register_dashboard(self, websocket: WebSocket) -> None:
        await websocket.accept()
        self._dashboard_connections.add(websocket)

    def unregister_dashboard(self, websocket: WebSocket) -> None:
        self._dashboard_connections.discard(websocket)

    async def register_announcement(self, websocket: WebSocket) -> None:
        await websocket.accept()
        self._announcement_connections.add(websocket)

    def unregister_announcement(self, websocket: WebSocket) -> None:
        self._announcement_connections.discard(websocket)

    async def broadcast_dashboard(self, payload: dict[str, Any]) -> None:
        await self._broadcast(self._dashboard_connections, payload)

    async def broadcast_announcement(self, payload: dict[str, Any]) -> None:
        await self._broadcast(self._announcement_connections, payload)

    async def _broadcast(self, targets: set[WebSocket], payload: dict[str, Any]) -> None:
        stale: list[WebSocket] = []
        for connection in list(targets):
            try:
                await connection.send_json(payload)
            except Exception:
                stale.append(connection)
        for connection in stale:
            targets.discard(connection)

    def _prune_locked(self) -> None:
        cutoff = self._now() - self.activity_window
        stale_ids = [
            user_id for user_id, payload in self._last_seen.items() if payload["last_seen"] < cutoff
        ]
        for user_id in stale_ids:
            self._last_seen.pop(user_id, None)


admin_realtime_tracker = AdminRealtimeTracker()
