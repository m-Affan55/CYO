from typing import Dict, Any
import logging
import random

logger = logging.getLogger(__name__)

class GameEngine:
    def __init__(self):
        # room_id -> game_state dict
        self.games: Dict[str, Dict[str, Any]] = {}

    def init_game(self, room_id: str, users: list, max_rounds: int = 3, timer: int = 30):
        # Users is a list of user IDs
        self.games[room_id] = {
            "phase": "TITLE_CREATION",
            "titles": [], # list of dicts: {"author_id": user_id, "text": title}
            "assigner_id": None,
            "target_id": None,
            "selected_title": None,
            "votes": {}, # user_id -> boolean
            "players": users, # list of user IDs
            "round": 1,
            "max_rounds": max_rounds,
            "timer": timer,
            "used_titles": [],
            "assigned_this_round": [],
        }

    def get_state(self, room_id: str) -> dict:
        return self.games.get(room_id, {})

    def update_players(self, room_id: str, users: list):
        if room_id in self.games:
            self.games[room_id]["players"] = users

    def submit_title(self, room_id: str, user_id: str, title: str) -> bool:
        """Adds a title. Returns False since we wait for explicit start."""
        if room_id not in self.games:
            return False
        
        self.games[room_id]["titles"].append({"author_id": user_id, "text": title})
        return False

    def select_assigner(self, room_id: str):
        state = self.games.get(room_id)
        if state:
            available = [p for p in state["players"] if p not in state["assigned_this_round"]]
            if not available: # Fallback just in case
                available = state["players"]
            assigner_id = random.choice(available)
            state["assigner_id"] = assigner_id
            state["assigned_this_round"].append(assigner_id)
            state["phase"] = "SELECTING_TARGET"
            return assigner_id

    def select_target(self, room_id: str):
        state = self.games.get(room_id)
        if state:
            assigner_id = state.get("assigner_id")
            possible_targets = [p for p in state["players"] if p != assigner_id]
            target_id = random.choice(possible_targets) if possible_targets else assigner_id
            state["target_id"] = target_id
            state["phase"] = "TITLE_SELECTION"
            return target_id

    def select_title(self, room_id: str, title: str):
        state = self.games.get(room_id)
        if state:
            state["selected_title"] = title
            state["phase"] = "VOTING"
            state["votes"] = {}

    def force_finish_voting(self, room_id: str):
        state = self.games.get(room_id)
        if state:
            state["phase"] = "ROUND_RESULTS"

    def next_round(self, room_id: str) -> bool:
        """Returns True if there is a next turn/round, False if game over."""
        state = self.games.get(room_id)
        if not state:
            return False
            
        current_round = state.get("round", 1)
        max_rounds = state.get("max_rounds", 3)
        
        # Mark title as used
        title = state.get("selected_title")
        if title and title not in state["used_titles"]:
            state["used_titles"].append(title)
            
        # Recycle titles if all used
        if len(state["used_titles"]) >= len(state["titles"]):
            state["used_titles"] = []
            
        state["phase"] = "SELECTING_ASSIGNER"
        state["assigner_id"] = None
        state["target_id"] = None
        state["selected_title"] = None
        state["votes"] = {}
        
        # Check if everyone has been assigner this round
        if len(state["assigned_this_round"]) >= len(state["players"]):
            if current_round >= max_rounds:
                state["phase"] = "GAME_OVER"
                return False
            
            state["round"] = current_round + 1
            state["assigned_this_round"] = []
            
        return True

    def submit_vote(self, room_id: str, user_id: str, vote: bool) -> bool:
        """Returns True if all eligible voters have voted."""
        if room_id not in self.games:
            return False
            
        self.games[room_id]["votes"][user_id] = vote
        
        # Eligible voters = total players - assigner - target
        eligible_voters = len(self.games[room_id]["players"]) - 2
        # If there are 3 players, 1 assigner, 1 target, 1 voter.
        # If there are 2 players... well, game needs at least 3 to vote.
        if eligible_voters <= 0:
            eligible_voters = 1
            
        if len(self.games[room_id]["votes"]) >= eligible_voters:
            self.games[room_id]["phase"] = "ROUND_RESULTS"
            return True
            
        return False

    def calculate_results(self, room_id: str) -> dict:
        """Calculates points. If majority votes True, Target +100, Assigner +50. If False, Assigner -50."""
        state = self.games.get(room_id)
        if not state:
            return {}
            
        votes = state["votes"].values()
        yes_votes = sum(1 for v in votes if v)
        no_votes = len(votes) - yes_votes
        
        majority_agrees = yes_votes > no_votes
        
        target_pts = 100 if majority_agrees else 0
        assigner_pts = 50 if majority_agrees else -50
        
        return {
            "majority_agrees": majority_agrees,
            "target_id": state["target_id"],
            "assigner_id": state["assigner_id"],
            "target_points": target_pts,
            "assigner_points": assigner_pts,
        }

engine = GameEngine()
