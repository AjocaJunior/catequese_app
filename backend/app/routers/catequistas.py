from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from pydantic import BaseModel
from pymongo import ReturnDocument

from app.core.database import get_database
from app.core.deps import get_current_admin
from app.core.mongo_utils import object_id_or_404
from app.models.catequista import CatequistaOut

router = APIRouter(prefix="/catequistas", tags=["catequistas"])


class AlterarAdminBody(BaseModel):
    is_admin: bool


def _to_out(doc: dict) -> CatequistaOut:
    return CatequistaOut(
        id=str(doc["_id"]),
        nome=doc["nome"],
        email=doc["email"],
        is_admin=doc.get("is_admin", False),
        criado_em=doc["criado_em"],
    )


@router.get("", response_model=list[CatequistaOut])
async def listar_catequistas(
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    cursor = db.catequistas.find().sort("nome", 1)
    return [_to_out(doc) async for doc in cursor]


@router.patch("/{catequista_id}/admin", response_model=CatequistaOut)
async def alterar_admin(
    catequista_id: str,
    dados: AlterarAdminBody,
    db: AsyncIOMotorDatabase = Depends(get_database),
    admin_atual: CatequistaOut = Depends(get_current_admin),
):
    if catequista_id == admin_atual.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Não podes alterar a tua própria permissão de administrador",
        )

    oid = object_id_or_404(catequista_id)
    doc = await db.catequistas.find_one_and_update(
        {"_id": oid}, {"$set": {"is_admin": dados.is_admin}}, return_document=ReturnDocument.AFTER
    )
    if doc is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Catequista não encontrado")

    return _to_out(doc)
