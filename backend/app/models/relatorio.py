from pydantic import BaseModel


class LinhaRelatorioFaseGenero(BaseModel):
    fase_id: str
    fase_nome: str
    ordem: int
    masculino: int
    feminino: int
    nao_informado: int
    total: int


class RelatorioCatequisandosPorFaseGenero(BaseModel):
    ano_letivo: int
    linhas: list[LinhaRelatorioFaseGenero]
    total_masculino: int
    total_feminino: int
    total_nao_informado: int
    total_geral: int


class LinhaRelatorioSituacaoFinal(BaseModel):
    fase_id: str
    fase_nome: str
    ordem: int
    permanece: int
    progride: int
    por_definir: int
    total: int


class RelatorioSituacaoFinal(BaseModel):
    ano_letivo: int
    linhas: list[LinhaRelatorioSituacaoFinal]
    total_permanece: int
    total_progride: int
    total_por_definir: int
    total_geral: int


class LinhaRelatorioAssiduidade(BaseModel):
    fase_id: str
    fase_nome: str
    ordem: int
    total_catequisandos: int
    total_presencas: int
    total_faltas: int
    total_faltas_justificadas: int
    taxa_assiduidade: float


class RelatorioAssiduidade(BaseModel):
    ano_letivo: int
    linhas: list[LinhaRelatorioAssiduidade]
    taxa_geral: float
