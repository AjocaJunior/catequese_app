from fastapi import APIRouter, Depends, HTTPException, Query, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.ano_letivo import garantir_atribuicao_catequista, obter_ano_letivo_atual
from app.core.auditoria import registar
from app.core.database import get_database
from app.core.deps import get_current_admin, get_current_catequista
from app.core.pauta_helpers import congelar_rosters
from app.core.transicao import aplicar_movimentos, calcular_transicao
from app.models.auditoria import AcaoAuditoria
from app.models.catequista import CatequistaOut
from app.models.configuracao import AtualizarAnoLetivoRequest, AvancarAnoOut, ConfiguracaoOut
from app.models.transicao import PreviaTransicao

router = APIRouter(prefix="/configuracao", tags=["configuração"])


@router.get("", response_model=ConfiguracaoOut)
async def obter_configuracao(
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_catequista),
):
    return ConfiguracaoOut(ano_letivo_atual=await obter_ano_letivo_atual(db))


@router.get("/ano-letivo/previa-transicao", response_model=PreviaTransicao)
async def previa_transicao(
    novo_ano: int | None = Query(None, ge=2020, le=2100),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    """O que aconteceria a cada catequisando se o ano avançasse agora —
    não altera nada. Serve para o administrador rever (e corrigir pautas ou
    fases seguintes) antes de confirmar."""
    ano_atual = await obter_ano_letivo_atual(db)
    previa, _movimentos = await calcular_transicao(db, ano_atual, novo_ano or ano_atual + 1)
    return previa


@router.put("/ano-letivo", response_model=AvancarAnoOut)
async def avancar_ano_letivo(
    dados: AtualizarAnoLetivoRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
    admin: CatequistaOut = Depends(get_current_admin),
):
    """Avança o ano letivo corrente. As atribuições de catequistas às fases
    são propagadas como ponto de partida do novo ano (continuam iguais até
    serem alteradas individualmente em 'Catequistas da fase' — o que só
    afeta o novo ano; o anterior fica congelado).

    Com `aplicar_transicao`, quem tem resultado "Progride" passa para a
    'Fase seguinte' da sua fase (ver core/transicao.py). Em qualquer caso, a
    lista de cada fase no ano que fecha é congelada primeiro, para as pautas
    e relatórios desse ano não mudarem quando as pessoas mudam de fase.

    A matrícula de cada um no novo ano fica registada quando a respetiva
    inscrição/renovação for lançada na Caixa (ver routers/caixa.py); quem
    ainda não a tem aparece como pendente em Relatórios."""
    ano_atual = await obter_ano_letivo_atual(db)
    if dados.novo_ano <= ano_atual:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"O novo ano tem de ser posterior ao ano corrente ({ano_atual})",
        )

    fases = [doc async for doc in db.fases.find()]

    # Garante que o ano que está a terminar fica bem registado (cobre quem
    # nunca teve a lista de catequistas da fase alterada, e por isso ainda
    # não tinha atribuição alguma nesse ano).
    for fase in fases:
        for cid in fase.get("catequista_ids", []):
            await garantir_atribuicao_catequista(db, cid, str(fase["_id"]), ano_letivo=ano_atual)

    # Novo ano começa como cópia do estado actual.
    for fase in fases:
        for cid in fase.get("catequista_ids", []):
            await garantir_atribuicao_catequista(db, cid, str(fase["_id"]), ano_letivo=dados.novo_ano)

    # 1) Congela quem fez parte de cada fase no ano que fecha — ANTES de mover ninguém.
    await congelar_rosters(db, ano_atual)

    # 2) Transição de fase (opcional): calcula sobre o estado do ano que fecha.
    previa = None
    if dados.aplicar_transicao:
        previa, movimentos = await calcular_transicao(db, ano_atual, dados.novo_ano)
        await aplicar_movimentos(db, movimentos, ano_atual, dados.novo_ano, admin.nome)

    # 3) Só no fim muda o ano corrente.
    await db.configuracao.update_one(
        {"_id": "geral"}, {"$set": {"ano_letivo_atual": dados.novo_ano}}, upsert=True
    )

    detalhe = f"Avançou o ano letivo de {ano_atual} para {dados.novo_ano}"
    if previa is not None:
        detalhe += (
            f" — transição aplicada: {previa.total_a_mover} movido(s), "
            f"{previa.total_permanecem} ficaram na fase"
        )
    await registar(db, admin, AcaoAuditoria.ATUALIZAR, "Configuração", None, detalhe)

    return AvancarAnoOut(
        ano_letivo_atual=dados.novo_ano,
        transicao_aplicada=previa is not None,
        movidos=previa.total_a_mover if previa else 0,
        permaneceram=previa.total_permanecem if previa else 0,
        por_definir=previa.total_por_definir if previa else 0,
        sem_fase_seguinte=previa.total_sem_fase_seguinte if previa else 0,
    )
