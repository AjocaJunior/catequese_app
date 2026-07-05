from datetime import datetime, timezone

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, Response, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from pymongo import ReturnDocument

from app.core.database import get_database
from app.core.deps import get_current_admin, get_current_catequista
from app.core.mongo_utils import object_id_or_404
from app.models.catequista import CatequistaOut
from app.models.retiro import (
    FaseResumo,
    ProgramaItem,
    RetiroCreate,
    RetiroOut,
    RetiroUpdate,
    SectorResumoRetiro,
)
from app.services.pdf_retiro import gerar_pdf_retiro

router = APIRouter(prefix="/retiros", tags=["retiros"])


async def _fases_resumo(db: AsyncIOMotorDatabase, fase_ids: list[str]) -> list[FaseResumo]:
    if not fase_ids:
        return []
    oids = [ObjectId(i) for i in fase_ids if ObjectId.is_valid(i)]
    cursor = db.fases.find({"_id": {"$in": oids}}).sort("ordem", 1)
    return [FaseResumo(id=str(f["_id"]), nome=f["nome"]) async for f in cursor]


async def _sectores_resumo(db: AsyncIOMotorDatabase, sector_ids: list[str]) -> list[SectorResumoRetiro]:
    if not sector_ids:
        return []
    oids = [ObjectId(i) for i in sector_ids if ObjectId.is_valid(i)]
    cursor = db.sectores.find({"_id": {"$in": oids}}).sort("nome", 1)
    return [SectorResumoRetiro(id=str(s["_id"]), nome=s["nome"]) async for s in cursor]


async def _validar_fases(db: AsyncIOMotorDatabase, fase_ids: list[str]) -> None:
    for fid in fase_ids:
        oid = object_id_or_404(fid)
        fase = await db.fases.find_one({"_id": oid})
        if fase is None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"A fase '{fid}' não existe")


async def _validar_sectores(db: AsyncIOMotorDatabase, sector_ids: list[str]) -> None:
    for sid in sector_ids:
        oid = object_id_or_404(sid)
        sector = await db.sectores.find_one({"_id": oid})
        if sector is None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"O sector '{sid}' não existe")


async def _to_out(db: AsyncIOMotorDatabase, doc: dict) -> RetiroOut:
    fases = await _fases_resumo(db, doc.get("fase_ids", []))
    sectores = await _sectores_resumo(db, doc.get("sector_ids", []))
    return RetiroOut(
        id=str(doc["_id"]),
        titulo=doc["titulo"],
        fases=fases,
        sectores=sectores,
        data=doc["data"].date(),
        local=doc["local"],
        oradores=doc.get("oradores", []),
        tema=doc.get("tema", ""),
        programa=[ProgramaItem(**p) for p in doc.get("programa", [])],
        criado_em=doc["criado_em"],
    )


@router.post("", response_model=RetiroOut, status_code=status.HTTP_201_CREATED)
async def criar_retiro(
    dados: RetiroCreate,
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_catequista),
):
    await _validar_fases(db, dados.fase_ids)
    await _validar_sectores(db, dados.sector_ids)

    doc = {
        "titulo": dados.titulo.strip(),
        "fase_ids": dados.fase_ids,
        "sector_ids": dados.sector_ids,
        "data": datetime.combine(dados.data, datetime.min.time()),
        "local": dados.local.strip(),
        "oradores": [o.strip() for o in dados.oradores if o.strip()],
        "tema": dados.tema.strip(),
        "programa": [p.model_dump() for p in dados.programa],
        "criado_em": datetime.now(timezone.utc),
    }
    result = await db.retiros.insert_one(doc)
    doc["_id"] = result.inserted_id
    return await _to_out(db, doc)


@router.get("", response_model=list[RetiroOut])
async def listar_retiros(
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_catequista),
):
    cursor = db.retiros.find().sort("data", -1)
    return [await _to_out(db, doc) async for doc in cursor]


@router.get("/{retiro_id}", response_model=RetiroOut)
async def obter_retiro(
    retiro_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_catequista),
):
    oid = object_id_or_404(retiro_id)
    doc = await db.retiros.find_one({"_id": oid})
    if doc is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Retiro não encontrado")
    return await _to_out(db, doc)


@router.put("/{retiro_id}", response_model=RetiroOut)
async def atualizar_retiro(
    retiro_id: str,
    dados: RetiroUpdate,
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_catequista),
):
    oid = object_id_or_404(retiro_id)
    update_doc = dados.model_dump(exclude_unset=True)

    if "fase_ids" in update_doc:
        await _validar_fases(db, update_doc["fase_ids"])
    if "sector_ids" in update_doc:
        await _validar_sectores(db, update_doc["sector_ids"])
    if "titulo" in update_doc:
        update_doc["titulo"] = update_doc["titulo"].strip()
    if "local" in update_doc:
        update_doc["local"] = update_doc["local"].strip()
    if "oradores" in update_doc:
        update_doc["oradores"] = [o.strip() for o in update_doc["oradores"] if o.strip()]
    if "tema" in update_doc:
        update_doc["tema"] = update_doc["tema"].strip()
    if "data" in update_doc:
        update_doc["data"] = datetime.combine(update_doc["data"], datetime.min.time())

    if not update_doc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Nada para atualizar")

    doc = await db.retiros.find_one_and_update(
        {"_id": oid}, {"$set": update_doc}, return_document=ReturnDocument.AFTER
    )
    if doc is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Retiro não encontrado")

    return await _to_out(db, doc)


@router.delete("/{retiro_id}", status_code=status.HTTP_204_NO_CONTENT)
async def apagar_retiro(
    retiro_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    oid = object_id_or_404(retiro_id)
    result = await db.retiros.delete_one({"_id": oid})
    if result.deleted_count == 0:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Retiro não encontrado")


@router.get("/{retiro_id}/pdf")
async def gerar_pdf(
    retiro_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_catequista),
):
    oid = object_id_or_404(retiro_id)
    doc = await db.retiros.find_one({"_id": oid})
    if doc is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Retiro não encontrado")

    fases = await _fases_resumo(db, doc.get("fase_ids", []))
    sectores = await _sectores_resumo(db, doc.get("sector_ids", []))
    pdf_bytes = gerar_pdf_retiro(doc, [f.nome for f in fases], [s.nome for s in sectores])

    nome_ficheiro = "".join(ch if ch.isalnum() else "_" for ch in doc["titulo"]) + ".pdf"
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'inline; filename="{nome_ficheiro}"'},
    )
