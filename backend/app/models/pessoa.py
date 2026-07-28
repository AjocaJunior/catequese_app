from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class PessoaCreate(BaseModel):
    nome: str = Field(..., min_length=2, max_length=150)
    natural_de: Optional[str] = Field(None, max_length=100)
    provincia: Optional[str] = Field(None, max_length=100)
    estado_civil: Optional[str] = Field(None, max_length=50)
    profissao: Optional[str] = Field(None, max_length=100)
    residencia: Optional[str] = Field(None, max_length=200)
    comunidade: Optional[str] = Field(None, max_length=150, description="Comunidade/paróquia a que pertence, se não for a nossa")
    contacto: Optional[str] = Field(None, max_length=50)


class PessoaUpdate(BaseModel):
    nome: Optional[str] = Field(None, min_length=2, max_length=150)
    natural_de: Optional[str] = Field(None, max_length=100)
    provincia: Optional[str] = Field(None, max_length=100)
    estado_civil: Optional[str] = Field(None, max_length=50)
    profissao: Optional[str] = Field(None, max_length=100)
    residencia: Optional[str] = Field(None, max_length=200)
    comunidade: Optional[str] = Field(None, max_length=150)
    contacto: Optional[str] = Field(None, max_length=50)


class PessoaOut(BaseModel):
    id: str
    nome: str
    natural_de: Optional[str] = None
    provincia: Optional[str] = None
    estado_civil: Optional[str] = None
    profissao: Optional[str] = None
    residencia: Optional[str] = None
    comunidade: Optional[str] = None
    contacto: Optional[str] = None
    criado_em: datetime


class VinculoPessoaOut(BaseModel):
    """Um catequisando que referencia esta pessoa, e em que papel."""
    catequisando_id: str
    catequisando_nome: str
    papel: str  # "pai" | "mae" | "padrinho" | "madrinha"
