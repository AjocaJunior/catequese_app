from datetime import datetime

from motor.motor_asyncio import AsyncIOMotorDatabase

from app.models.pauta import ItemPautaOut, PautaOut


async def montar_pauta(db: AsyncIOMotorDatabase, fase: dict, ano_letivo: int) -> PautaOut:
    """Estatísticas de presença + situação (permanece/progride) de cada
    catequisando ATIVO da fase, no ano letivo indicado. Catequisandos já
    marcados como Crismados não entram (já concluíram e já têm a sua
    situação final registada num ano anterior)."""
    fase_id = str(fase["_id"])
    inicio = datetime(ano_letivo, 1, 1)
    fim = datetime(ano_letivo + 1, 1, 1)

    pauta_doc = await db.pautas.find_one({"fase_id": fase_id, "ano_letivo": ano_letivo})
    situacoes_guardadas = pauta_doc.get("situacoes", {}) if pauta_doc else {}

    itens: list[ItemPautaOut] = []
    async for c in db.catequisandos.find({"fase_id": fase_id, "situacao": {"$ne": "crismado"}}).sort("nome", 1):
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
