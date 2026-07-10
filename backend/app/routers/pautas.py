from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, Query, Response
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.ano_letivo import obter_ano_letivo_atual
from app.core.auditoria import registar
from app.core.database import get_database
from app.core.deps import get_current_catequista
from app.core.pauta_helpers import montar_pauta
from app.core.permissoes import garantir_acesso_fase
from app.models.auditoria import AcaoAuditoria
from app.models.catequista import CatequistaOut
from app.models.pauta import DefinirPautaRequest, PautaOut
from app.services.pdf_pauta import gerar_pdf_pauta

router = APIRouter(prefix="/pautas", tags=["pautas"])


@router.get("", response_model=PautaOut)
async def obter_pauta(
    fase_id: str = Query(...),
    ano_letivo: int | None = Query(None),
    db: AsyncIOMotorDatabase = Depends(get_database),
    catequista: CatequistaOut = Depends(get_current_catequista),
):
    fase = await garantir_acesso_fase(db, fase_id, catequista)
    ano = ano_letivo or await obter_ano_letivo_atual(db)
    return await montar_pauta(db, fase, ano)


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

    await registar(
        db, catequista, AcaoAuditoria.ATUALIZAR, "Pauta", fase_id,
        f"Definiu a pauta de '{fase['nome']}' para o ano {ano} ({len(situacoes)} situação(ões) preenchida(s))",
    )

    return await montar_pauta(db, fase, ano)


@router.get("/pdf")
async def gerar_pdf(
    fase_id: str = Query(...),
    ano_letivo: int | None = Query(None),
    db: AsyncIOMotorDatabase = Depends(get_database),
    catequista: CatequistaOut = Depends(get_current_catequista),
):
    fase = await garantir_acesso_fase(db, fase_id, catequista)
    ano = ano_letivo or await obter_ano_letivo_atual(db)
    pauta = await montar_pauta(db, fase, ano)

    pdf_bytes = gerar_pdf_pauta(pauta)

    nome_ficheiro = "pauta_" + "".join(ch if ch.isalnum() else "_" for ch in fase["nome"]) + f"_{ano}.pdf"
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'inline; filename="{nome_ficheiro}"'},
    )
