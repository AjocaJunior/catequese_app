from fastapi import APIRouter, Depends, Query, Response
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.ano_letivo import obter_ano_letivo_atual
from app.core.database import get_database
from app.core.deps import get_current_admin
from app.core.pauta_helpers import cids_da_fase_no_ano, montar_pauta
from app.core.transicao import listar_matriculas_pendentes
from app.models.caixa import CATEGORIA_INSCRICAO, CATEGORIA_RENOVACAO, CATEGORIAS_MATRICULA
from app.models.catequista import CatequistaOut
from app.models.pauta import Situacao
from app.models.relatorio import (
    GrupoFaseObservacoes,
    LinhaObservacao,
    LinhaRelatorioAssiduidade,
    LinhaRelatorioFaseGenero,
    LinhaRelatorioInscricoes,
    LinhaRelatorioSituacaoFinal,
    RelatorioAssiduidade,
    RelatorioCatequisandosPorFaseGenero,
    RelatorioInscricoes,
    RelatorioObservacoes,
    RelatorioSituacaoFinal,
)
from app.models.transicao import MatriculaPendente
from app.services.pdf_relatorio_assiduidade import gerar_pdf_relatorio_assiduidade
from app.services.pdf_relatorio_estatistico import gerar_pdf_relatorio_fase_genero
from app.services.pdf_relatorio_inscricoes import gerar_pdf_relatorio_inscricoes
from app.services.pdf_relatorio_observacoes import gerar_pdf_relatorio_observacoes
from app.services.pdf_relatorio_situacao_final import gerar_pdf_relatorio_situacao_final

router = APIRouter(prefix="/relatorios", tags=["relatórios"])


async def _montar_relatorio_fase_genero(db: AsyncIOMotorDatabase) -> RelatorioCatequisandosPorFaseGenero:
    """Contagem por fase e género dos catequisandos ATIVOS, pelo estado actual
    (fase_id de cada um agora) — a mesma fonte já usada em Situação Final e
    Assiduidade. Antes derivava-se da inscrição/renovação na Caixa, o que
    deixava o relatório a mostrar sempre 0 sempre que essa matrícula não
    tivesse sido lançada lá para o ano em questão."""
    fases = [doc async for doc in db.fases.find().sort("ordem", 1)]
    ano = await obter_ano_letivo_atual(db)

    linhas: list[LinhaRelatorioFaseGenero] = []
    total_m = total_f = total_n = 0
    for fase in fases:
        fase_id = str(fase["_id"])
        m = f = n = 0
        async for cat in db.catequisandos.find({"fase_id": fase_id, "situacao": "ativo"}):
            genero = cat.get("genero")
            if genero == "masculino":
                m += 1
            elif genero == "feminino":
                f += 1
            else:
                n += 1
        linhas.append(LinhaRelatorioFaseGenero(
            fase_id=fase_id, fase_nome=fase["nome"], ordem=fase["ordem"],
            masculino=m, feminino=f, nao_informado=n, total=m + f + n,
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
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    return await _montar_relatorio_fase_genero(db)


@router.get("/catequisandos-por-fase-genero/pdf")
async def relatorio_fase_genero_pdf(
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    relatorio = await _montar_relatorio_fase_genero(db)
    pdf_bytes = gerar_pdf_relatorio_fase_genero(relatorio)
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'inline; filename="relatorio_fase_genero_{relatorio.ano_letivo}.pdf"'},
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


async def _montar_relatorio_inscricoes(db: AsyncIOMotorDatabase, ano: int) -> RelatorioInscricoes:
    """Por fase: quantos catequisandos ativos tem agora, e quantos já têm
    inscrição ou renovação lançada na Caixa para o ano indicado — a
    diferença são os pendentes (quem ainda não pagou/renovou)."""
    fases = [doc async for doc in db.fases.find().sort("ordem", 1)]
    ano_atual = await obter_ano_letivo_atual(db)

    transacoes_por_fase: dict[str, list[dict]] = {}
    async for doc in db.caixa.find({"ano_letivo": ano, "categoria": {"$in": list(CATEGORIAS_MATRICULA)}}):
        fid = doc.get("fase_id")
        if fid:
            transacoes_por_fase.setdefault(fid, []).append(doc)

    linhas: list[LinhaRelatorioInscricoes] = []
    tot_cat = tot_insc = tot_renov = tot_pend = 0
    tot_valor = 0.0
    for fase in fases:
        fase_id = str(fase["_id"])
        if ano < ano_atual:
            # Ano fechado: quem fez parte da fase nesse ano (a fase actual de
            # cada um já pode ser outra, por causa da transição).
            total_catequisandos = len(await cids_da_fase_no_ano(db, fase_id, ano))
        else:
            total_catequisandos = await db.catequisandos.count_documents({"fase_id": fase_id, "situacao": "ativo"})
        transacoes = transacoes_por_fase.get(fase_id, [])
        inscricoes = sum(1 for t in transacoes if t["categoria"] == CATEGORIA_INSCRICAO)
        renovacoes = sum(1 for t in transacoes if t["categoria"] == CATEGORIA_RENOVACAO)
        total_registado = inscricoes + renovacoes
        valor_total = sum(t["valor"] for t in transacoes)
        pendentes = max(total_catequisandos - total_registado, 0)

        linhas.append(LinhaRelatorioInscricoes(
            fase_id=fase_id, fase_nome=fase["nome"], ordem=fase["ordem"],
            total_catequisandos=total_catequisandos, inscricoes=inscricoes, renovacoes=renovacoes,
            total_registado=total_registado, pendentes=pendentes, valor_total=round(valor_total, 2),
        ))
        tot_cat += total_catequisandos
        tot_insc += inscricoes
        tot_renov += renovacoes
        tot_valor += valor_total
        tot_pend += pendentes

    return RelatorioInscricoes(
        ano_letivo=ano, linhas=linhas,
        total_catequisandos=tot_cat, total_inscricoes=tot_insc, total_renovacoes=tot_renov,
        total_registado=tot_insc + tot_renov, total_pendentes=tot_pend, valor_total=round(tot_valor, 2),
    )


@router.get("/inscricoes/pendentes", response_model=list[MatriculaPendente])
async def inscricoes_pendentes(
    ano_letivo: int | None = Query(None),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    """Quem ainda não tem Inscrição/Renovação lançada no ano (por defeito, o
    corrente) — a lista de nomes por trás da coluna 'Pendentes'."""
    ano = ano_letivo or await obter_ano_letivo_atual(db)
    return await listar_matriculas_pendentes(db, ano)


@router.get("/inscricoes", response_model=RelatorioInscricoes)
async def relatorio_inscricoes(
    ano_letivo: int | None = Query(None),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    ano = ano_letivo or await obter_ano_letivo_atual(db)
    return await _montar_relatorio_inscricoes(db, ano)


@router.get("/inscricoes/pdf")
async def relatorio_inscricoes_pdf(
    ano_letivo: int | None = Query(None),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    ano = ano_letivo or await obter_ano_letivo_atual(db)
    relatorio = await _montar_relatorio_inscricoes(db, ano)
    pdf_bytes = gerar_pdf_relatorio_inscricoes(relatorio)
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'inline; filename="relatorio_inscricoes_{ano}.pdf"'},
    )


async def _montar_relatorio_observacoes(db: AsyncIOMotorDatabase) -> RelatorioObservacoes:
    """Lista todos os catequisandos com o campo 'observações' preenchido,
    agrupados por fase — não depende do ano letivo, é sempre o estado atual
    (a observação é uma nota viva, não um registo histórico por ano)."""
    fases = [doc async for doc in db.fases.find().sort("ordem", 1)]

    grupos: list[GrupoFaseObservacoes] = []
    total = 0
    for fase in fases:
        fase_id = str(fase["_id"])
        cursor = db.catequisandos.find({
            "fase_id": fase_id,
            "observacoes": {"$nin": [None, ""]},
        }).sort("nome", 1)

        linhas: list[LinhaObservacao] = []
        numero = 1
        async for doc in cursor:
            linhas.append(LinhaObservacao(
                numero=numero, catequisando_id=str(doc["_id"]), nome=doc["nome"], observacoes=doc["observacoes"],
            ))
            numero += 1

        if linhas:
            grupos.append(GrupoFaseObservacoes(
                fase_id=fase_id, fase_nome=fase["nome"], ordem=fase["ordem"], linhas=linhas,
            ))
            total += len(linhas)

    return RelatorioObservacoes(grupos=grupos, total=total)


@router.get("/observacoes", response_model=RelatorioObservacoes)
async def relatorio_observacoes(
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    return await _montar_relatorio_observacoes(db)


@router.get("/observacoes/pdf")
async def relatorio_observacoes_pdf(
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    relatorio = await _montar_relatorio_observacoes(db)
    pdf_bytes = gerar_pdf_relatorio_observacoes(relatorio)
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": 'inline; filename="relatorio_observacoes.pdf"'},
    )
