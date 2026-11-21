from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


class Situacao(str, Enum):
    PERMANECE = "permanece"
    PROGRIDE = "progride"


class Comportamento(str, Enum):
    RAZOAVEL = "razoavel"
    BOM = "bom"
    EXCELENTE = "excelente"


class ItemPautaOut(BaseModel):
    catequisando_id: str
    catequisando_nome: str
    genero: Optional[str] = None
    total_presencas: int
    total_faltas: int
    total_faltas_justificadas: int
    situacao: Optional[Situacao] = None
    comportamento: Optional[Comportamento] = None
    observacao: Optional[str] = None


class ItemPautaBody(BaseModel):
    catequisando_id: str
    situacao: Optional[Situacao] = None
    comportamento: Optional[Comportamento] = None
    observacao: Optional[str] = Field(None, max_length=300)


class DefinirPautaRequest(BaseModel):
    situacoes: list[ItemPautaBody]


class PautaOut(BaseModel):
    fase_id: str
    fase_nome: str
    ano_letivo: int
    itens: list[ItemPautaOut]
    atualizado_em: Optional[datetime] = None
    atualizado_por_nome: Optional[str] = None
