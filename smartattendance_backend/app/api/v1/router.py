# app/api/v1/router.py
"""
API v1 router â€” aggregates all feature routers.
OCP: add a new feature router here without touching any other module.
"""
from fastapi import APIRouter

from app.api.v1.endpoints import auth, attendance, messages, qr, users

api_v1_router = APIRouter(prefix="/api/v1")

api_v1_router.include_router(auth.router)
api_v1_router.include_router(attendance.router)
api_v1_router.include_router(messages.router)
api_v1_router.include_router(qr.router)
api_v1_router.include_router(users.router)


