from datetime import datetime, timezone
from io import BytesIO

from bson import Binary
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from PIL import Image as PILImage

from app.core.database import get_database
from app.core.deps import get_current_admin, get_current_catequista
from app.core.mongo_utils import object_id_or_404
from app.models.catequista import CatequistaOut
from app.models.foto import FotoOut

router = APIRouter(prefix="/fotos", tags=["fotos"])

LARGURA_MAX = 1280  # px — suficiente para um carrossel, mantém o ficheiro leve


def comprimir_imagem(conteudo: bytes) -> bytes:
    img = PILImage.open(BytesIO(conteudo))
    img = img.convert("RGB")
    if img.width > LARGURA_MAX:
        nova_altura = round(img.height * (LARGURA_MAX / img.width))
        img = img.resize((LARGURA_MAX, nova_altura), PILImage.LANCZOS)
    buffer = BytesIO()
    img.save(buffer, "JPEG", quality=80, optimize=True)
    return buffer.getvalue()


def foto_to_out(doc: dict) -> FotoOut:
    return FotoOut(id=str(doc["_id"]), titulo=doc.get("titulo"), criado_em=doc["criado_em"])


@router.post("", response_model=FotoOut, status_code=status.HTTP_201_CREATED)
async def enviar_foto(
    imagem: UploadFile = File(...),
    titulo: str | None = Form(None),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_catequista),
):
    conteudo = await imagem.read()
    try:
        comprimida = comprimir_imagem(conteudo)
    except Exception:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Ficheiro de imagem inválido")

    doc = {
        "titulo": (titulo or "").strip() or None,
        "imagem": Binary(comprimida),
        "criado_em": datetime.now(timezone.utc),
    }
    result = await db.fotos.insert_one(doc)
    doc["_id"] = result.inserted_id
    return foto_to_out(doc)


@router.get("", response_model=list[FotoOut])
async def listar_fotos(
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_catequista),
):
    cursor = db.fotos.find({}, {"imagem": 0}).sort("criado_em", -1)
    return [foto_to_out(doc) async for doc in cursor]


@router.delete("/{foto_id}", status_code=status.HTTP_204_NO_CONTENT)
async def apagar_foto(
    foto_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    oid = object_id_or_404(foto_id)
    result = await db.fotos.delete_one({"_id": oid})
    if result.deleted_count == 0:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Foto não encontrada")
