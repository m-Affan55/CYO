from fastapi import APIRouter
from api.routes.room import router as room_router
from api.routes.game import router as game_router

api_router = APIRouter()
api_router.include_router(room_router)
api_router.include_router(game_router)
