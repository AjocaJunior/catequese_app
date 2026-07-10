from typing import Optional

from pydantic import BaseModel


class LeituraLiturgia(BaseModel):
    titulo: str
    texto: str


class SalmoLiturgia(BaseModel):
    titulo: str
    resposta: str
    versos: list[str]


class LiturgiaDiariaOut(BaseModel):
    disponivel: bool
    data: Optional[str] = None
    cor_liturgica: Optional[str] = None
    tempo_liturgico: Optional[str] = None
    primeira_leitura: Optional[LeituraLiturgia] = None
    segunda_leitura: Optional[LeituraLiturgia] = None
    salmo: Optional[SalmoLiturgia] = None
    evangelho: Optional[LeituraLiturgia] = None
    fonte_url: str = "https://sagradaliturgia.com.br/"
