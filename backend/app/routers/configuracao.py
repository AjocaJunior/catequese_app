from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.ano_letivo import garantir_atribuicao_catequista, obter_ano_letivo_atual
from app.core.database import get_database
from app.core.deps import get_current_admin, get_current_catequista
from app.models.catequista import CatequistaOut
from app.models.configuracao import AtualizarAnoLetivoRequest, ConfiguracaoOut

router = APIRouter(prefix="/configuracao", tags=["configuração"])


@router.get("", response_model=ConfiguracaoOut)
async def obter_configuracao(
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_catequista),
):
    return ConfiguracaoOut(ano_letivo_atual=await obter_ano_letivo_atual(db))


@router.put("/ano-letivo", response_model=ConfiguracaoOut)
async def avancar_ano_letivo(
    dados: AtualizarAnoLetivoRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    """Avança o ano letivo corrente. As atribuições de catequistas às fases
    são propagadas como ponto de partida do novo ano (continuam iguais até
    serem alteradas individualmente em 'Catequistas da fase' — o que só
    afeta o novo ano; o anterior fica congelado).

    Os catequisandos não são tocados aqui: a matrícula de cada um no novo
    ano fica registada organicamente quando a respetiva inscrição/renovação
    for lançada na Caixa (ver routers/caixa.py)."""
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

    await db.configuracao.update_one(
        {"_id": "geral"}, {"$set": {"ano_letivo_atual": dados.novo_ano}}, upsert=True
    )

    return ConfiguracaoOut(ano_letivo_atual=dados.novo_ano)
