from fastapi import APIRouter, Depends
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.database import get_database

router = APIRouter(tags=["health"])


@router.get("/health")
async def health_check(db: AsyncIOMotorDatabase = Depends(get_database)):
    mongo_status = "unknown"
    try:
        await db.command("ping")
        mongo_status = "ok"
    except Exception as exc:  # noqa: BLE001
        mongo_status = f"error: {exc}"

    return {
        "api": "ok",
        "mongodb": mongo_status,
    }
