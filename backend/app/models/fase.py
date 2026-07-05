from typing import Optional

from pydantic import BaseModel, Field


class FaseCreate(BaseModel):
    nome: str = Field(..., min_length=2, max_length=100)
    ordem: Optional[int] = Field(None, description="Se omitido, é atribuída a ordem seguinte disponível")
    nome_catecismo: Optional[str] = Field(None, max_length=150)
    local: Optional[str] = Field(None, max_length=100)
    programa_pdf_url: Optional[str] = Field(None, max_length=500)


class FaseUpdate(BaseModel):
    nome: Optional[str] = Field(None, min_length=2, max_length=100)
    ordem: Optional[int] = None
    nome_catecismo: Optional[str] = Field(None, max_length=150)
    local: Optional[str] = Field(None, max_length=100)
    programa_pdf_url: Optional[str] = Field(None, max_length=500)


class CatequistaResumo(BaseModel):
    """Versão reduzida do catequista, usada dentro da FaseOut."""
    id: str
    nome: str


class FaseOut(BaseModel):
    id: str
    nome: str
    ordem: int
    nome_catecismo: Optional[str] = None
    local: Optional[str] = None
    programa_pdf_url: Optional[str] = None
    catequistas: list[CatequistaResumo] = []


class DefinirCatequistasBody(BaseModel):
    catequista_ids: list[str]
