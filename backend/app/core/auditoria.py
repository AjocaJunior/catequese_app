"""
Registo de auditoria — um log central e simples de "quem fez o quê, quando",
para consulta pelo administrador (nunca visível ao público).

Em vez de espalhar campos criado_por/atualizado_por por todas as coleções da
app, cada endpoint de escrita relevante chama 'registar()' depois de concluir
a ação. Alguns modelos mais sensíveis (Caixa, Inventário) também guardam
criado_por_nome/atualizado_por_nome directamente no próprio registo, para
quem quiser ver isso sem ir aos logs.
"""
from datetime import datetime, timezone

from motor.motor_asyncio import AsyncIOMotorDatabase

from app.models.auditoria import AcaoAuditoria
from app.models.catequista import CatequistaOut


async def registar(
    db: AsyncIOMotorDatabase,
    catequista: CatequistaOut,
    acao: AcaoAuditoria,
    entidade: str,
    entidade_id: str | None,
    resumo: str,
) -> None:
    await db.auditoria.insert_one({
        "data": datetime.now(timezone.utc),
        "catequista_id": catequista.id if catequista else None,
        "catequista_nome": catequista.nome if catequista else "Sistema",
        "acao": acao.value,
        "entidade": entidade,
        "entidade_id": entidade_id,
        "resumo": resumo,
    })
