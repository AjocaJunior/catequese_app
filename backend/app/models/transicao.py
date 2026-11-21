from typing import Optional

from pydantic import BaseModel


class CatequisandoTransicao(BaseModel):
    catequisando_id: str
    nome: str


class LinhaTransicaoFase(BaseModel):
    fase_id: str
    fase_nome: str
    ordem: int
    transitoria: bool = False
    fase_seguinte_id: Optional[str] = None
    fase_seguinte_nome: Optional[str] = None
    total: int = 0
    # Progridem E existe fase seguinte: vão ser movidos.
    a_mover: int = 0
    # Ficam na fase (permanecem, ou — numa fase transitória — ainda sem baptismo).
    permanecem: int = 0
    # Sem resultado na pauta: ficam na fase.
    por_definir: int = 0
    # Progridem mas a fase não tem fase seguinte: ficam na fase.
    sem_fase_seguinte: int = 0
    lista_por_definir: list[CatequisandoTransicao] = []
    lista_sem_fase_seguinte: list[CatequisandoTransicao] = []


class PreviaTransicao(BaseModel):
    ano_atual: int
    novo_ano: int
    linhas: list[LinhaTransicaoFase]
    total_a_mover: int = 0
    total_permanecem: int = 0
    total_por_definir: int = 0
    total_sem_fase_seguinte: int = 0
    avisos: list[str] = []


class MatriculaPendente(BaseModel):
    catequisando_id: str
    nome: str
    fase_id: str
    fase_nome: str
