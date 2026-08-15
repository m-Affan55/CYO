from fastapi import WebSocket
from typing import Dict, Any
import logging

logger = logging.getLogger(__name__)

class ConnectionManager:
    def __init__(self):
        # Maps room_id to a dictionary of user_id -> WebSocket
        # Example: {"ABCD": {"uuid-1": <WebSocket>, "uuid-2": <WebSocket>}}
        self.active_connections: Dict[str, Dict[str, WebSocket]] = {}

    async def connect(self, websocket: WebSocket, room_id: str, user_id: str):
        """Accept a websocket connection and store it."""
        await websocket.accept()
        if room_id not in self.active_connections:
            self.active_connections[room_id] = {}
        
        self.active_connections[room_id][user_id] = websocket
        logger.info(f"User {user_id} connected to room {room_id}")

    def disconnect(self, room_id: str, user_id: str):
        """Remove a disconnected websocket."""
        if room_id in self.active_connections:
            if user_id in self.active_connections[room_id]:
                del self.active_connections[room_id][user_id]
                logger.info(f"User {user_id} disconnected from room {room_id}")
            
            # Clean up empty rooms
            if not self.active_connections[room_id]:
                del self.active_connections[room_id]
                logger.info(f"Room {room_id} has no connections, cleaned up.")

    async def broadcast_to_room(self, room_id: str, message: dict):
        """Send a JSON payload to all connected users in a room."""
        if room_id in self.active_connections:
            dead_connections = []
            for user_id, connection in self.active_connections[room_id].items():
                try:
                    await connection.send_json(message)
                except Exception as e:
                    logger.error(f"Error sending message to user {user_id} in room {room_id}: {e}")
                    # Keep track of dead connections to remove them
                    dead_connections.append(user_id)
            
            # Clean up dead connections
            for user_id in dead_connections:
                self.disconnect(room_id, user_id)

    def get_connected_users(self, room_id: str) -> list[str]:
        """Return a list of user IDs currently connected to the room."""
        if room_id in self.active_connections:
            return list(self.active_connections[room_id].keys())
        return []

# Singleton instance to be imported and used across the app
manager = ConnectionManager()
