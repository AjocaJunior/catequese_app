from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel


class AcaoAuditoria(str, Enum):
    CRIAR = "criar"
    ATUALIZAR = "atualizar"
    APAGAR = "apagar"


class RegistoAuditoriaOut(BaseModel):
    id: str
    data: datetime
    catequista_id: Optional[str] = None
    catequista_nome: str
    acao: AcaoAuditoria
    entidade: str
    entidade_id: Optional[str] = None
    resumo: str
