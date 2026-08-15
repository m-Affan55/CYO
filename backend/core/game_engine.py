from typing import Dict, Any
import logging

logger = logging.getLogger(__name__)

class GameEngine:
    def __init__(self):
        # room_id -> game_state dict
        self.games: Dict[str, Dict[str, Any]] = {}

    def init_game(self, room_id: str, users: list):
        # Users is a list of user IDs
        self.games[room_id] = {
            "phase": "TITLE_CREATION",
            "titles": {}, # user_id -> title string
            "assigner_id": None,
            "target_id": None,
            "selected_title": None,
            "votes": {}, # user_id -> boolean
            "players": users, # list of user IDs
        }

    def get_state(self, room_id: str) -> dict:
        return self.games.get(room_id, {})

    def submit_title(self, room_id: str, user_id: str, title: str) -> bool:
        """Returns True if all players have submitted a title."""
        if room_id not in self.games:
            return False
        
        self.games[room_id]["titles"][user_id] = title
        
        # Check if everyone submitted
        if len(self.games[room_id]["titles"]) >= len(self.games[room_id]["players"]):
            self.games[room_id]["phase"] = "SELECTING_ASSIGNER"
            return True
        return False

    def select_assigner(self, room_id: str, assigner_id: str):
        if room_id in self.games:
            self.games[room_id]["assigner_id"] = assigner_id
            self.games[room_id]["phase"] = "SELECTING_TARGET"

    def select_target_and_title(self, room_id: str, target_id: str, title: str):
        if room_id in self.games:
            self.games[room_id]["target_id"] = target_id
            self.games[room_id]["selected_title"] = title
            self.games[room_id]["phase"] = "VOTING"
            self.games[room_id]["votes"] = {}

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
