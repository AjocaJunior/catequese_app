from datetime import date, datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


class Genero(str, Enum):
    MASCULINO = "masculino"
    FEMININO = "feminino"


class SituacaoCatequisando(str, Enum):
    ATIVO = "ativo"
    CRISMADO = "crismado"


class CatequisandoCreate(BaseModel):
    nome: str = Field(..., min_length=2, max_length=150)
    genero: Optional[Genero] = None
    data_nascimento: Optional[date] = None
    fase_id: str
    sector_id: Optional[str] = Field(None, description="Sector pastoral a que também pertence, ex: Acólitos")
    encarregado_nome: Optional[str] = Field(None, max_length=150)
    encarregado_contacto: Optional[str] = Field(None, max_length=50)
    encarregado_parentesco: Optional[str] = Field(None, max_length=50)
    observacoes: Optional[str] = Field(None, max_length=500)


class CatequisandoUpdate(BaseModel):
    nome: Optional[str] = Field(None, min_length=2, max_length=150)
    genero: Optional[Genero] = None
    data_nascimento: Optional[date] = None
    fase_id: Optional[str] = None
    sector_id: Optional[str] = None
    situacao: Optional[SituacaoCatequisando] = None
    encarregado_nome: Optional[str] = Field(None, max_length=150)
    encarregado_contacto: Optional[str] = Field(None, max_length=50)
    encarregado_parentesco: Optional[str] = Field(None, max_length=50)
    observacoes: Optional[str] = Field(None, max_length=500)


class CatequisandoOut(BaseModel):
    id: str
    nome: str
    genero: Optional[Genero] = None
    data_nascimento: Optional[date] = None
    fase_id: str
    fase_nome: str
    sector_id: Optional[str] = None
    sector_nome: Optional[str] = None
    situacao: SituacaoCatequisando = SituacaoCatequisando.ATIVO
    data_situacao: Optional[date] = None
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
