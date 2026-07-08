"""
Gestão da ligação ao MongoDB (via Motor, driver assíncrono).
A ligação é criada uma vez no arranque da aplicação (ver main.py -> lifespan)
e reutilizada em todos os pedidos.
"""
import certifi
from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase

from app.core.config import get_settings

settings = get_settings()


class MongoDB:
    client: AsyncIOMotorClient | None = None
    db: AsyncIOMotorDatabase | None = None


mongodb = MongoDB()


async def connect_to_mongo() -> None:
    # tlsCAFile=certifi.where() evita erros de SSL handshake comuns no Windows,
    # onde a cadeia de certificados do sistema por vezes não é reconhecida corretamente.
    mongodb.client = AsyncIOMotorClient(
        settings.MONGODB_URI,
        tlsCAFile=certifi.where(),
        serverSelectionTimeoutMS=10000,
    )
    mongodb.db = mongodb.client[settings.DB_NAME]


async def close_mongo_connection() -> None:
    if mongodb.client:
        mongodb.client.close()


async def _normalizar(nome: str) -> str:
    return " ".join(nome.strip().lower().split())


async def _backfill_nome_normalizado(colecao) -> None:
    """Preenche 'nome_normalizado' em documentos antigos que ainda não o têm
    (criados antes deste campo existir) — necessário para a verificação de
    unicidade por nome funcionar também para dados já existentes."""
    async for doc in colecao.find({"nome_normalizado": {"$exists": False}}):
        await colecao.update_one(
            {"_id": doc["_id"]},
            {"$set": {"nome_normalizado": await _normalizar(doc["nome"])}},
        )


async def _criar_indice_seguro(colecao, chave, **kwargs) -> None:
    """Cria um índice sem derrubar o arranque da app se já existirem dados
    que violem a restrição (ex: nomes duplicados anteriores a esta versão).
    Nesse caso, a restrição fica só ao nível da aplicação até os duplicados
    serem resolvidos manualmente (ver scripts/encontrar_duplicados.py)."""
    try:
        await colecao.create_index(chave, **kwargs)
    except Exception as e:
        print(f"AVISO: não foi possível criar o índice {chave} em {colecao.name}: {e}")
        print("Provavelmente há dados duplicados. Corre scripts/encontrar_duplicados.py para os localizar.")


async def ensure_indexes() -> None:
    """Cria índices necessários. Chamado uma vez no arranque da aplicação."""
    await _backfill_nome_normalizado(mongodb.db.catequistas)
    await _backfill_nome_normalizado(mongodb.db.catequisandos)

    await mongodb.db.catequistas.create_index("email", unique=True)
    await _criar_indice_seguro(mongodb.db.catequistas, "nome_normalizado", unique=True, sparse=True)
    await mongodb.db.fases.create_index("nome", unique=True)
    await mongodb.db.fases.create_index("catequista_ids")
    await mongodb.db.catequisandos.create_index("fase_id")
    await mongodb.db.catequisandos.create_index("nome")
    await _criar_indice_seguro(mongodb.db.catequisandos, "nome_normalizado", unique=True, sparse=True)
    await mongodb.db.presencas.create_index([("catequisando_id", 1), ("data", 1)], unique=True)
    await mongodb.db.presencas.create_index([("fase_id", 1), ("data", 1)])
    await mongodb.db.retiros.create_index("data")
    await mongodb.db.eventos.create_index("data")
    await mongodb.db.sectores.create_index("nome")
    await mongodb.db.sectores.create_index("responsavel_catequista_id")
    await mongodb.db.ministerios.create_index("nome")
    await mongodb.db.catequisandos.create_index("sector_id")
    await mongodb.db.fotos.create_index("criado_em")
    await mongodb.db.caixa.create_index("data")
    await mongodb.db.caixa.create_index("catequisando_id")
    await mongodb.db.inventario.create_index("nome")
    await _criar_indice_seguro(
        mongodb.db.atribuicoes_catequista,
        [("catequista_id", 1), ("fase_id", 1), ("ano_letivo", 1)],
        unique=True,
    )
    await mongodb.db.caixa.create_index([("catequisando_id", 1), ("ano_letivo", 1), ("categoria", 1)])
    await _criar_indice_seguro(mongodb.db.pautas, [("fase_id", 1), ("ano_letivo", 1)], unique=True)
    await mongodb.db.auditoria.create_index("data")
    await mongodb.db.auditoria.create_index("entidade")
    await mongodb.db.auditoria.create_index("catequista_id")


def get_database() -> AsyncIOMotorDatabase:
    """Dependency para usar nos routers: db = Depends(get_database)"""
    return mongodb.db
