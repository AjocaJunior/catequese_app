from fastapi import APIRouter, Depends, Query, Response
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.ano_letivo import obter_ano_letivo_atual
from app.core.database import get_database
from app.core.deps import get_current_admin
from app.core.mongo_utils import object_id_or_404
from app.core.pauta_helpers import montar_pauta
from app.models.caixa import CATEGORIAS_MATRICULA
from app.models.catequista import CatequistaOut
from app.models.pauta import Situacao
from app.models.relatorio import (
    LinhaRelatorioAssiduidade,
    LinhaRelatorioFaseGenero,
    LinhaRelatorioSituacaoFinal,
    RelatorioAssiduidade,
    RelatorioCatequisandosPorFaseGenero,
    RelatorioSituacaoFinal,
)
from app.services.pdf_relatorio_assiduidade import gerar_pdf_relatorio_assiduidade
from app.services.pdf_relatorio_estatistico import gerar_pdf_relatorio_fase_genero
from app.services.pdf_relatorio_situacao_final import gerar_pdf_relatorio_situacao_final

router = APIRouter(prefix="/relatorios", tags=["relatórios"])


async def _montar_relatorio_fase_genero(
    db: AsyncIOMotorDatabase, ano: int
) -> RelatorioCatequisandosPorFaseGenero:
    """A 'matrícula' de cada catequisando no ano indicado é derivada da sua
    inscrição/renovação registada nesse ano na Caixa (categoria + fase_id +
    ano_letivo) — a mesma fonte usada em GET /catequisandos/{id}/historico."""
    matriculas: dict[str, str] = {}
    async for doc in db.caixa.find({"ano_letivo": ano, "categoria": {"$in": list(CATEGORIAS_MATRICULA)}}):
        if doc.get("catequisando_id") and doc.get("fase_id"):
            matriculas[doc["catequisando_id"]] = doc["fase_id"]

    generos: dict[str, str | None] = {}
    if matriculas:
        oids = [object_id_or_404(cid) for cid in matriculas]
        async for cat in db.catequisandos.find({"_id": {"$in": oids}}):
            generos[str(cat["_id"])] = cat.get("genero")

    fases = [doc async for doc in db.fases.find().sort("ordem", 1)]

    linhas: list[LinhaRelatorioFaseGenero] = []
    total_m = total_f = total_n = 0
    for fase in fases:
        fase_id = str(fase["_id"])
        ids_desta_fase = [cid for cid, fid in matriculas.items() if fid == fase_id]
        m = sum(1 for cid in ids_desta_fase if generos.get(cid) == "masculino")
        f = sum(1 for cid in ids_desta_fase if generos.get(cid) == "feminino")
        n = len(ids_desta_fase) - m - f
        linhas.append(LinhaRelatorioFaseGenero(
            fase_id=fase_id, fase_nome=fase["nome"], ordem=fase["ordem"],
            masculino=m, feminino=f, nao_informado=n, total=len(ids_desta_fase),
        ))
        total_m += m
        total_f += f
        total_n += n

    return RelatorioCatequisandosPorFaseGenero(
        ano_letivo=ano, linhas=linhas,
        total_masculino=total_m, total_feminino=total_f, total_nao_informado=total_n,
        total_geral=total_m + total_f + total_n,
    )


@router.get("/catequisandos-por-fase-genero", response_model=RelatorioCatequisandosPorFaseGenero)
async def relatorio_fase_genero(
    ano_letivo: int | None = Query(None),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    ano = ano_letivo or await obter_ano_letivo_atual(db)
    return await _montar_relatorio_fase_genero(db, ano)


@router.get("/catequisandos-por-fase-genero/pdf")
async def relatorio_fase_genero_pdf(
    ano_letivo: int | None = Query(None),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    ano = ano_letivo or await obter_ano_letivo_atual(db)
    relatorio = await _montar_relatorio_fase_genero(db, ano)
    pdf_bytes = gerar_pdf_relatorio_fase_genero(relatorio)
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'inline; filename="relatorio_fase_genero_{ano}.pdf"'},
    )


@router.get("/anos-disponiveis", response_model=list[int])
async def anos_disponiveis(
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    """Anos letivos com pelo menos uma inscrição/renovação registada, mais o
    ano corrente (mesmo que ainda sem dados) — para preencher o filtro."""
    anos = await db.caixa.distinct("ano_letivo", {"categoria": {"$in": list(CATEGORIAS_MATRICULA)}})
    ano_atual = await obter_ano_letivo_atual(db)
    return sorted(set(anos) | {ano_atual}, reverse=True)


async def _montar_relatorio_situacao_final(db: AsyncIOMotorDatabase, ano: int) -> RelatorioSituacaoFinal:
    """Reaproveita a mesma pauta (permanece/progride) já usada no módulo de
    Pautas — este relatório é só a vista agregada de todas as fases."""
    fases = [doc async for doc in db.fases.find().sort("ordem", 1)]

    linhas: list[LinhaRelatorioSituacaoFinal] = []
    total_perm = total_prog = total_indef = 0
    for fase in fases:
        pauta = await montar_pauta(db, fase, ano)
        permanece = sum(1 for i in pauta.itens if i.situacao == Situacao.PERMANECE)
        progride = sum(1 for i in pauta.itens if i.situacao == Situacao.PROGRIDE)
        indef = sum(1 for i in pauta.itens if i.situacao is None)
        linhas.append(LinhaRelatorioSituacaoFinal(
            fase_id=str(fase["_id"]), fase_nome=fase["nome"], ordem=fase["ordem"],
            permanece=permanece, progride=progride, por_definir=indef, total=len(pauta.itens),
        ))
        total_perm += permanece
        total_prog += progride
        total_indef += indef

    return RelatorioSituacaoFinal(
        ano_letivo=ano, linhas=linhas,
        total_permanece=total_perm, total_progride=total_prog, total_por_definir=total_indef,
        total_geral=total_perm + total_prog + total_indef,
    )


@router.get("/situacao-final", response_model=RelatorioSituacaoFinal)
async def relatorio_situacao_final(
    ano_letivo: int | None = Query(None),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    ano = ano_letivo or await obter_ano_letivo_atual(db)
    return await _montar_relatorio_situacao_final(db, ano)


@router.get("/situacao-final/pdf")
async def relatorio_situacao_final_pdf(
    ano_letivo: int | None = Query(None),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    ano = ano_letivo or await obter_ano_letivo_atual(db)
    relatorio = await _montar_relatorio_situacao_final(db, ano)
    pdf_bytes = gerar_pdf_relatorio_situacao_final(relatorio)
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'inline; filename="relatorio_situacao_final_{ano}.pdf"'},
    )


async def _montar_relatorio_assiduidade(db: AsyncIOMotorDatabase, ano: int) -> RelatorioAssiduidade:
    fases = [doc async for doc in db.fases.find().sort("ordem", 1)]

    linhas: list[LinhaRelatorioAssiduidade] = []
    total_p = total_f = total_fj = 0
    for fase in fases:
        pauta = await montar_pauta(db, fase, ano)
        p = sum(i.total_presencas for i in pauta.itens)
        f = sum(i.total_faltas for i in pauta.itens)
        fj = sum(i.total_faltas_justificadas for i in pauta.itens)
        registos = p + f + fj
        taxa = (p / registos * 100) if registos > 0 else 0.0
        linhas.append(LinhaRelatorioAssiduidade(
            fase_id=str(fase["_id"]), fase_nome=fase["nome"], ordem=fase["ordem"],
            total_catequisandos=len(pauta.itens), total_presencas=p, total_faltas=f,
            total_faltas_justificadas=fj, taxa_assiduidade=round(taxa, 1),
        ))
        total_p += p
        total_f += f
        total_fj += fj

    registos_geral = total_p + total_f + total_fj
    taxa_geral = (total_p / registos_geral * 100) if registos_geral > 0 else 0.0

    return RelatorioAssiduidade(ano_letivo=ano, linhas=linhas, taxa_geral=round(taxa_geral, 1))


@router.get("/assiduidade", response_model=RelatorioAssiduidade)
async def relatorio_assiduidade(
    ano_letivo: int | None = Query(None),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    ano = ano_letivo or await obter_ano_letivo_atual(db)
    return await _montar_relatorio_assiduidade(db, ano)


@router.get("/assiduidade/pdf")
async def relatorio_assiduidade_pdf(
    ano_letivo: int | None = Query(None),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    ano = ano_letivo or await obter_ano_letivo_atual(db)
    relatorio = await _montar_relatorio_assiduidade(db, ano)
    pdf_bytes = gerar_pdf_relatorio_assiduidade(relatorio)
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'inline; filename="relatorio_assiduidade_{ano}.pdf"'},
    )
