from typing import Dict, Set
from fastapi import WebSocket


class ConnectionManager:
    def __init__(self):
        self.active_connections: Dict[int, Set[WebSocket]] = {}

        # user_id -> conversation_id
        self.active_conversations: Dict[int, int] = {}

        # websocket -> user_id
        self.socket_users: Dict[WebSocket, int] = {}

    async def connect(self, user_id: int, websocket: WebSocket):
        await websocket.accept()

        if user_id not in self.active_connections:
            self.active_connections[user_id] = set()

        was_offline = len(self.active_connections[user_id]) == 0

        self.active_connections[user_id].add(websocket)
        self.socket_users[websocket] = user_id

        if was_offline:
            await self.broadcast_presence(
                user_id=user_id,
                online=True,
            )

    async def disconnect(self, user_id: int, websocket: WebSocket | None = None):
        sockets = self.active_connections.get(user_id)

        if websocket is not None:
            self.socket_users.pop(websocket, None)

        if not sockets:
            self.active_conversations.pop(user_id, None)
            return

        if websocket is not None:
            sockets.discard(websocket)
        else:
            for ws in list(sockets):
                self.socket_users.pop(ws, None)
            sockets.clear()

        if not sockets:
            self.active_connections.pop(user_id, None)
            self.active_conversations.pop(user_id, None)

            await self.broadcast_presence(
                user_id=user_id,
                online=False,
            )

    def set_active_conversation(
        self,
        *,
        user_id: int,
        conversation_id: int | None,
    ) -> None:
        if conversation_id is None or conversation_id <= 0:
            self.active_conversations.pop(user_id, None)
            return

        self.active_conversations[user_id] = conversation_id

    def clear_active_conversation(
        self,
        *,
        user_id: int,
    ) -> None:
        self.active_conversations.pop(user_id, None)

    def is_user_online(self, user_id: int) -> bool:
        sockets = self.active_connections.get(user_id)
        return bool(sockets)

    def is_user_in_conversation(
        self,
        *,
        user_id: int,
        conversation_id: int,
    ) -> bool:
        return self.active_conversations.get(user_id) == conversation_id

    async def send_to_user(self, user_id: int, data: dict):
        sockets = self.active_connections.get(user_id)

        if not sockets:
            return

        dead_connections = []

        for websocket in list(sockets):
            try:
                await websocket.send_json(data)
            except Exception:
                dead_connections.append(websocket)

        for websocket in dead_connections:
            sockets.discard(websocket)
            self.socket_users.pop(websocket, None)

        if not sockets:
            self.active_connections.pop(user_id, None)
            self.active_conversations.pop(user_id, None)

    async def broadcast_presence(self, user_id: int, online: bool):
        data = {
            "type": "user_presence",
            "user_id": user_id,
            "online": online,
            "active_now": online,
        }

        dead_by_user: dict[int, list[WebSocket]] = {}

        for uid, sockets in list(self.active_connections.items()):
            if uid == user_id:
                continue

            for websocket in list(sockets):
                try:
                    await websocket.send_json(data)
                except Exception:
                    dead_by_user.setdefault(uid, []).append(websocket)

        for uid, dead_sockets in dead_by_user.items():
            sockets = self.active_connections.get(uid)
            if not sockets:
                continue

            for websocket in dead_sockets:
                sockets.discard(websocket)
                self.socket_users.pop(websocket, None)

            if not sockets:
                self.active_connections.pop(uid, None)
                self.active_conversations.pop(uid, None)


manager = ConnectionManager()