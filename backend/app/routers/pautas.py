from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, Query, Response
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.ano_letivo import obter_ano_letivo_atual
from app.core.database import get_database
from app.core.deps import get_current_catequista
from app.core.permissoes import garantir_acesso_fase
from app.models.catequista import CatequistaOut
from app.models.pauta import DefinirPautaRequest, ItemPautaOut, PautaOut
from app.services.pdf_pauta import gerar_pdf_pauta

router = APIRouter(prefix="/pautas", tags=["pautas"])


async def _montar_pauta(db: AsyncIOMotorDatabase, fase: dict, ano_letivo: int) -> PautaOut:
    fase_id = str(fase["_id"])
    inicio = datetime(ano_letivo, 1, 1)
    fim = datetime(ano_letivo + 1, 1, 1)

    pauta_doc = await db.pautas.find_one({"fase_id": fase_id, "ano_letivo": ano_letivo})
    situacoes_guardadas = pauta_doc.get("situacoes", {}) if pauta_doc else {}

    itens: list[ItemPautaOut] = []
    async for c in db.catequisandos.find({"fase_id": fase_id}).sort("nome", 1):
        catequisando_id = str(c["_id"])
        presencas = 0
        faltas = 0
        faltas_justificadas = 0
        async for p in db.presencas.find({
            "catequisando_id": catequisando_id,
            "fase_id": fase_id,
            "data": {"$gte": inicio, "$lt": fim},
        }):
            if p["status"] == "presente":
                presencas += 1
            elif p["status"] == "falta":
                faltas += 1
            elif p["status"] == "falta_justificada":
                faltas_justificadas += 1

        itens.append(ItemPautaOut(
            catequisando_id=catequisando_id,
            catequisando_nome=c["nome"],
            total_presencas=presencas,
            total_faltas=faltas,
            total_faltas_justificadas=faltas_justificadas,
            situacao=situacoes_guardadas.get(catequisando_id),
        ))

    return PautaOut(
        fase_id=fase_id,
        fase_nome=fase["nome"],
        ano_letivo=ano_letivo,
        itens=itens,
        atualizado_em=pauta_doc.get("atualizado_em") if pauta_doc else None,
        atualizado_por_nome=pauta_doc.get("atualizado_por_nome") if pauta_doc else None,
    )


@router.get("", response_model=PautaOut)
async def obter_pauta(
    fase_id: str = Query(...),
    ano_letivo: int | None = Query(None),
    db: AsyncIOMotorDatabase = Depends(get_database),
    catequista: CatequistaOut = Depends(get_current_catequista),
):
    fase = await garantir_acesso_fase(db, fase_id, catequista)
    ano = ano_letivo or await obter_ano_letivo_atual(db)
    return await _montar_pauta(db, fase, ano)


@router.put("", response_model=PautaOut)
async def definir_pauta(
    dados: DefinirPautaRequest,
    fase_id: str = Query(...),
    ano_letivo: int | None = Query(None),
    db: AsyncIOMotorDatabase = Depends(get_database),
    catequista: CatequistaOut = Depends(get_current_catequista),
):
    fase = await garantir_acesso_fase(db, fase_id, catequista)
    ano = ano_letivo or await obter_ano_letivo_atual(db)

    situacoes = {item.catequisando_id: item.situacao.value for item in dados.situacoes}

    await db.pautas.update_one(
        {"fase_id": fase_id, "ano_letivo": ano},
        {
            "$set": {
                "situacoes": situacoes,
                "atualizado_em": datetime.now(timezone.utc),
                "atualizado_por_nome": catequista.nome,
            }
        },
        upsert=True,
    )

    return await _montar_pauta(db, fase, ano)


@router.get("/pdf")
async def gerar_pdf(
    fase_id: str = Query(...),
    ano_letivo: int | None = Query(None),
    db: AsyncIOMotorDatabase = Depends(get_database),
    catequista: CatequistaOut = Depends(get_current_catequista),
):
    fase = await garantir_acesso_fase(db, fase_id, catequista)
    ano = ano_letivo or await obter_ano_letivo_atual(db)
    pauta = await _montar_pauta(db, fase, ano)

    pdf_bytes = gerar_pdf_pauta(pauta)

    nome_ficheiro = "pauta_" + "".join(ch if ch.isalnum() else "_" for ch in fase["nome"]) + f"_{ano}.pdf"
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'inline; filename="{nome_ficheiro}"'},
    )
