from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from pymongo import ReturnDocument

from app.core.database import get_database
from app.core.deps import get_current_admin, get_current_catequista
from app.core.mongo_utils import object_id_or_404
from app.models.catequista import CatequistaOut
from app.models.sector import SectorCreate, SectorOut, SectorUpdate

router = APIRouter(prefix="/sectores", tags=["sectores"])


async def _ministerio_nome_ou_erro(db: AsyncIOMotorDatabase, ministerio_id: str) -> str:
    oid = object_id_or_404(ministerio_id)
    ministerio = await db.ministerios.find_one({"_id": oid})
    if ministerio is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="O ministério indicado não existe")
    return ministerio["nome"]


async def _to_out(db: AsyncIOMotorDatabase, doc: dict) -> SectorOut:
    ministerio_nome = None
    ministerio_id = doc.get("ministerio_id")
    if ministerio_id:
        ministerio = await db.ministerios.find_one({"_id": object_id_or_404(ministerio_id)})
        ministerio_nome = ministerio["nome"] if ministerio else None

    return SectorOut(
        id=str(doc["_id"]),
        nome=doc["nome"],
        dia_semana=doc["dia_semana"],
        hora=doc["hora"],
        local=doc.get("local"),
        ministerio_id=ministerio_id,
        ministerio_nome=ministerio_nome,
        responsavel_nome=doc.get("responsavel_nome"),
        criado_em=doc["criado_em"],
    )


@router.post("", response_model=SectorOut, status_code=status.HTTP_201_CREATED)
async def criar_sector(
    dados: SectorCreate,
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_catequista),
):
    if dados.ministerio_id:
        await _ministerio_nome_ou_erro(db, dados.ministerio_id)

    doc = {
        "nome": dados.nome.strip(),
        "dia_semana": dados.dia_semana.value if dados.dia_semana else None,
        "hora": (dados.hora or "").strip() or None,
        "local": (dados.local or "").strip() or None,
        "ministerio_id": dados.ministerio_id,
        "responsavel_nome": (dados.responsavel_nome or "").strip() or None,
        "criado_em": datetime.now(timezone.utc),
    }
    result = await db.sectores.insert_one(doc)
    doc["_id"] = result.inserted_id
    return await _to_out(db, doc)


@router.get("", response_model=list[SectorOut])
async def listar_sectores(
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_catequista),
):
    cursor = db.sectores.find().sort("nome", 1)
    return [await _to_out(db, doc) async for doc in cursor]


@router.put("/{sector_id}", response_model=SectorOut)
async def atualizar_sector(
    sector_id: str,
    dados: SectorUpdate,
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_catequista),
):
    oid = object_id_or_404(sector_id)
    update_doc = dados.model_dump(exclude_unset=True)

    if "nome" in update_doc:
        update_doc["nome"] = update_doc["nome"].strip()
    if "hora" in update_doc and update_doc["hora"] is not None:
        update_doc["hora"] = update_doc["hora"].strip() or None
    if "dia_semana" in update_doc and update_doc["dia_semana"] is not None:
        update_doc["dia_semana"] = update_doc["dia_semana"].value
    if "local" in update_doc and update_doc["local"] is not None:
        update_doc["local"] = update_doc["local"].strip() or None
    if "responsavel_nome" in update_doc and update_doc["responsavel_nome"] is not None:
        update_doc["responsavel_nome"] = update_doc["responsavel_nome"].strip() or None
    if "ministerio_id" in update_doc and update_doc["ministerio_id"]:
        await _ministerio_nome_ou_erro(db, update_doc["ministerio_id"])

    if not update_doc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Nada para atualizar")

    doc = await db.sectores.find_one_and_update(
        {"_id": oid}, {"$set": update_doc}, return_document=ReturnDocument.AFTER
    )
    if doc is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Sector não encontrado")

    return await _to_out(db, doc)


@router.delete("/{sector_id}", status_code=status.HTTP_204_NO_CONTENT)
async def apagar_sector(
    sector_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    oid = object_id_or_404(sector_id)
    result = await db.sectores.delete_one({"_id": oid})
    if result.deleted_count == 0:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Sector não encontrado")
