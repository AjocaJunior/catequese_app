"""
Helper partilhado para construir a resposta completa de um catequista,
incluindo os campos computados que decidem o que a app mostra no menu:

- tem_fase_atribuida: está atribuído a pelo menos uma fase (como catequista)
- sectores_responsavel: sectores de que é responsável (conta ligada)

Só é usado nos sítios em que a app precisa desta informação completa para
decidir o nível de acesso (registo, login, perfil, /auth/eu, listagem de
catequistas) — o resto do código usa 'app.core.deps.get_current_catequista',
que não computa estes campos (não são precisos para autorizações internas,
só para a app saber o que mostrar no menu).
"""
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.models.catequista import CatequistaOut, SectorResumoCatequista


async def construir_catequista_completo(db: AsyncIOMotorDatabase, doc: dict) -> CatequistaOut:
    catequista_id = str(doc["_id"])

    tem_fase_atribuida = await db.fases.find_one({"catequista_ids": catequista_id}) is not None

    sectores_responsavel = []
    async for s in db.sectores.find({"responsavel_catequista_id": catequista_id}):
        sectores_responsavel.append(SectorResumoCatequista(id=str(s["_id"]), nome=s["nome"]))

    return CatequistaOut(
        id=catequista_id,
        nome=doc["nome"],
        email=doc["email"],
        contacto=doc.get("contacto"),
        is_admin=doc.get("is_admin", False),
        tem_fase_atribuida=tem_fase_atribuida,
        sectores_responsavel=sectores_responsavel,
        criado_em=doc["criado_em"],
    )
