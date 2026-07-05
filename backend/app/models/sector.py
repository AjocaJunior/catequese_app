from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


class DiaSemana(str, Enum):
    SEGUNDA = "segunda"
    TERCA = "terca"
    QUARTA = "quarta"
    QUINTA = "quinta"
    SEXTA = "sexta"
    SABADO = "sabado"
    DOMINGO = "domingo"


class SectorCreate(BaseModel):
    nome: str = Field(..., min_length=2, max_length=100, description="Ex: Acolhimento, Acólitos")
    dia_semana: Optional[DiaSemana] = Field(None, description="Só para sectores com encontro regular")
    hora: Optional[str] = Field(None, max_length=20, description="Ex: 18:00")
    local: Optional[str] = Field(None, max_length=100)
    ministerio_id: Optional[str] = Field(None, description="Ministério ao qual este sector pertence")
    responsavel_nome: Optional[str] = Field(None, max_length=150)


class SectorUpdate(BaseModel):
    nome: Optional[str] = Field(None, min_length=2, max_length=100)
    dia_semana: Optional[DiaSemana] = None
    hora: Optional[str] = Field(None, max_length=20)
    local: Optional[str] = Field(None, max_length=100)
    ministerio_id: Optional[str] = None
    responsavel_nome: Optional[str] = Field(None, max_length=150)


class SectorOut(BaseModel):
    id: str
    nome: str
    dia_semana: Optional[DiaSemana] = None
    hora: Optional[str] = None
    local: Optional[str] = None
    ministerio_id: Optional[str] = None
    ministerio_nome: Optional[str] = None
    responsavel_nome: Optional[str] = None
    criado_em: datetime
