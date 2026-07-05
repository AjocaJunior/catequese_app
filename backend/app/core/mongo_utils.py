from bson import ObjectId
from bson.errors import InvalidId
from fastapi import HTTPException, status


def object_id_or_404(id_str: str) -> ObjectId:
    """Converte uma string em ObjectId; devolve 400 (não 500) se for inválida."""
    try:
        return ObjectId(id_str)
    except (InvalidId, TypeError):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="ID inválido")
