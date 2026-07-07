from datetime import datetime, timezone

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from pymongo import ReturnDocument
from pymongo.errors import DuplicateKeyError

from app.core.ano_letivo import sincronizar_atribuicoes_fase
from app.core.database import get_database
from app.core.deps import get_current_admin, get_current_catequista
from app.core.mongo_utils import object_id_or_404
from app.models.catequista import CatequistaOut
from app.models.fase import (
    CatequistaResumo,
    DefinirCatequistasBody,
    FaseCreate,
    FaseOut,
    FaseUpdate,
)

router = APIRouter(prefix="/fases", tags=["fases"])


async def _to_out(db: AsyncIOMotorDatabase, doc: dict) -> FaseOut:
    ids = doc.get("catequista_ids", [])
    catequistas: list[CatequistaResumo] = []
    if ids:
        oids = [ObjectId(i) for i in ids if ObjectId.is_valid(i)]
        cursor = db.catequistas.find({"_id": {"$in": oids}}).sort("nome", 1)
        catequistas = [CatequistaResumo(id=str(c["_id"]), nome=c["nome"]) async for c in cursor]

    return FaseOut(
        id=str(doc["_id"]),
        nome=doc["nome"],
        ordem=doc["ordem"],
        nome_catecismo=doc.get("nome_catecismo"),
        dia_semana=doc.get("dia_semana"),
        hora=doc.get("hora"),
        local=doc.get("local"),
        programa_pdf_url=doc.get("programa_pdf_url"),
        catequistas=catequistas,
    )


@router.post("", response_model=FaseOut, status_code=status.HTTP_201_CREATED)
async def criar_fase(
    dados: FaseCreate,
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    if dados.ordem is None:
        ultima = await db.fases.find_one(sort=[("ordem", -1)])
        ordem = (ultima["ordem"] + 1) if ultima else 1
    else:
        ordem = dados.ordem

    doc = {
        "nome": dados.nome.strip(),
        "ordem": ordem,
        "nome_catecismo": (dados.nome_catecismo or "").strip() or None,
        "dia_semana": dados.dia_semana.value if dados.dia_semana else None,
        "hora": (dados.hora or "").strip() or None,
        "local": (dados.local or "").strip() or None,
        "programa_pdf_url": (dados.programa_pdf_url or "").strip() or None,
        "catequista_ids": [],
        "criado_em": datetime.now(timezone.utc),
    }
    try:
        result = await db.fases.insert_one(doc)
    except DuplicateKeyError:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT, detail="Já existe uma fase com este nome"
        )

    doc["_id"] = result.inserted_id
    return await _to_out(db, doc)


@router.get("", response_model=list[FaseOut])
async def listar_fases(
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_catequista),
):
    cursor = db.fases.find().sort("ordem", 1)
    return [await _to_out(db, doc) async for doc in cursor]


@router.put("/{fase_id}", response_model=FaseOut)
async def atualizar_fase(
    fase_id: str,
    dados: FaseUpdate,
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    oid = object_id_or_404(fase_id)
    update_doc = dados.model_dump(exclude_unset=True)
    if "nome" in update_doc:
        update_doc["nome"] = update_doc["nome"].strip()
    for campo in ("nome_catecismo", "hora", "local", "programa_pdf_url"):
        if campo in update_doc and update_doc[campo] is not None:
            update_doc[campo] = update_doc[campo].strip() or None
    if "dia_semana" in update_doc and update_doc["dia_semana"] is not None:
        update_doc["dia_semana"] = update_doc["dia_semana"].value

    if not update_doc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Nada para atualizar")

    try:
        doc = await db.fases.find_one_and_update(
            {"_id": oid}, {"$set": update_doc}, return_document=ReturnDocument.AFTER
        )
    except DuplicateKeyError:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT, detail="Já existe uma fase com este nome"
        )

    if doc is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Fase não encontrada")

    return await _to_out(db, doc)


@router.put("/{fase_id}/catequistas", response_model=FaseOut)
async def definir_catequistas_da_fase(
    fase_id: str,
    dados: DefinirCatequistasBody,
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    """Substitui a lista completa de catequistas atribuídos a esta fase.
    Uma fase pode ter vários catequistas (e um catequista pode estar em várias fases)."""
    fase_oid = object_id_or_404(fase_id)

    ids_validos: list[str] = []
    for cid in dados.catequista_ids:
        coid = object_id_or_404(cid)
        existe = await db.catequistas.find_one({"_id": coid})
        if existe is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail=f"Catequista '{cid}' não existe"
            )
        ids_validos.append(cid)

    doc = await db.fases.find_one_and_update(
        {"_id": fase_oid},
        {"$set": {"catequista_ids": ids_validos}},
        return_document=ReturnDocument.AFTER,
    )
    if doc is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Fase não encontrada")

    await sincronizar_atribuicoes_fase(db, fase_id, ids_validos)

    return await _to_out(db, doc)


@router.delete("/{fase_id}", status_code=status.HTTP_204_NO_CONTENT)
async def apagar_fase(
    fase_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    oid = object_id_or_404(fase_id)

    em_uso = await db.catequisandos.count_documents({"fase_id": fase_id})
    if em_uso > 0:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Não é possível apagar: existem {em_uso} catequisando(s) nesta fase",
        )

    result = await db.fases.delete_one({"_id": oid})
    if result.deleted_count == 0:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Fase não encontrada")
