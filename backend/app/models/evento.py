from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel, Field


class EventoCreate(BaseModel):
    titulo: str = Field(..., min_length=2, max_length=150)
    data: date
    local: Optional[str] = Field(None, max_length=200)
    descricao: Optional[str] = Field(None, max_length=1000)


class EventoUpdate(BaseModel):
    titulo: Optional[str] = Field(None, min_length=2, max_length=150)
    data: Optional[date] = None
    local: Optional[str] = Field(None, max_length=200)
    descricao: Optional[str] = Field(None, max_length=1000)


class EventoOut(BaseModel):
    id: str
    titulo: str
    data: date
    local: Optional[str] = None
    descricao: Optional[str] = None
    criado_em: datetime
