"""
Transição de fase no fecho do Ano Letivo.

Regras (acordadas com a coordenação):
- Só se muda de fase quando o novo Ano Letivo é criado (não ao fechar a pauta).
- Fase normal: quem tem resultado "Progride" vai para a 'Fase seguinte' da
  fase; "Permanece" ou sem resultado fica onde está.
- Fase transitória (ex: Sacramento do Baptismo): o critério de saída não é a
  pauta mas ter data de baptismo registada. (Normalmente quem é baptizado já
  saiu na hora — ver routers/catequisandos.py — isto apanha os restantes.)
- Sem 'Fase seguinte' definida: fica na fase actual e aparece na prévia, para
  o administrador o marcar como Crismado/Transferido ou definir o destino.
  (O fase_id é obrigatório em todo o sistema, por isso não há "sem fase".)
- A matrícula do novo ano não gera registos próprios: quem está activo e ainda
  não tem Inscrição/Renovação lançada na Caixa nesse ano é "pendente" — ver
  listar_matriculas_pendentes.
"""
from datetime import datetime, timezone

from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.pauta_helpers import SITUACOES_FORA_DA_PAUTA, situacao_guardada
from app.models.caixa import CATEGORIAS_MATRICULA
from app.models.transicao import (
    CatequisandoTransicao,
    LinhaTransicaoFase,
    MatriculaPendente,
    PreviaTransicao,
)


async def calcular_transicao(
    db: AsyncIOMotorDatabase, ano_atual: int, novo_ano: int
) -> tuple[PreviaTransicao, list[dict]]:
    """Calcula o que acontece a cada catequisando ao passar de ano_atual para
    novo_ano, sem alterar nada. Devolve a prévia (para mostrar) e a lista de
    movimentos a aplicar."""
    fases = [doc async for doc in db.fases.find().sort("ordem", 1)]
    fases_por_id = {str(f["_id"]): f for f in fases}

    linhas: list[LinhaTransicaoFase] = []
    movimentos: list[dict] = []
    avisos: list[str] = []

    for fase in fases:
        fase_id = str(fase["_id"])
        transitoria = bool(fase.get("transitoria", False))

        destino_id = fase.get("fase_seguinte_id")
        destino = fases_por_id.get(destino_id) if destino_id and destino_id != fase_id else None

        pauta_doc = await db.pautas.find_one({"fase_id": fase_id, "ano_letivo": ano_atual})
        entradas = (pauta_doc.get("situacoes") or {}) if pauta_doc else {}

        linha = LinhaTransicaoFase(
            fase_id=fase_id, fase_nome=fase["nome"], ordem=fase["ordem"],
            transitoria=transitoria,
            fase_seguinte_id=str(destino["_id"]) if destino else None,
            fase_seguinte_nome=destino["nome"] if destino else None,
        )

        async for c in db.catequisandos.find(
            {"fase_id": fase_id, "situacao": {"$nin": SITUACOES_FORA_DA_PAUTA}}
        ).sort("nome", 1):
            cid = str(c["_id"])
            linha.total += 1
            ref = CatequisandoTransicao(catequisando_id=cid, nome=c["nome"])

            if transitoria:
                progride = bool(c.get("baptismo_data"))
                sem_resultado = False
            else:
                situacao = situacao_guardada(entradas.get(cid))
                progride = situacao == "progride"
                sem_resultado = situacao is None

            if progride and destino:
                linha.a_mover += 1
                movimentos.append({
                    "catequisando_id": cid, "nome": c["nome"],
                    "de_fase_id": fase_id, "de_fase_nome": fase["nome"],
                    "para_fase_id": str(destino["_id"]), "para_fase_nome": destino["nome"],
                })
            elif progride:
                linha.sem_fase_seguinte += 1
                linha.lista_sem_fase_seguinte.append(ref)
            else:
                linha.permanecem += 1
                if sem_resultado:
                    linha.por_definir += 1
                    linha.lista_por_definir.append(ref)

        if linha.sem_fase_seguinte:
            avisos.append(
                f"{fase['nome']}: {linha.sem_fase_seguinte} catequisando(s) progridem mas a fase não tem "
                f"'Fase seguinte' definida — ficam em {fase['nome']}. Se concluíram o percurso, marca-os como "
                f"Crismados/Transferidos; se não, define a 'Fase seguinte' em Fases e volta a abrir esta prévia."
            )
        if linha.por_definir:
            avisos.append(
                f"{fase['nome']}: {linha.por_definir} catequisando(s) sem resultado na pauta — ficam na fase. "
                f"Preenche a pauta antes de avançar se algum deve progredir."
            )
        if transitoria and not destino and linha.total:
            avisos.append(
                f"{fase['nome']} é transitória mas não tem 'Fase seguinte' — ninguém poderá sair dela."
            )

        linhas.append(linha)

    previa = PreviaTransicao(
        ano_atual=ano_atual, novo_ano=novo_ano, linhas=linhas,
        total_a_mover=sum(l.a_mover for l in linhas),
        total_permanecem=sum(l.permanecem for l in linhas),
        total_por_definir=sum(l.por_definir for l in linhas),
        total_sem_fase_seguinte=sum(l.sem_fase_seguinte for l in linhas),
        avisos=avisos,
    )
    return previa, movimentos


async def aplicar_movimentos(
    db: AsyncIOMotorDatabase, movimentos: list[dict], ano_anterior: int, novo_ano: int, aplicado_por: str
) -> None:
    """Muda a fase de cada catequisando e guarda um registo da transição
    (quem foi de onde para onde), para auditoria."""
    for m in movimentos:
        await db.catequisandos.update_one(
            {"_id": ObjectId(m["catequisando_id"])}, {"$set": {"fase_id": m["para_fase_id"]}}
        )
    await db.transicoes_ano.insert_one({
        "ano_anterior": ano_anterior,
        "novo_ano": novo_ano,
        "aplicada_em": datetime.now(timezone.utc),
        "aplicada_por": aplicado_por,
        "movimentos": movimentos,
    })


async def listar_matriculas_pendentes(db: AsyncIOMotorDatabase, ano_letivo: int) -> list[MatriculaPendente]:
    """Catequisandos ativos sem Inscrição/Renovação lançada na Caixa para o
    ano indicado — quem ainda tem de renovar. A fase mostrada é a actual (é
    a que a renovação vai sugerir)."""
    ja_matriculados = set(await db.caixa.distinct(
        "catequisando_id",
        {"ano_letivo": ano_letivo, "categoria": {"$in": list(CATEGORIAS_MATRICULA)}},
    ))
    nomes_fases = {str(f["_id"]): f["nome"] async for f in db.fases.find()}
    ordem_fases = {str(f["_id"]): f["ordem"] async for f in db.fases.find()}

    pendentes: list[tuple[int, str, MatriculaPendente]] = []
    async for c in db.catequisandos.find({"situacao": {"$nin": SITUACOES_FORA_DA_PAUTA}}):
        cid = str(c["_id"])
        if cid in ja_matriculados:
            continue
        pendentes.append((
            ordem_fases.get(c["fase_id"], 9999), c["nome"].lower(),
            MatriculaPendente(
                catequisando_id=cid, nome=c["nome"], fase_id=c["fase_id"],
                fase_nome=nomes_fases.get(c["fase_id"], "Fase desconhecida"),
            ),
        ))
    pendentes.sort(key=lambda t: (t[0], t[1]))
    return [p for _, _, p in pendentes]
