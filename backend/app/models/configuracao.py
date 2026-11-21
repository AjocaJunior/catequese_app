from pydantic import BaseModel, Field


class ConfiguracaoOut(BaseModel):
    ano_letivo_atual: int


class AtualizarAnoLetivoRequest(BaseModel):
    novo_ano: int = Field(..., ge=2020, le=2100)
    aplicar_transicao: bool = Field(
        False,
        description="Se verdadeiro, move para a 'Fase seguinte' quem progride (ver GET /configuracao/ano-letivo/previa-transicao).",
    )


class AvancarAnoOut(ConfiguracaoOut):
    transicao_aplicada: bool = False
    movidos: int = 0
    permaneceram: int = 0
    por_definir: int = 0
    sem_fase_seguinte: int = 0
