from datetime import date, datetime
from typing import Optional
from zoneinfo import ZoneInfo

import httpx
from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, Response, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from pydantic import BaseModel

from app.core.database import get_database
from app.core.mongo_utils import object_id_or_404
from app.models.evento import EventoOut
from app.models.foto import FotoOut
from app.models.liturgia import LeituraLiturgia, LiturgiaDiariaOut, SalmoLiturgia
from app.models.sector import SectorOut
from app.routers.eventos import _to_out as evento_to_out
from app.routers.fotos import foto_to_out
from app.routers.sectores import _to_out as sector_to_out

router = APIRouter(prefix="/publico", tags=["público"])

_LITURGIA_API_URL = "https://api-liturgia-diaria.vercel.app/"
_LITURGIA_FONTE_URL = "https://sagradaliturgia.com.br/"
_FUSO_MOCAMBIQUE = ZoneInfo("Africa/Maputo")
_cache_liturgia: dict[str, LiturgiaDiariaOut] = {}


class RetiroPublicoOut(BaseModel):
    id: str
    titulo: str
    data: date
    local: str
    fases: list[str]


class SectorOrganogramaOut(BaseModel):
    id: str
    nome: str
    responsavel_nome: Optional[str] = None


class MinisterioOrganogramaOut(BaseModel):
    id: str
    nome: str
    coordenador_nome: Optional[str] = None
    sectores: list[SectorOrganogramaOut]


class OrganogramaOut(BaseModel):
    ministerios: list[MinisterioOrganogramaOut]
    sectores_sem_ministerio: list[SectorOrganogramaOut]


@router.get("/retiros", response_model=list[RetiroPublicoOut])
async def listar_retiros_publico(db: AsyncIOMotorDatabase = Depends(get_database)):
    resultado = []
    async for doc in db.retiros.find().sort("data", -1):
        fase_ids = doc.get("fase_ids", [])
        fases_nomes: list[str] = []
        if fase_ids:
            oids = [ObjectId(i) for i in fase_ids if ObjectId.is_valid(i)]
            async for f in db.fases.find({"_id": {"$in": oids}}).sort("ordem", 1):
                fases_nomes.append(f["nome"])
        resultado.append(RetiroPublicoOut(
            id=str(doc["_id"]),
            titulo=doc["titulo"],
            data=doc["data"].date(),
            local=doc["local"],
            fases=fases_nomes,
        ))
    return resultado


@router.get("/eventos", response_model=list[EventoOut])
async def listar_eventos_publico(db: AsyncIOMotorDatabase = Depends(get_database)):
    cursor = db.eventos.find().sort("data", 1)
    return [evento_to_out(doc) async for doc in cursor]


@router.get("/sectores", response_model=list[SectorOut])
async def listar_sectores_publico(db: AsyncIOMotorDatabase = Depends(get_database)):
    cursor = db.sectores.find().sort("nome", 1)
    return [await sector_to_out(db, doc) async for doc in cursor]


@router.get("/fotos", response_model=list[FotoOut])
async def listar_fotos_publico(db: AsyncIOMotorDatabase = Depends(get_database)):
    cursor = db.fotos.find({}, {"imagem": 0}).sort("criado_em", -1)
    return [foto_to_out(doc) async for doc in cursor]


@router.get("/fotos/{foto_id}/imagem")
async def obter_imagem_publico(foto_id: str, db: AsyncIOMotorDatabase = Depends(get_database)):
    oid = object_id_or_404(foto_id)
    doc = await db.fotos.find_one({"_id": oid})
    if doc is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Foto não encontrada")
    return Response(content=bytes(doc["imagem"]), media_type="image/jpeg")


@router.get("/organograma", response_model=OrganogramaOut)
async def organograma_publico(db: AsyncIOMotorDatabase = Depends(get_database)):
    """Estrutura da paróquia: ministérios, cada um com os seus sectores,
    coordenador e responsáveis — para a área pública, sem login."""
    ministerios_docs = [m async for m in db.ministerios.find().sort("nome", 1)]
    sectores_docs = [s async for s in db.sectores.find().sort("nome", 1)]

    sectores_por_ministerio: dict[str, list[dict]] = {}
    sectores_sem_ministerio: list[dict] = []
    for s in sectores_docs:
        mid = s.get("ministerio_id")
        if mid:
            sectores_por_ministerio.setdefault(mid, []).append(s)
        else:
            sectores_sem_ministerio.append(s)

    def _sector_organograma(s: dict) -> SectorOrganogramaOut:
        return SectorOrganogramaOut(
            id=str(s["_id"]), nome=s["nome"], responsavel_nome=s.get("responsavel_nome")
        )

    ministerios_out = []
    for m in ministerios_docs:
        mid = str(m["_id"])
        ministerios_out.append(MinisterioOrganogramaOut(
            id=mid,
            nome=m["nome"],
            coordenador_nome=m.get("coordenador_nome"),
            sectores=[_sector_organograma(s) for s in sectores_por_ministerio.get(mid, [])],
        ))

    return OrganogramaOut(
        ministerios=ministerios_out,
        sectores_sem_ministerio=[_sector_organograma(s) for s in sectores_sem_ministerio],
    )


async def _buscar_dados_liturgia_externa(chave: str) -> dict:
    """Chamada isolada à API externa — mantida à parte para poder ser
    simulada em testes sem interferir com o cliente de testes (que também
    usa httpx internamente)."""
    async with httpx.AsyncClient(timeout=8.0) as client:
        resposta = await client.get(_LITURGIA_API_URL, params={"date": chave})
        resposta.raise_for_status()
        return resposta.json()


@router.get("/liturgia", response_model=LiturgiaDiariaOut)
async def liturgia_diaria_publico():
    """Leituras da missa do dia (segundo a data em Moçambique), obtidas de
    uma API pública comunitária que espelha o sagradaliturgia.com.br.

    Se a API externa falhar por qualquer razão (fora do ar, formato
    inesperado, etc.), devolve disponivel=false — a app mostra então um
    link direto para a fonte, em vez de rebentar ou mostrar dados errados.
    Resultados bem-sucedidos ficam em cache (em memória) pelo resto do dia,
    para não sobrecarregar o serviço externo a cada visita."""
    hoje = datetime.now(_FUSO_MOCAMBIQUE).date()
    chave = hoje.isoformat()

    if chave in _cache_liturgia:
        return _cache_liturgia[chave]

    try:
        dados = await _buscar_dados_liturgia_externa(chave)

        hoje_dados = dados["today"]
        leituras = hoje_dados["readings"]
        primeira = leituras.get("first_reading")
        segunda = leituras.get("second_reading")
        evangelho = leituras.get("gospel")
        salmo = leituras.get("psalm")

        resultado = LiturgiaDiariaOut(
            disponivel=True,
            data=hoje_dados.get("date"),
            cor_liturgica=hoje_dados.get("color"),
            tempo_liturgico=hoje_dados.get("entry_title"),
            primeira_leitura=LeituraLiturgia(titulo=primeira["title"], texto=primeira["text"]) if primeira else None,
            segunda_leitura=LeituraLiturgia(titulo=segunda["title"], texto=segunda["text"]) if segunda else None,
            salmo=SalmoLiturgia(
                titulo=salmo["title"], resposta=salmo["response"], versos=salmo["content_psalm"],
            ) if salmo else None,
            evangelho=LeituraLiturgia(
                titulo=evangelho.get("head_title") or evangelho.get("title", "Evangelho"),
                texto=evangelho["text"],
            ) if evangelho else None,
            fonte_url=_LITURGIA_FONTE_URL,
        )
    except Exception:
        return LiturgiaDiariaOut(disponivel=False, fonte_url=_LITURGIA_FONTE_URL)

    _cache_liturgia.clear()  # só guarda o dia corrente, liberta dias antigos
    _cache_liturgia[chave] = resultado
    return resultado
