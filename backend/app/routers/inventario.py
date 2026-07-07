from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from pymongo import ReturnDocument

from app.core.database import get_database
from app.core.deps import get_current_admin, get_current_catequista
from app.core.mongo_utils import object_id_or_404
from app.models.catequista import CatequistaOut
from app.models.inventario import ItemInventarioCreate, ItemInventarioOut, ItemInventarioUpdate

router = APIRouter(prefix="/inventario", tags=["inventário"])


def _to_out(doc: dict) -> ItemInventarioOut:
    return ItemInventarioOut(
        id=str(doc["_id"]),
        nome=doc["nome"],
        quantidade=doc["quantidade"],
        descricao=doc.get("descricao"),
        criado_em=doc["criado_em"],
    )


@router.post("", response_model=ItemInventarioOut, status_code=status.HTTP_201_CREATED)
async def criar_item(
    dados: ItemInventarioCreate,
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    doc = {
        "nome": dados.nome.strip(),
        "quantidade": dados.quantidade,
        "descricao": (dados.descricao or "").strip() or None,
        "criado_em": datetime.now(timezone.utc),
    }
    result = await db.inventario.insert_one(doc)
    doc["_id"] = result.inserted_id
    return _to_out(doc)


@router.get("", response_model=list[ItemInventarioOut])
async def listar_itens(
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_catequista),
):
    cursor = db.inventario.find().sort("nome", 1)
    return [_to_out(doc) async for doc in cursor]


@router.put("/{item_id}", response_model=ItemInventarioOut)
async def atualizar_item(
    item_id: str,
    dados: ItemInventarioUpdate,
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    oid = object_id_or_404(item_id)
    update_doc = dados.model_dump(exclude_unset=True)
    if "nome" in update_doc:
        update_doc["nome"] = update_doc["nome"].strip()
    if "descricao" in update_doc and update_doc["descricao"] is not None:
        update_doc["descricao"] = update_doc["descricao"].strip() or None

    if not update_doc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Nada para atualizar")

    doc = await db.inventario.find_one_and_update(
        {"_id": oid}, {"$set": update_doc}, return_document=ReturnDocument.AFTER
    )
    if doc is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Item não encontrado")

    return _to_out(doc)


@router.delete("/{item_id}", status_code=status.HTTP_204_NO_CONTENT)
async def apagar_item(
    item_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    oid = object_id_or_404(item_id)
    result = await db.inventario.delete_one({"_id": oid})
    if result.deleted_count == 0:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Item não encontrado")
