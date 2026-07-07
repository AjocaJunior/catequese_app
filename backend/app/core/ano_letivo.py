"""
Mecanismo de Ano Letivo — lado dos catequistas.

'Fase.catequista_ids' continua a representar sempre a atribuição ACTUAL (é o
que os outros módulos já leem — presenças, permissões, etc. — sem precisarem
de saber nada disto).

Por baixo, sempre que essa lista muda, regista-se também uma cópia
"congelada" no ano letivo corrente, na coleção 'atribuicoes_catequista'
(catequista → fase, por ano).

Do lado dos catequisandos, o histórico por ano letivo não usa este
mecanismo — deriva-se diretamente das inscrições/renovações registadas na
Caixa (cada uma já regista catequisando + fase + ano letivo), porque essa é
a acção real que já acontece todos os anos (ver routers/caixa.py).

Quando o admin avança para um novo ano letivo (ver routers/configuracao.py),
o ano anterior fica com as atribuições de catequista congeladas, e o novo
ano começa como cópia do estado actual, só alterado dali em diante.
"""
from datetime import datetime, timezone

from motor.motor_asyncio import AsyncIOMotorDatabase

ANO_LETIVO_PADRAO = 2026  # ano em que este mecanismo foi introduzido


async def obter_ano_letivo_atual(db: AsyncIOMotorDatabase) -> int:
    doc = await db.configuracao.find_one({"_id": "geral"})
    if doc is None:
        await db.configuracao.insert_one({"_id": "geral", "ano_letivo_atual": ANO_LETIVO_PADRAO})
        return ANO_LETIVO_PADRAO
    return doc["ano_letivo_atual"]


async def garantir_atribuicao_catequista(
    db: AsyncIOMotorDatabase,
    catequista_id: str,
    fase_id: str,
    ano_letivo: int | None = None,
) -> None:
    """Regista a atribuição de um catequista a uma fase, no ano indicado."""
    if ano_letivo is None:
        ano_letivo = await obter_ano_letivo_atual(db)

    await db.atribuicoes_catequista.update_one(
        {"catequista_id": catequista_id, "fase_id": fase_id, "ano_letivo": ano_letivo},
        {"$setOnInsert": {"criado_em": datetime.now(timezone.utc)}},
        upsert=True,
    )


async def sincronizar_atribuicoes_fase(
    db: AsyncIOMotorDatabase, fase_id: str, catequista_ids: list[str]
) -> None:
    """Alinha as atribuições do ano corrente com a lista actual de
    catequistas de uma fase — remove quem saiu, acrescenta quem entrou."""
    ano_letivo = await obter_ano_letivo_atual(db)

    await db.atribuicoes_catequista.delete_many({
        "fase_id": fase_id,
        "ano_letivo": ano_letivo,
        "catequista_id": {"$nin": catequista_ids},
    })
    for cid in catequista_ids:
        await garantir_atribuicao_catequista(db, cid, fase_id, ano_letivo)
