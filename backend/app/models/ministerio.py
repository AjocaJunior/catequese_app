from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class MinisterioCreate(BaseModel):
    nome: str = Field(..., min_length=2, max_length=100, description="Ex: Ministério da Liturgia")
    coordenador_nome: Optional[str] = Field(None, max_length=150)


class MinisterioUpdate(BaseModel):
    nome: Optional[str] = Field(None, min_length=2, max_length=100)
    coordenador_nome: Optional[str] = Field(None, max_length=150)


class MinisterioOut(BaseModel):
    id: str
    nome: str
    coordenador_nome: Optional[str] = None
    criado_em: datetime
