from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from pymongo import ReturnDocument

from app.core.database import get_database
from app.core.deps import get_current_admin, get_current_catequista
from app.core.mongo_utils import object_id_or_404
from app.models.catequista import CatequistaOut
from app.models.pessoa import PessoaCreate, PessoaOut, PessoaUpdate, VinculoPessoaOut

router = APIRouter(prefix="/pessoas", tags=["pessoas"])


def _to_out(doc: dict) -> PessoaOut:
    return PessoaOut(
        id=str(doc["_id"]),
        nome=doc["nome"],
        natural_de=doc.get("natural_de"),
        provincia=doc.get("provincia"),
        estado_civil=doc.get("estado_civil"),
        profissao=doc.get("profissao"),
        residencia=doc.get("residencia"),
        comunidade=doc.get("comunidade"),
        contacto=doc.get("contacto"),
        criado_em=doc["criado_em"],
    )


@router.post("", response_model=PessoaOut, status_code=status.HTTP_201_CREATED)
async def criar_pessoa(
    dados: PessoaCreate,
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_catequista),
):
    """Cria uma pessoa reutilizável (pai, mãe, padrinho ou madrinha de um ou
    mais catequisandos). Antes de criar, pesquisa em GET /pessoas para
    confirmar que esta pessoa ainda não está registada — evita duplicados
    e dados inconsistentes entre irmãos ou afilhados da mesma pessoa."""
    doc = {
        "nome": dados.nome.strip(),
        "natural_de": (dados.natural_de or "").strip() or None,
        "provincia": (dados.provincia or "").strip() or None,
        "estado_civil": (dados.estado_civil or "").strip() or None,
        "profissao": (dados.profissao or "").strip() or None,
        "residencia": (dados.residencia or "").strip() or None,
        "comunidade": (dados.comunidade or "").strip() or None,
        "contacto": (dados.contacto or "").strip() or None,
        "criado_em": datetime.now(timezone.utc),
    }
    result = await db.pessoas.insert_one(doc)
    doc["_id"] = result.inserted_id
    return _to_out(doc)


@router.get("", response_model=list[PessoaOut])
async def listar_pessoas(
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_catequista),
):
    """Lista todas as pessoas — a app filtra localmente por nome (mesmo
    padrão já usado para escolher o catequisando na Caixa/Inscrições)."""
    cursor = db.pessoas.find().sort("nome", 1)
    return [_to_out(doc) async for doc in cursor]


@router.put("/{pessoa_id}", response_model=PessoaOut)
async def atualizar_pessoa(
    pessoa_id: str,
    dados: PessoaUpdate,
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_catequista),
):
    """Corrigir aqui (ex: mudou de residência) atualiza automaticamente em
    todas as fichas de catequisandos que a referenciam — é essa a vantagem
    de não duplicar os dados em cada ficha."""
    oid = object_id_or_404(pessoa_id)
    update_doc = dados.model_dump(exclude_unset=True)
    if "nome" in update_doc:
        update_doc["nome"] = update_doc["nome"].strip()
    for campo in ("natural_de", "provincia", "estado_civil", "profissao", "residencia", "comunidade", "contacto"):
        if campo in update_doc and update_doc[campo] is not None:
            update_doc[campo] = update_doc[campo].strip() or None

    if not update_doc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Nada para atualizar")

    doc = await db.pessoas.find_one_and_update(
        {"_id": oid}, {"$set": update_doc}, return_document=ReturnDocument.AFTER
    )
    if doc is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pessoa não encontrada")

    return _to_out(doc)


@router.get("/{pessoa_id}/vinculos", response_model=list[VinculoPessoaOut])
async def vinculos_da_pessoa(
    pessoa_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_catequista),
):
    """Todos os catequisandos que têm esta pessoa como pai, mãe, padrinho
    ou madrinha — ex: 'quem são os afilhados deste padrinho?'."""
    oid = object_id_or_404(pessoa_id)
    if await db.pessoas.find_one({"_id": oid}) is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pessoa não encontrada")

    resultado: list[VinculoPessoaOut] = []
    campos_papel = {"pai_id": "pai", "mae_id": "mae", "padrinho_id": "padrinho", "madrinha_id": "madrinha"}
    for campo, papel in campos_papel.items():
        async for c in db.catequisandos.find({campo: pessoa_id}):
            resultado.append(VinculoPessoaOut(catequisando_id=str(c["_id"]), catequisando_nome=c["nome"], papel=papel))

    return resultado


@router.delete("/{pessoa_id}", status_code=status.HTTP_204_NO_CONTENT)
async def apagar_pessoa(
    pessoa_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    """Só apaga se já não estiver referenciada por nenhum catequisando —
    caso contrário, edita o registo em vez de apagar, ou primeiro liga
    esses catequisandos a outra pessoa."""
    oid = object_id_or_404(pessoa_id)

    campos = ("pai_id", "mae_id", "padrinho_id", "madrinha_id")
    em_uso = await db.catequisandos.count_documents({"$or": [{c: pessoa_id} for c in campos]})
    if em_uso > 0:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Não é possível apagar: {em_uso} catequisando(s) ainda referenciam esta pessoa",
        )

    result = await db.pessoas.delete_one({"_id": oid})
    if result.deleted_count == 0:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pessoa não encontrada")
