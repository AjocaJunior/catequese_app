from datetime import date, datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


class TipoTransacao(str, Enum):
    RECEITA = "receita"
    DESPESA = "despesa"


class MetodoPagamento(str, Enum):
    NUMERARIO = "numerario"
    MPESA = "mpesa"
    EMOLA = "emola"


# Categorias sugeridas para receitas ligadas a um catequisando — usadas pelo
# ecrã de Inscrições e Renovações. O campo em si é texto livre (permite
# outras categorias, ex. despesas), mas o frontend usa sempre estes valores
# para as 3 taxas específicas da catequese.
CATEGORIA_INSCRICAO = "Inscrição"
CATEGORIA_RENOVACAO = "Renovação"
CATEGORIA_FICHA_CATECUMENO = "Ficha do Catecúmeno"

# Categorias que representam a matrícula do catequisando num ano letivo —
# a fase é guardada nestas transações, e é daqui que se deriva o histórico
# de "em que fase estava X no ano Y" (ver GET /catequisandos/{id}/historico).
CATEGORIAS_MATRICULA = {CATEGORIA_INSCRICAO, CATEGORIA_RENOVACAO}


class CaixaTransacaoCreate(BaseModel):
    tipo: TipoTransacao
    categoria: str = Field(..., min_length=2, max_length=60)
    valor: float = Field(..., gt=0)
    metodo_pagamento: Optional[MetodoPagamento] = None
    catequisando_id: Optional[str] = None
    fase_id: Optional[str] = Field(None, description="Fase a que a inscrição/renovação se refere")
    ano_letivo: Optional[int] = Field(None, description="Se omitido, usa o ano letivo corrente")
    descricao: Optional[str] = Field(None, max_length=300)
    data: date


class CaixaTransacaoUpdate(BaseModel):
    tipo: Optional[TipoTransacao] = None
    categoria: Optional[str] = Field(None, min_length=2, max_length=60)
    valor: Optional[float] = Field(None, gt=0)
    metodo_pagamento: Optional[MetodoPagamento] = None
    catequisando_id: Optional[str] = None
    fase_id: Optional[str] = None
    ano_letivo: Optional[int] = None
    descricao: Optional[str] = Field(None, max_length=300)
    data: Optional[date] = None


class CaixaTransacaoOut(BaseModel):
    id: str
    tipo: TipoTransacao
    categoria: str
    valor: float
    metodo_pagamento: Optional[MetodoPagamento] = None
    catequisando_id: Optional[str] = None
    catequisando_nome: Optional[str] = None
    fase_id: Optional[str] = None
    fase_nome: Optional[str] = None
    ano_letivo: Optional[int] = None
    descricao: Optional[str] = None
    data: date
    registado_por_nome: str
    criado_em: datetime


class ResumoCaixa(BaseModel):
    total_receitas: float
    total_despesas: float
    saldo: float
