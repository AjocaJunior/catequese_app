from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class ItemInventarioCreate(BaseModel):
    nome: str = Field(..., min_length=2, max_length=150)
    quantidade: int = Field(..., ge=0)
    descricao: Optional[str] = Field(None, max_length=300)


class ItemInventarioUpdate(BaseModel):
    nome: Optional[str] = Field(None, min_length=2, max_length=150)
    quantidade: Optional[int] = Field(None, ge=0)
    descricao: Optional[str] = Field(None, max_length=300)


class ItemInventarioOut(BaseModel):
    id: str
    nome: str
    quantidade: int
    descricao: Optional[str] = None
    criado_em: datetime
