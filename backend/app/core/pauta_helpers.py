from datetime import datetime, timezone

from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.ano_letivo import obter_ano_letivo_atual
from app.models.pauta import ItemPautaOut, PautaOut

# Situações que já não entram nas pautas/presenças do ano em curso.
SITUACOES_FORA_DA_PAUTA = ["crismado", "transferido"]


def situacao_guardada(entrada) -> str | None:
    """A situação (permanece/progride) guardada numa entrada da pauta.
    Formato antigo: a própria string. Formato novo: objecto com 'situacao'."""
    if isinstance(entrada, dict):
        return entrada.get("situacao")
    return entrada


async def cids_da_fase_no_ano(
    db: AsyncIOMotorDatabase, fase_id: str, ano_letivo: int, pauta_doc: dict | None = None
) -> set[str]:
    """Quem passou por esta fase neste ano letivo, independentemente da fase
    em que está AGORA: quem tem presenças marcadas na fase nesse ano, quem
    tem entrada guardada na pauta, e a lista congelada quando o ano fechou
    (ver congelar_rosters). É isto que mantém o histórico do ano intacto
    depois de os catequisandos mudarem de fase."""
    inicio = datetime(ano_letivo, 1, 1)
    fim = datetime(ano_letivo + 1, 1, 1)

    cids: set[str] = set()
    for cid in await db.presencas.distinct(
        "catequisando_id", {"fase_id": fase_id, "data": {"$gte": inicio, "$lt": fim}}
    ):
        if cid:
            cids.add(cid)

    if pauta_doc is None:
        pauta_doc = await db.pautas.find_one({"fase_id": fase_id, "ano_letivo": ano_letivo})
    if pauta_doc:
        cids.update((pauta_doc.get("situacoes") or {}).keys())
        cids.update(pauta_doc.get("roster_ids") or [])
    return cids


async def montar_pauta(db: AsyncIOMotorDatabase, fase: dict, ano_letivo: int) -> PautaOut:
    """Estatísticas de presença + resultado (permanece/progride), comportamento
    e observação de cada catequisando da fase, no ano letivo indicado.

    - Ano corrente (ou futuro): os catequisandos ATIVOS que estão agora na fase,
      mais quem já passou por ela este ano mas entretanto mudou de fase (ex:
      baptizado que passou para o Aprofundamento a meio do ano). Crismados e
      transferidos não entram (já concluíram / saíram).
    - Ano já fechado: exactamente quem passou pela fase nesse ano — a fase
      actual de cada um já não conta, para o histórico não se perder."""
    fase_id = str(fase["_id"])
    inicio = datetime(ano_letivo, 1, 1)
    fim = datetime(ano_letivo + 1, 1, 1)
    ano_atual = await obter_ano_letivo_atual(db)
    ano_fechado = ano_letivo < ano_atual

    pauta_doc = await db.pautas.find_one({"fase_id": fase_id, "ano_letivo": ano_letivo})
    entradas_guardadas = pauta_doc.get("situacoes", {}) if pauta_doc else {}

    docs: dict[str, dict] = {}
    if not ano_fechado:
        async for c in db.catequisandos.find({"fase_id": fase_id, "situacao": {"$nin": SITUACOES_FORA_DA_PAUTA}}):
            docs[str(c["_id"])] = c

    historicos = await cids_da_fase_no_ano(db, fase_id, ano_letivo, pauta_doc)
    em_falta = [ObjectId(i) for i in historicos - docs.keys() if ObjectId.is_valid(i)]
    if em_falta:
        async for c in db.catequisandos.find({"_id": {"$in": em_falta}}):
            if not ano_fechado and c.get("situacao") in SITUACOES_FORA_DA_PAUTA:
                continue
            docs[str(c["_id"])] = c

    itens: list[ItemPautaOut] = []
    for c in sorted(docs.values(), key=lambda d: d["nome"].lower()):
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

        # Formato antigo guardava só a string da situação (ex: "progride").
        # O novo guarda um objeto com situação + comportamento + observação.
        # Aceita os dois, para não perder pautas já preenchidas antes.
        entrada = entradas_guardadas.get(catequisando_id)
        if isinstance(entrada, dict):
            situacao = entrada.get("situacao")
            comportamento = entrada.get("comportamento")
            observacao = entrada.get("observacao")
        else:
            situacao = entrada
            comportamento = None
            observacao = None

        itens.append(ItemPautaOut(
            catequisando_id=catequisando_id,
            catequisando_nome=c["nome"],
            genero=c.get("genero"),
            total_presencas=presencas,
            total_faltas=faltas,
            total_faltas_justificadas=faltas_justificadas,
            situacao=situacao,
            comportamento=comportamento,
            observacao=observacao,
        ))

    return PautaOut(
        fase_id=fase_id,
        fase_nome=fase["nome"],
        ano_letivo=ano_letivo,
        itens=itens,
        atualizado_em=pauta_doc.get("atualizado_em") if pauta_doc else None,
        atualizado_por_nome=pauta_doc.get("atualizado_por_nome") if pauta_doc else None,
    )


async def congelar_rosters(db: AsyncIOMotorDatabase, ano_letivo: int) -> int:
    """Guarda, para cada fase, a lista de quem fez parte dela em `ano_letivo`.
    Chama-se ao fechar o ano, ANTES de qualquer catequisando mudar de fase —
    é o que torna a pauta e os relatórios desse ano imutáveis daí em diante.
    Devolve o número de fases congeladas."""
    fases = [doc async for doc in db.fases.find()]
    agora = datetime.now(timezone.utc)
    for fase in fases:
        pauta = await montar_pauta(db, fase, ano_letivo)
        await db.pautas.update_one(
            {"fase_id": str(fase["_id"]), "ano_letivo": ano_letivo},
            {"$set": {"roster_ids": [i.catequisando_id for i in pauta.itens], "congelada_em": agora}},
            upsert=True,
        )
    return len(fases)
