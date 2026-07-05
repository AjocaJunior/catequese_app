"""
Gestão da ligação ao MongoDB (via Motor, driver assíncrono).
A ligação é criada uma vez no arranque da aplicação (ver main.py -> lifespan)
e reutilizada em todos os pedidos.
"""
import certifi
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase

from app.core.config import get_settings

settings = get_settings()


class MongoDB:
    client: AsyncIOMotorClient | None = None
    db: AsyncIOMotorDatabase | None = None


mongodb = MongoDB()


async def connect_to_mongo() -> None:
    # tlsCAFile=certifi.where() evita erros de SSL handshake comuns no Windows,
    # onde a cadeia de certificados do sistema por vezes não é reconhecida corretamente.
    mongodb.client = AsyncIOMotorClient(
        settings.MONGODB_URI,
        tlsCAFile=certifi.where(),
        serverSelectionTimeoutMS=10000,
    )
    mongodb.db = mongodb.client[settings.DB_NAME]


async def close_mongo_connection() -> None:
    if mongodb.client:
        mongodb.client.close()


async def ensure_indexes() -> None:
    """Cria índices necessários. Chamado uma vez no arranque da aplicação."""
    await mongodb.db.catequistas.create_index("email", unique=True)
    await mongodb.db.fases.create_index("nome", unique=True)
    await mongodb.db.fases.create_index("catequista_ids")
    await mongodb.db.catequisandos.create_index("fase_id")
    await mongodb.db.catequisandos.create_index("nome")
    await mongodb.db.presencas.create_index([("catequisando_id", 1), ("data", 1)], unique=True)
    await mongodb.db.presencas.create_index([("fase_id", 1), ("data", 1)])
    await mongodb.db.retiros.create_index("data")
    await mongodb.db.eventos.create_index("data")
    await mongodb.db.sectores.create_index("nome")
    await mongodb.db.ministerios.create_index("nome")
    await mongodb.db.catequisandos.create_index("sector_id")


def get_database() -> AsyncIOMotorDatabase:
    """Dependency para usar nos routers: db = Depends(get_database)"""
    return mongodb.db
