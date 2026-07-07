from pydantic import BaseModel, Field


class ConfiguracaoOut(BaseModel):
    ano_letivo_atual: int


class AtualizarAnoLetivoRequest(BaseModel):
    novo_ano: int = Field(..., ge=2020, le=2100)
