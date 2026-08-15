# CYO (Call You Out)

## Overview
Friends Title Game is a real-time multiplayer social party game designed for groups of friends. Players join the same online game room, collaboratively create a shared pool of titles, and take turns assigning titles to other players. A randomly selected player assigns a title to a randomly selected target, and the rest of the group votes on whether the title fits the target. Real-time state changes, short animations, and visible feedback drive the core game loop.

## Tech Stack
- **Frontend**: Flutter / Dart
- **Backend**: FastAPI / Python
- **Realtime Transport**: WebSockets
- **Database**: PostgreSQL (optional Redis for future caching/rate-limiting)

## Project Structure
- `frontend/` - Contains the Flutter mobile client application.
- `backend/` - Contains the FastAPI server, WebSocket logic, and database interactions.

## Core Gameplay Loop
1. **Room Creation/Join**: Players create or join a room using a unique room code.
2. **Title Creation**: The group collaboratively enters titles before the game starts. The number of titles must be at least the number of players.
3. **Random Turn**: The server randomly selects the next player (Assigner).
4. **Random Target**: The server randomly selects a target (different from the current Assigner).
5. **Title Assignment**: The current player selects a title from the available pool and explicitly reveals it to the group.
6. **Voting**: Eligible players (excluding Assigner and Target) vote *Agree* or *Disagree* within a realtime voting window.
7. **Resolution**: 
   - **Majority Agree**: The target gets the title and a score reward.
   - **Majority Disagree**: The title is rejected, and the assigner gets a penalty.
   - **Missed Vote**: Players who fail to vote within the timeframe receive a small score penalty.
8. **Scoring & Chat**: The game features real-time chat and server-authoritative scorekeeping. 

## Development Phases (MVP)
The development is structured to build the core online loop first:
1. Flutter setup, UI and onboarding.
2. FastAPI setup, auth, PostgreSQL.
3. Room creation and lobby management.
4. Collaborative title setup.
5. WebSocket connection and authoritative game state.
6. Random player/target selection.
7. Title selection, reveal, and voting mechanics.
8. Realtime chat, scoring, and leaderboards.

## Future Enhancements
- **Offline Mode**: Local peer-to-peer play for real-world gatherings.
- **Friend System**: Persistent friend lists, requests, and invites.
- **Title Packs**: Themed packs (e.g., programmer, sports, funny) and custom saved collections.
- **Advanced Game Modes**: Anonymous voting, team modes, secret titles, and spectator support for larger groups.

## Getting Started

### Frontend
```bash
cd frontend
flutter pub get
flutter run
```

### Backend
```bash
cd backend
# Recommended: Create a virtual environment
pip install -r requirements.txt
uvicorn main:app --reload
```
