from datetime import date
from enum import Enum

from pydantic import BaseModel


class StatusPresenca(str, Enum):
    PRESENTE = "presente"
    FALTA = "falta"
    FALTA_JUSTIFICADA = "falta_justificada"


class PresencaItem(BaseModel):
    catequisando_id: str
    status: StatusPresenca


class MarcarPresencasRequest(BaseModel):
    fase_id: str
    data: date
    presencas: list[PresencaItem]


class PresencaOut(BaseModel):
    catequisando_id: str
    catequisando_nome: str
    status: StatusPresenca


class ListaPresencasOut(BaseModel):
    fase_id: str
    data: date
    presencas: list[PresencaOut]


class RegistoPresenca(BaseModel):
    data: date
    status: StatusPresenca


class HistoricoPresencasOut(BaseModel):
    catequisando_id: str
    total_registos: int
    total_presencas: int
    total_faltas: int
    total_faltas_justificadas: int
    registos: list[RegistoPresenca]


class LinhaRelatorioPresencas(BaseModel):
    catequisando_id: str
    nome: str
    presencas: int
    faltas: int
    faltas_justificadas: int
    total: int
