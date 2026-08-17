from fastapi import APIRouter
from api.routes.room import router as room_router
from api.routes.game import router as game_router
from api.routes.auth import router as auth_router
from api.routes.friends import router as friends_router
from api.routes.invites import router as invites_router

api_router = APIRouter()
api_router.include_router(auth_router)
api_router.include_router(room_router)
api_router.include_router(game_router)
api_router.include_router(friends_router)
api_router.include_router(invites_router)
