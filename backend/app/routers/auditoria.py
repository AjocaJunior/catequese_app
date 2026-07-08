from fastapi import APIRouter, Depends, Query
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.database import get_database
from app.core.deps import get_current_admin
from app.models.auditoria import RegistoAuditoriaOut
from app.models.catequista import CatequistaOut

router = APIRouter(prefix="/auditoria", tags=["auditoria"])


@router.get("", response_model=list[RegistoAuditoriaOut])
async def listar_auditoria(
    entidade: str | None = Query(None),
    catequista_id: str | None = Query(None),
    limite: int = Query(300, le=2000),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    filtro: dict = {}
    if entidade:
        filtro["entidade"] = entidade
    if catequista_id:
        filtro["catequista_id"] = catequista_id

    cursor = db.auditoria.find(filtro).sort("data", -1).limit(limite)
    resultado = []
    async for doc in cursor:
        resultado.append(RegistoAuditoriaOut(
            id=str(doc["_id"]),
            data=doc["data"],
            catequista_id=doc.get("catequista_id"),
            catequista_nome=doc["catequista_nome"],
            acao=doc["acao"],
            entidade=doc["entidade"],
            entidade_id=doc.get("entidade_id"),
            resumo=doc["resumo"],
        ))
    return resultado


@router.get("/entidades", response_model=list[str])
async def listar_entidades(
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    """Lista as entidades distintas já registadas, para preencher um filtro."""
    return sorted(await db.auditoria.distinct("entidade"))
