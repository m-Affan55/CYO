from typing import Dict, Any, Optional
import logging
import random
import uuid

logger = logging.getLogger(__name__)

class GameEngine:
    def __init__(self):
        # room_id -> game_state dict
        self.games: Dict[str, Dict[str, Any]] = {}

    def init_game(self, room_id: str, users: list, max_rounds: int = 3, timer: int = 30, secret_mode: bool = False):
        """Initialize a brand-new game for a room."""
        self.games[room_id] = {
            "phase": "TITLE_CREATION",
            "titles": [],                    # [{author_id, text}]
            "assigner_id": None,
            "target_id": None,
            "selected_title": None,
            "votes": {},                     # user_id -> "agree"|"disagree"|"neutral"
            "players": list(users),          # list of connected user IDs
            "round": 1,
            "max_rounds": max_rounds,
            "timer": timer,
            "secret_mode": secret_mode,
            "used_titles": [],
            "assigned_this_round": [],
            # BUG-1: guards zombie voting timers
            "voting_id": None,
            # BUG-15: guards zombie selection timers
            "selection_timer_id": None,
            # MISSING-3: last turn summary for results screen
            "last_results": None,
            "voting_ends_at": None,
        }

    def get_state(self, room_id: str) -> dict:
        return self.games.get(room_id, {})

    def update_players(self, room_id: str, users: list):
        """Update the in-memory player list (used on initial connection sync)."""
        if room_id in self.games:
            self.games[room_id]["players"] = list(users)

    # ─── BUG-2: Remove a player from the live game ───────────────────────────

    def remove_player(self, room_id: str, user_id: str) -> dict:
        """
        Remove a player who disconnected from the in-memory game.
        Returns a dict describing what changed so the caller can react.
        """
        state = self.games.get(room_id)
        if not state or user_id not in state["players"]:
            return {"removed": False}

        state["players"].remove(user_id)

        # Clean up their assignment history so round math stays correct
        if user_id in state["assigned_this_round"]:
            state["assigned_this_round"].remove(user_id)

        # Remove any vote they already cast (doesn't matter much but keeps state clean)
        state["votes"].pop(user_id, None)

        was_assigner = state.get("assigner_id") == user_id
        was_target   = state.get("target_id")   == user_id

        return {
            "removed": True,
            "was_assigner": was_assigner,
            "was_target": was_target,
            "remaining_players": len(state["players"]),
        }

    # ─── BUG-5: Submit a title with duplicate + cap guard ────────────────────

    def submit_title(self, room_id: str, user_id: str, title: str) -> dict:
        """
        Adds a title to the pool.
        Returns {"success": True} or {"success": False, "error": "..."}
        """
        if room_id not in self.games:
            return {"success": False, "error": "Game not found"}

        state = self.games[room_id]
        title_stripped = title.strip()

        if not title_stripped:
            return {"success": False, "error": "Title cannot be empty"}

        # Duplicate text guard (case-insensitive)
        existing_texts = [t["text"].lower() for t in state["titles"]]
        if title_stripped.lower() in existing_texts:
            return {"success": False, "error": "This title already exists in the pool"}

        # Per-player cap of 5
        player_count = sum(1 for t in state["titles"] if t["author_id"] == user_id)
        if player_count >= 5:
            return {"success": False, "error": "You can submit at most 5 titles"}

        state["titles"].append({"author_id": user_id, "text": title_stripped})
        return {"success": True}

    # ─── Assigner / target selection ─────────────────────────────────────────

    def select_assigner(self, room_id: str) -> Optional[str]:
        state = self.games.get(room_id)
        if not state:
            return None

        available = [p for p in state["players"] if p not in state["assigned_this_round"]]
        if not available:
            # BUG-9: Don't fall back to full list — this means the round is over
            logger.warning(f"select_assigner: no available players in room {room_id}, all assigned.")
            return None

        assigner_id = random.choice(available)
        state["assigner_id"] = assigner_id
        state["assigned_this_round"].append(assigner_id)
        state["phase"] = "SELECTING_TARGET"
        return assigner_id

    def select_target(self, room_id: str) -> Optional[str]:
        state = self.games.get(room_id)
        if not state:
            return None

        assigner_id = state.get("assigner_id")
        possible_targets = [p for p in state["players"] if p != assigner_id]
        if not possible_targets:
            return None

        target_id = random.choice(possible_targets)
        state["target_id"] = target_id
        state["phase"] = "TITLE_SELECTION"

        # BUG-15: Generate a new selection_timer_id every time we enter TITLE_SELECTION
        state["selection_timer_id"] = str(uuid.uuid4())
        return target_id

    # ─── BUG-15: Auto-select title for AFK assigner ──────────────────────────

    def auto_select_title(self, room_id: str) -> Optional[str]:
        """Randomly pick an available title when the assigner goes AFK."""
        state = self.games.get(room_id)
        if not state or state.get("phase") != "TITLE_SELECTION":
            return None

        used = state.get("used_titles", [])
        available = [t["text"] for t in state["titles"] if t["text"] not in used]

        if not available:
            # Recycle
            state["used_titles"] = []
            available = [t["text"] for t in state["titles"]]

        if not available:
            return None

        return random.choice(available)

    def select_title(self, room_id: str, title: str) -> Optional[str]:
        """
        Assigner picks a title → enter VOTING phase.
        Returns the new voting_id (BUG-1).
        """
        state = self.games.get(room_id)
        if not state:
            return None

        state["selected_title"] = title
        state["phase"] = "VOTING"
        state["votes"] = {}
        state["selection_timer_id"] = None  # Invalidate selection timer

        # BUG-1: New voting_id for every vote — kills zombie timers
        new_voting_id = str(uuid.uuid4())
        state["voting_id"] = new_voting_id
        return new_voting_id

    def force_finish_voting(self, room_id: str):
        state = self.games.get(room_id)
        if state:
            state["phase"] = "ROUND_RESULTS"

    # ─── Round lifecycle ──────────────────────────────────────────────────────

    def next_round(self, room_id: str) -> bool:
        """Returns True if there is a next turn, False if game over."""
        state = self.games.get(room_id)
        if not state:
            return False

        current_round = state.get("round", 1)
        max_rounds    = state.get("max_rounds", 3)

        # Mark title as used
        title = state.get("selected_title")
        if title and title not in state["used_titles"]:
            state["used_titles"].append(title)

        # Recycle when pool exhausted
        if len(state["used_titles"]) >= len(state["titles"]):
            state["used_titles"] = []

        # Reset turn-level state
        state["phase"]             = "SELECTING_ASSIGNER"
        state["assigner_id"]       = None
        state["target_id"]         = None
        state["selected_title"]    = None
        state["votes"]             = {}
        state["voting_id"]         = None
        state["selection_timer_id"] = None
        state["last_results"]      = None
        state["voting_ends_at"]    = None

        # Check if everyone has been assigner this round
        if len(state["assigned_this_round"]) >= len(state["players"]):
            if current_round >= max_rounds:
                state["phase"] = "GAME_OVER"
                return False
            state["round"] = current_round + 1
            state["assigned_this_round"] = []

        return True

    # ─── Voting ──────────────────────────────────────────────────────────────

    def submit_vote(self, room_id: str, user_id: str, vote: str) -> bool:
        """Returns True if all eligible voters have voted."""
        if room_id not in self.games:
            return False

        state = self.games[room_id]

        if state.get("phase") != "VOTING":
            return False

        assigner_id = state.get("assigner_id")
        target_id   = state.get("target_id")

        # Assigner and target cannot vote
        if user_id in (assigner_id, target_id):
            return False

        state["votes"][user_id] = vote

        # Eligible voters = all connected players minus assigner and target
        eligible = [p for p in state["players"] if p not in (assigner_id, target_id)]

        if len(state["votes"]) >= len(eligible):
            state["phase"] = "ROUND_RESULTS"
            return True

        return False

    def calculate_results(self, room_id: str) -> dict:
        state = self.games.get(room_id)
        if not state:
            return {}

        votes = state["votes"].values()
        agree_count    = sum(1 for v in votes if v == "agree")
        disagree_count = sum(1 for v in votes if v == "disagree")
        # Neutral votes are abstentions — ignored for majority calc

        majority_agrees = agree_count > disagree_count

        target_pts   = 100 if majority_agrees else 0
        assigner_pts = 50  if majority_agrees else -50

        target_id   = state.get("target_id")
        assigner_id = state.get("assigner_id")
        eligible    = [p for p in state["players"] if p not in (target_id, assigner_id)]
        missed      = [p for p in eligible if p not in state["votes"]]

        results = {
            "majority_agrees":  majority_agrees,
            "agree_count":      agree_count,
            "disagree_count":   disagree_count,
            "target_id":        target_id,
            "assigner_id":      assigner_id,
            "selected_title":   state.get("selected_title"),
            "target_points":    target_pts,
            "assigner_points":  assigner_pts,
            "missed_voters":    missed,
            "missed_penalty":   -10,
        }

        # MISSING-3: Persist for the results screen
        state["last_results"] = results
        return results

    # ─── MISSING-1: Play Again ────────────────────────────────────────────────

    def reset_game(self, room_id: str) -> bool:
        """Reset to TITLE_CREATION for a rematch with the same players."""
        state = self.games.get(room_id)
        if not state:
            return False

        state["phase"]              = "TITLE_CREATION"
        state["titles"]             = []
        state["assigner_id"]        = None
        state["target_id"]          = None
        state["selected_title"]     = None
        state["votes"]              = {}
        state["round"]              = 1
        state["used_titles"]        = []
        state["assigned_this_round"] = []
        state["voting_id"]          = None
        state["selection_timer_id"] = None
        state["last_results"]       = None
        state["voting_ends_at"]     = None
        return True


engine = GameEngine()
