from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from pymongo import ReturnDocument

from app.core.auditoria import registar
from app.core.database import get_database
from app.core.deps import get_current_admin, get_current_catequista
from app.core.mongo_utils import object_id_or_404
from app.models.auditoria import AcaoAuditoria
from app.models.catequista import CatequistaOut
from app.models.ministerio import MinisterioCreate, MinisterioOut, MinisterioUpdate

router = APIRouter(prefix="/ministerios", tags=["ministérios"])


def _to_out(doc: dict) -> MinisterioOut:
    return MinisterioOut(
        id=str(doc["_id"]),
        nome=doc["nome"],
        coordenador_nome=doc.get("coordenador_nome"),
        criado_em=doc["criado_em"],
    )


@router.post("", response_model=MinisterioOut, status_code=status.HTTP_201_CREATED)
async def criar_ministerio(
    dados: MinisterioCreate,
    db: AsyncIOMotorDatabase = Depends(get_database),
    catequista: CatequistaOut = Depends(get_current_catequista),
):
    doc = {
        "nome": dados.nome.strip(),
        "coordenador_nome": (dados.coordenador_nome or "").strip() or None,
        "criado_em": datetime.now(timezone.utc),
    }
    result = await db.ministerios.insert_one(doc)
    doc["_id"] = result.inserted_id
    await registar(db, catequista, AcaoAuditoria.CRIAR, "Ministério", str(result.inserted_id), f"Criou o ministério '{doc['nome']}'")
    return _to_out(doc)


@router.get("", response_model=list[MinisterioOut])
async def listar_ministerios(
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_catequista),
):
    cursor = db.ministerios.find().sort("nome", 1)
    return [_to_out(doc) async for doc in cursor]


@router.put("/{ministerio_id}", response_model=MinisterioOut)
async def atualizar_ministerio(
    ministerio_id: str,
    dados: MinisterioUpdate,
    db: AsyncIOMotorDatabase = Depends(get_database),
    catequista: CatequistaOut = Depends(get_current_catequista),
):
    oid = object_id_or_404(ministerio_id)
    update_doc = dados.model_dump(exclude_unset=True)

    if "nome" in update_doc:
        update_doc["nome"] = update_doc["nome"].strip()
    if "coordenador_nome" in update_doc and update_doc["coordenador_nome"] is not None:
        update_doc["coordenador_nome"] = update_doc["coordenador_nome"].strip() or None

    if not update_doc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Nada para atualizar")

    doc = await db.ministerios.find_one_and_update(
        {"_id": oid}, {"$set": update_doc}, return_document=ReturnDocument.AFTER
    )
    if doc is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ministério não encontrado")

    await registar(db, catequista, AcaoAuditoria.ATUALIZAR, "Ministério", ministerio_id, f"Editou o ministério '{doc['nome']}'")

    return _to_out(doc)


@router.delete("/{ministerio_id}", status_code=status.HTTP_204_NO_CONTENT)
async def apagar_ministerio(
    ministerio_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    admin: CatequistaOut = Depends(get_current_admin),
):
    oid = object_id_or_404(ministerio_id)
    ministerio = await db.ministerios.find_one({"_id": oid})

    em_uso = await db.sectores.count_documents({"ministerio_id": ministerio_id})
    if em_uso > 0:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Não é possível apagar: existem {em_uso} sector(es) associados a este ministério",
        )

    result = await db.ministerios.delete_one({"_id": oid})
    if result.deleted_count == 0:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Ministério não encontrado")

    await registar(db, admin, AcaoAuditoria.APAGAR, "Ministério", ministerio_id, f"Apagou o ministério '{ministerio['nome'] if ministerio else ministerio_id}'")
