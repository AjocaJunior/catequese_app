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
from app.models.evento import EventoCreate, EventoOut, EventoUpdate

router = APIRouter(prefix="/eventos", tags=["eventos"])


def _to_out(doc: dict) -> EventoOut:
    return EventoOut(
        id=str(doc["_id"]),
        titulo=doc["titulo"],
        data=doc["data"].date(),
        local=doc.get("local"),
        descricao=doc.get("descricao"),
        criado_em=doc["criado_em"],
    )


@router.post("", response_model=EventoOut, status_code=status.HTTP_201_CREATED)
async def criar_evento(
    dados: EventoCreate,
    db: AsyncIOMotorDatabase = Depends(get_database),
    catequista: CatequistaOut = Depends(get_current_catequista),
):
    doc = {
        "titulo": dados.titulo.strip(),
        "data": datetime.combine(dados.data, datetime.min.time()),
        "local": (dados.local or "").strip() or None,
        "descricao": (dados.descricao or "").strip() or None,
        "criado_em": datetime.now(timezone.utc),
    }
    result = await db.eventos.insert_one(doc)
    doc["_id"] = result.inserted_id
    await registar(db, catequista, AcaoAuditoria.CRIAR, "Evento", str(result.inserted_id), f"Criou o evento '{doc['titulo']}'")
    return _to_out(doc)


@router.get("", response_model=list[EventoOut])
async def listar_eventos(
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_catequista),
):
    cursor = db.eventos.find().sort("data", 1)
    return [_to_out(doc) async for doc in cursor]


@router.put("/{evento_id}", response_model=EventoOut)
async def atualizar_evento(
    evento_id: str,
    dados: EventoUpdate,
    db: AsyncIOMotorDatabase = Depends(get_database),
    catequista: CatequistaOut = Depends(get_current_catequista),
):
    oid = object_id_or_404(evento_id)
    update_doc = dados.model_dump(exclude_unset=True)

    if "titulo" in update_doc:
        update_doc["titulo"] = update_doc["titulo"].strip()
    if "data" in update_doc and update_doc["data"] is not None:
        update_doc["data"] = datetime.combine(update_doc["data"], datetime.min.time())
    for campo in ("local", "descricao"):
        if campo in update_doc and update_doc[campo] is not None:
            update_doc[campo] = update_doc[campo].strip() or None

    if not update_doc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Nada para atualizar")

    doc = await db.eventos.find_one_and_update(
        {"_id": oid}, {"$set": update_doc}, return_document=ReturnDocument.AFTER
    )
    if doc is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Evento não encontrado")

    await registar(db, catequista, AcaoAuditoria.ATUALIZAR, "Evento", evento_id, f"Editou o evento '{doc['titulo']}'")

    return _to_out(doc)


@router.delete("/{evento_id}", status_code=status.HTTP_204_NO_CONTENT)
async def apagar_evento(
    evento_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    admin: CatequistaOut = Depends(get_current_admin),
):
    oid = object_id_or_404(evento_id)
    evento = await db.eventos.find_one({"_id": oid})
    result = await db.eventos.delete_one({"_id": oid})
    if result.deleted_count == 0:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Evento não encontrado")

    await registar(db, admin, AcaoAuditoria.APAGAR, "Evento", evento_id, f"Apagou o evento '{evento['titulo'] if evento else evento_id}'")
