from fastapi import APIRouter

from .endpoints import thought_graphs, auth

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["authentication"])
api_router.include_router(thought_graphs.router, prefix="/thought-graphs", tags=["thought-graphs"])
