from datetime import datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field


class EstadoItem(str, Enum):
    BOM = "bom"
    EM_USO = "em_uso"
    NOVO = "novo"
    DESCARTADO = "descartado"
    DANIFICADO = "danificado"
    ANTIGO = "antigo"
    NAO_APLICAVEL = "nao_aplicavel"


class ItemInventarioCreate(BaseModel):
    nome: str = Field(..., min_length=2, max_length=150)
    sector_id: Optional[str] = Field(
        None, description="Sector dono deste item (ex: Património). Vazio = inventário geral da catequese"
    )
    categoria: Optional[str] = Field(None, max_length=80)
    quantidade: int = Field(..., ge=0)
    descricao: Optional[str] = Field(None, max_length=300)
    localizacao: Optional[str] = Field(None, max_length=150)
    imagem_url: Optional[str] = Field(None, max_length=500, description="Link do Google Drive")
    estado: Optional[EstadoItem] = None


class ItemInventarioUpdate(BaseModel):
    nome: Optional[str] = Field(None, min_length=2, max_length=150)
    sector_id: Optional[str] = None
    categoria: Optional[str] = Field(None, max_length=80)
    quantidade: Optional[int] = Field(None, ge=0)
    descricao: Optional[str] = Field(None, max_length=300)
    localizacao: Optional[str] = Field(None, max_length=150)
    imagem_url: Optional[str] = Field(None, max_length=500)
    estado: Optional[EstadoItem] = None


class ItemInventarioOut(BaseModel):
    id: str
    nome: str
    sector_id: Optional[str] = None
    sector_nome: Optional[str] = None
    categoria: Optional[str] = None
    quantidade: int
    descricao: Optional[str] = None
    localizacao: Optional[str] = None
    imagem_url: Optional[str] = None
    estado: Optional[EstadoItem] = None
    criado_em: datetime
    criado_por_nome: Optional[str] = None
    atualizado_em: Optional[datetime] = None
    atualizado_por_nome: Optional[str] = None
