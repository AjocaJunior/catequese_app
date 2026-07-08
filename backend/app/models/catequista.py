from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr, Field, ConfigDict


class CatequistaCreate(BaseModel):
    nome: str = Field(..., min_length=2, max_length=120)
    email: EmailStr
    password: str = Field(..., min_length=6, max_length=72)


class SectorResumoCatequista(BaseModel):
    """Versão reduzida do sector, usada dentro da CatequistaOut."""
    id: str
    nome: str


class CatequistaOut(BaseModel):
    id: str
    nome: str
    email: EmailStr
    contacto: Optional[str] = None
    is_admin: bool = False
    tem_fase_atribuida: bool = False
    sectores_responsavel: list[SectorResumoCatequista] = []
    criado_em: datetime

    model_config = ConfigDict(from_attributes=True)


class AtualizarPerfilRequest(BaseModel):
    nome: Optional[str] = Field(None, min_length=2, max_length=120)
    contacto: Optional[str] = Field(None, max_length=50)


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    catequista: CatequistaOut


class AlterarSenhaRequest(BaseModel):
    senha_atual: str
    nova_senha: str = Field(..., min_length=6, max_length=72)


class EsqueciSenhaRequest(BaseModel):
    email: EmailStr


class RedefinirSenhaRequest(BaseModel):
    email: EmailStr
    codigo: str = Field(..., min_length=6, max_length=6)
    nova_senha: str = Field(..., min_length=6, max_length=72)
