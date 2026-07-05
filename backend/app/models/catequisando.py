from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel, Field


class CatequisandoCreate(BaseModel):
    nome: str = Field(..., min_length=2, max_length=150)
    data_nascimento: Optional[date] = None
    fase_id: str
    sector_id: Optional[str] = Field(None, description="Sector pastoral a que também pertence, ex: Acólitos")
    encarregado_nome: Optional[str] = Field(None, max_length=150)
    encarregado_contacto: Optional[str] = Field(None, max_length=50)
    encarregado_parentesco: Optional[str] = Field(None, max_length=50)
    observacoes: Optional[str] = Field(None, max_length=500)


class CatequisandoUpdate(BaseModel):
    nome: Optional[str] = Field(None, min_length=2, max_length=150)
    data_nascimento: Optional[date] = None
    fase_id: Optional[str] = None
    sector_id: Optional[str] = None
    encarregado_nome: Optional[str] = Field(None, max_length=150)
    encarregado_contacto: Optional[str] = Field(None, max_length=50)
    encarregado_parentesco: Optional[str] = Field(None, max_length=50)
    observacoes: Optional[str] = Field(None, max_length=500)


class CatequisandoOut(BaseModel):
    id: str
    nome: str
    data_nascimento: Optional[date] = None
    fase_id: str
    fase_nome: str
    sector_id: Optional[str] = None
    sector_nome: Optional[str] = None
    encarregado_nome: Optional[str] = None
    encarregado_contacto: Optional[str] = None
    encarregado_parentesco: Optional[str] = None
    observacoes: Optional[str] = None
    criado_em: datetime


class ErroImportacao(BaseModel):
    linha: int
    motivo: str


class ImportacaoResultado(BaseModel):
    total_linhas: int
    criados: int
    erros: list[ErroImportacao]
