from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel


class Situacao(str, Enum):
    PERMANECE = "permanece"
    PROGRIDE = "progride"


class ItemPautaOut(BaseModel):
    catequisando_id: str
    catequisando_nome: str
    total_presencas: int
    total_faltas: int
    total_faltas_justificadas: int
    situacao: Optional[Situacao] = None


class SituacaoItemBody(BaseModel):
    catequisando_id: str
    situacao: Situacao


class DefinirPautaRequest(BaseModel):
    situacoes: list[SituacaoItemBody]


class PautaOut(BaseModel):
    fase_id: str
    fase_nome: str
    ano_letivo: int
    itens: list[ItemPautaOut]
    atualizado_em: Optional[datetime] = None
    atualizado_por_nome: Optional[str] = None
