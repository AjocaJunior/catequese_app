from fastapi import HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.mongo_utils import object_id_or_404
from app.models.catequista import CatequistaOut


async def garantir_acesso_fase(db: AsyncIOMotorDatabase, fase_id: str, catequista: CatequistaOut) -> dict:
    """Confirma que a fase existe e que o catequista pode aceder a ela
    (admin acede a tudo; catequista comum só às fases a que está atribuído).
    Devolve o documento da fase se o acesso for permitido."""
    fase_oid = object_id_or_404(fase_id)
    fase = await db.fases.find_one({"_id": fase_oid})
    if fase is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="A fase indicada não existe")

    if not catequista.is_admin and catequista.id not in fase.get("catequista_ids", []):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Não estás atribuído a esta fase",
        )

    return fase
