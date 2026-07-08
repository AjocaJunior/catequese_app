from fastapi import APIRouter, Depends, HTTPException, Response, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from pydantic import BaseModel
from pymongo import ReturnDocument

from app.core.auditoria import registar
from app.core.catequista_helpers import construir_catequista_completo
from app.core.database import get_database
from app.core.deps import get_current_admin, get_current_catequista
from app.core.mongo_utils import object_id_or_404
from app.models.auditoria import AcaoAuditoria
from app.models.catequista import CatequistaOut
from app.services.pdf_lista_catequistas import gerar_pdf_lista_catequistas

router = APIRouter(prefix="/catequistas", tags=["catequistas"])


class AlterarAdminBody(BaseModel):
    is_admin: bool


@router.get("", response_model=list[CatequistaOut])
async def listar_catequistas(
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    cursor = db.catequistas.find().sort("nome", 1)
    return [await construir_catequista_completo(db, doc) async for doc in cursor]


@router.get("/pdf")
async def gerar_pdf(
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_catequista),
):
    """Lista de catequistas, uma linha por catequista/fase, pronta a imprimir."""
    catequistas_por_id = {}
    async for c in db.catequistas.find():
        catequistas_por_id[str(c["_id"])] = {"nome": c["nome"], "contacto": c.get("contacto")}

    fases_com_catequistas = []
    async for fase in db.fases.find().sort("ordem", 1):
        catequistas_da_fase = [
            catequistas_por_id[cid] for cid in fase.get("catequista_ids", []) if cid in catequistas_por_id
        ]
        fases_com_catequistas.append({
            "ordem": fase["ordem"],
            "nome": fase["nome"],
            "dia_semana": fase.get("dia_semana"),
            "hora": fase.get("hora"),
            "local": fase.get("local"),
            "catequistas": sorted(catequistas_da_fase, key=lambda c: c["nome"]),
        })

    pdf_bytes = gerar_pdf_lista_catequistas(fases_com_catequistas)
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": 'inline; filename="lista_catequistas.pdf"'},
    )


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

    await registar(
        db, admin_atual, AcaoAuditoria.ATUALIZAR, "Catequista", catequista_id,
        f"{'Promoveu' if dados.is_admin else 'Removeu admin de'} '{doc['nome']}'"
        f"{' a administrador' if dados.is_admin else ''}",
    )

    return await construir_catequista_completo(db, doc)
