from datetime import date, datetime
from enum import Enum
from typing import Optional

from pydantic import BaseModel, Field

from app.models.pessoa import PessoaOut


class Genero(str, Enum):
    MASCULINO = "masculino"
    FEMININO = "feminino"


class SituacaoCatequisando(str, Enum):
    ATIVO = "ativo"
    CRISMADO = "crismado"
    TRANSFERIDO = "transferido"


class CatequisandoCreate(BaseModel):
    nome: str = Field(..., min_length=2, max_length=150)
    genero: Optional[Genero] = None
    data_nascimento: Optional[date] = None
    natural_de: Optional[str] = Field(None, max_length=100)
    estado_civil: Optional[str] = Field(None, max_length=50)
    profissao: Optional[str] = Field(None, max_length=100)
    residencia: Optional[str] = Field(None, max_length=200)
    fase_id: str
    sector_id: Optional[str] = Field(None, description="Sector pastoral a que também pertence, ex: Acólitos")
    encarregado_nome: Optional[str] = Field(None, max_length=150)
    encarregado_contacto: Optional[str] = Field(None, max_length=50)
    encarregado_parentesco: Optional[str] = Field(None, max_length=50)
    observacoes: Optional[str] = Field(None, max_length=500)

    # Ficha do Catecúmeno — Ano/Número de registo (ex: da ficha em papel)
    ficha_ano: Optional[int] = Field(None, ge=1900, le=2200)
    ficha_numero: Optional[str] = Field(None, max_length=10, description="Pode ter até 5 dígitos")

    # Filiação — referências a pessoas reutilizáveis (ver GET/POST /pessoas),
    # para não duplicar dados entre irmãos ou afilhados da mesma pessoa
    pai_id: Optional[str] = None
    mae_id: Optional[str] = None
    avo_paterno_nome: Optional[str] = Field(None, max_length=150)
    avo_paterna_nome: Optional[str] = Field(None, max_length=150)
    avo_materno_nome: Optional[str] = Field(None, max_length=150)
    avo_materna_nome: Optional[str] = Field(None, max_length=150)

    # Padrinhos — idem, referências reutilizáveis
    padrinho_id: Optional[str] = None
    madrinha_id: Optional[str] = None

    # Eleição e Escrutínios (RCIA) — opcional, só para algumas fases
    eleicao_data: Optional[date] = None
    escrutinio_1_data: Optional[date] = None
    escrutinio_2_data: Optional[date] = None
    escrutinio_3_data: Optional[date] = None

    # Baptismo
    baptismo_local: Optional[str] = Field(None, max_length=150)
    baptismo_data: Optional[date] = None
    baptismo_certidao_url: Optional[str] = Field(None, max_length=500, description="Link do Google Drive")

    # Núcleo — como um Sector, mas do Ministério da Animação dos Núcleos
    nucleo_id: Optional[str] = None
    nucleo_comunidade: Optional[str] = Field(None, max_length=150, description="'da comunidade ___' nas fichas de sacramento")

    # Baptismo — campos adicionais para a Ficha de Baptismo completa
    baptismo_arquidiocese: Optional[str] = Field(None, max_length=150)
    baptismo_livro: Optional[str] = Field(None, max_length=30)
    baptismo_numero_registo: Optional[str] = Field(None, max_length=20)
    baptismo_pagina: Optional[str] = Field(None, max_length=20)

    # Primeira Comunhão
    primeira_comunhao_data: Optional[date] = None
    primeira_comunhao_hora: Optional[str] = Field(None, max_length=20)
    primeira_comunhao_livro: Optional[str] = Field(None, max_length=30)
    primeira_comunhao_numero_registo: Optional[str] = Field(None, max_length=20)
    primeira_comunhao_pagina: Optional[str] = Field(None, max_length=20)

    # Crisma
    crisma_data: Optional[date] = None
    crisma_hora: Optional[str] = Field(None, max_length=20)
    crisma_livro: Optional[str] = Field(None, max_length=30)
    crisma_numero_registo: Optional[str] = Field(None, max_length=20)
    crisma_pagina: Optional[str] = Field(None, max_length=20)


class CatequisandoUpdate(BaseModel):
    nome: Optional[str] = Field(None, min_length=2, max_length=150)
    genero: Optional[Genero] = None
    data_nascimento: Optional[date] = None
    natural_de: Optional[str] = Field(None, max_length=100)
    estado_civil: Optional[str] = Field(None, max_length=50)
    profissao: Optional[str] = Field(None, max_length=100)
    residencia: Optional[str] = Field(None, max_length=200)
    fase_id: Optional[str] = None
    sector_id: Optional[str] = None
    situacao: Optional[SituacaoCatequisando] = None
    encarregado_nome: Optional[str] = Field(None, max_length=150)
    encarregado_contacto: Optional[str] = Field(None, max_length=50)
    encarregado_parentesco: Optional[str] = Field(None, max_length=50)
    observacoes: Optional[str] = Field(None, max_length=500)

    ficha_ano: Optional[int] = Field(None, ge=1900, le=2200)
    ficha_numero: Optional[str] = Field(None, max_length=10)

    pai_id: Optional[str] = None
    mae_id: Optional[str] = None
    avo_paterno_nome: Optional[str] = Field(None, max_length=150)
    avo_paterna_nome: Optional[str] = Field(None, max_length=150)
    avo_materno_nome: Optional[str] = Field(None, max_length=150)
    avo_materna_nome: Optional[str] = Field(None, max_length=150)

    padrinho_id: Optional[str] = None
    madrinha_id: Optional[str] = None

    eleicao_data: Optional[date] = None
    escrutinio_1_data: Optional[date] = None
    escrutinio_2_data: Optional[date] = None
    escrutinio_3_data: Optional[date] = None

    baptismo_local: Optional[str] = Field(None, max_length=150)
    baptismo_data: Optional[date] = None
    baptismo_certidao_url: Optional[str] = Field(None, max_length=500)

    nucleo_id: Optional[str] = None
    nucleo_comunidade: Optional[str] = Field(None, max_length=150)

    baptismo_arquidiocese: Optional[str] = Field(None, max_length=150)
    baptismo_livro: Optional[str] = Field(None, max_length=30)
    baptismo_numero_registo: Optional[str] = Field(None, max_length=20)
    baptismo_pagina: Optional[str] = Field(None, max_length=20)

    primeira_comunhao_data: Optional[date] = None
    primeira_comunhao_hora: Optional[str] = Field(None, max_length=20)
    primeira_comunhao_livro: Optional[str] = Field(None, max_length=30)
    primeira_comunhao_numero_registo: Optional[str] = Field(None, max_length=20)
    primeira_comunhao_pagina: Optional[str] = Field(None, max_length=20)

    crisma_data: Optional[date] = None
    crisma_hora: Optional[str] = Field(None, max_length=20)
    crisma_livro: Optional[str] = Field(None, max_length=30)
    crisma_numero_registo: Optional[str] = Field(None, max_length=20)
    crisma_pagina: Optional[str] = Field(None, max_length=20)


class CatequisandoOut(BaseModel):
    id: str
    nome: str
    genero: Optional[Genero] = None
    data_nascimento: Optional[date] = None
    natural_de: Optional[str] = None
    estado_civil: Optional[str] = None
    profissao: Optional[str] = None
    residencia: Optional[str] = None
    fase_id: str
    fase_nome: str
    sector_id: Optional[str] = None
    sector_nome: Optional[str] = None
    situacao: SituacaoCatequisando = SituacaoCatequisando.ATIVO
    data_situacao: Optional[date] = None
    encarregado_nome: Optional[str] = None
    encarregado_contacto: Optional[str] = None
    encarregado_parentesco: Optional[str] = None
    observacoes: Optional[str] = None

    ficha_ano: Optional[int] = None
    ficha_numero: Optional[str] = None

    pai_id: Optional[str] = None
    pai: Optional[PessoaOut] = None
    mae_id: Optional[str] = None
    mae: Optional[PessoaOut] = None
    avo_paterno_nome: Optional[str] = None
    avo_paterna_nome: Optional[str] = None
    avo_materno_nome: Optional[str] = None
    avo_materna_nome: Optional[str] = None

    padrinho_id: Optional[str] = None
    padrinho: Optional[PessoaOut] = None
    madrinha_id: Optional[str] = None
    madrinha: Optional[PessoaOut] = None

    eleicao_data: Optional[date] = None
    escrutinio_1_data: Optional[date] = None
    escrutinio_2_data: Optional[date] = None
    escrutinio_3_data: Optional[date] = None

    baptismo_local: Optional[str] = None
    baptismo_data: Optional[date] = None
    baptismo_certidao_url: Optional[str] = None

    nucleo_id: Optional[str] = None
    nucleo_nome: Optional[str] = None
    nucleo_comunidade: Optional[str] = None

    baptismo_arquidiocese: Optional[str] = None
    baptismo_livro: Optional[str] = None
    baptismo_numero_registo: Optional[str] = None
    baptismo_pagina: Optional[str] = None

    primeira_comunhao_data: Optional[date] = None
    primeira_comunhao_hora: Optional[str] = None
    primeira_comunhao_livro: Optional[str] = None
    primeira_comunhao_numero_registo: Optional[str] = None
    primeira_comunhao_pagina: Optional[str] = None

    crisma_data: Optional[date] = None
    crisma_hora: Optional[str] = None
    crisma_livro: Optional[str] = None
    crisma_numero_registo: Optional[str] = None
    crisma_pagina: Optional[str] = None

    # Transferência para outra paróquia/comunidade
    transferencia_numero: Optional[str] = None
    transferencia_ano_guia: Optional[int] = None
    transferencia_ano_frequentado: Optional[int] = None
    transferencia_destino_comunidade: Optional[str] = None
    transferencia_destino_arquidiocese: Optional[str] = None
    transferencia_observacao: Optional[str] = None
    transferencia_data: Optional[date] = None

    criado_em: datetime


class TransferenciaRequest(BaseModel):
    numero: str = Field(..., min_length=1, max_length=10)
    ano_guia: int = Field(..., ge=1900, le=2200)
    ano_frequentado: int = Field(..., ge=1900, le=2200)
    destino_comunidade: str = Field(..., min_length=2, max_length=200)
    destino_arquidiocese: str = Field(..., min_length=2, max_length=150)
    observacao: Optional[str] = Field(None, max_length=500)
    data_impressao: Optional[date] = None


class ErroImportacao(BaseModel):
    linha: int
    motivo: str


class ImportacaoResultado(BaseModel):
    total_linhas: int
    criados: int
    erros: list[ErroImportacao]
