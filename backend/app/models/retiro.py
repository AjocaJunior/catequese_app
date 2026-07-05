from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel, Field


class ProgramaItem(BaseModel):
    hora: str = Field(..., max_length=30)
    atividade: str = Field(..., max_length=200)
    responsavel: str = Field(..., max_length=120)


class RetiroCreate(BaseModel):
    titulo: str = Field(..., min_length=2, max_length=150)
    fase_ids: list[str] = Field(default_factory=list)
    sector_ids: list[str] = Field(default_factory=list)
    data: date
    local: str = Field(..., min_length=2, max_length=200)
    oradores: list[str] = Field(default_factory=list)
    tema: str = Field("", max_length=1000)
    programa: list[ProgramaItem] = Field(default_factory=list)


class RetiroUpdate(BaseModel):
    titulo: Optional[str] = Field(None, min_length=2, max_length=150)
    fase_ids: Optional[list[str]] = None
    sector_ids: Optional[list[str]] = None
    data: Optional[date] = None
    local: Optional[str] = Field(None, min_length=2, max_length=200)
    oradores: Optional[list[str]] = None
    tema: Optional[str] = Field(None, max_length=1000)
    programa: Optional[list[ProgramaItem]] = None


class FaseResumo(BaseModel):
    """Versão reduzida da fase, usada dentro da RetiroOut."""
    id: str
    nome: str


class SectorResumoRetiro(BaseModel):
    """Versão reduzida do sector, usada dentro da RetiroOut."""
    id: str
    nome: str


class RetiroOut(BaseModel):
    id: str
    titulo: str
    fases: list[FaseResumo] = []
    sectores: list[SectorResumoRetiro] = []
    data: date
    local: str
    oradores: list[str]
    tema: str
    programa: list[ProgramaItem]
    criado_em: datetime
