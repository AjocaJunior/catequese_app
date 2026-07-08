from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from pymongo import ReturnDocument

from app.core.ano_letivo import obter_ano_letivo_atual
from app.core.auditoria import registar
from app.core.database import get_database
from app.core.deps import get_current_admin, get_current_catequista
from app.core.mongo_utils import object_id_or_404
from app.models.auditoria import AcaoAuditoria
from app.models.caixa import (
    CATEGORIAS_MATRICULA,
    CaixaTransacaoCreate,
    CaixaTransacaoOut,
    CaixaTransacaoUpdate,
    ResumoCaixa,
    TipoTransacao,
)
from app.models.catequista import CatequistaOut

router = APIRouter(prefix="/caixa", tags=["caixa"])


async def _to_out(db: AsyncIOMotorDatabase, doc: dict) -> CaixaTransacaoOut:
    catequisando_nome = None
    if doc.get("catequisando_id"):
        cat = await db.catequisandos.find_one({"_id": object_id_or_404(doc["catequisando_id"])})
        catequisando_nome = cat["nome"] if cat else None

    fase_nome = None
    if doc.get("fase_id"):
        fase = await db.fases.find_one({"_id": object_id_or_404(doc["fase_id"])})
        fase_nome = fase["nome"] if fase else None

    return CaixaTransacaoOut(
        id=str(doc["_id"]),
        tipo=doc["tipo"],
        categoria=doc["categoria"],
        valor=doc["valor"],
        metodo_pagamento=doc.get("metodo_pagamento"),
        catequisando_id=doc.get("catequisando_id"),
        catequisando_nome=catequisando_nome,
        fase_id=doc.get("fase_id"),
        fase_nome=fase_nome,
        ano_letivo=doc.get("ano_letivo"),
        descricao=doc.get("descricao"),
        data=doc["data"].date(),
        registado_por_nome=doc.get("registado_por_nome", "—"),
        criado_em=doc["criado_em"],
    )


async def _validar_matricula_se_aplicavel(
    db: AsyncIOMotorDatabase,
    categoria: str,
    catequisando_id: str | None,
    fase_id: str | None,
    ano_letivo: int,
    ignorar_id: str | None = None,
) -> None:
    """Para Inscrição/Renovação: exige catequisando + fase, e impede duplicar
    (mesma pessoa, mesmo ano) — cada catequisando só tem uma inscrição ou
    renovação por ano letivo."""
    if categoria not in CATEGORIAS_MATRICULA:
        return

    if not catequisando_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"'{categoria}' exige a seleção do catequisando",
        )
    if not fase_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"'{categoria}' exige a seleção da fase",
        )

    filtro = {
        "catequisando_id": catequisando_id,
        "ano_letivo": ano_letivo,
        "categoria": {"$in": list(CATEGORIAS_MATRICULA)},
    }
    if ignorar_id:
        filtro["_id"] = {"$ne": object_id_or_404(ignorar_id)}
    existente = await db.caixa.find_one(filtro)
    if existente is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Já existe uma inscrição/renovação registada para este catequisando no ano {ano_letivo}",
        )


@router.post("", response_model=CaixaTransacaoOut, status_code=status.HTTP_201_CREATED)
async def criar_transacao(
    dados: CaixaTransacaoCreate,
    db: AsyncIOMotorDatabase = Depends(get_database),
    admin: CatequistaOut = Depends(get_current_admin),
):
    if dados.catequisando_id:
        cat = await db.catequisandos.find_one({"_id": object_id_or_404(dados.catequisando_id)})
        if cat is None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="O catequisando indicado não existe")
    if dados.fase_id:
        fase = await db.fases.find_one({"_id": object_id_or_404(dados.fase_id)})
        if fase is None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="A fase indicada não existe")

    ano_letivo = dados.ano_letivo or await obter_ano_letivo_atual(db)
    await _validar_matricula_se_aplicavel(db, dados.categoria, dados.catequisando_id, dados.fase_id, ano_letivo)

    doc = {
        "tipo": dados.tipo.value,
        "categoria": dados.categoria.strip(),
        "valor": dados.valor,
        "metodo_pagamento": dados.metodo_pagamento.value if dados.metodo_pagamento else None,
        "catequisando_id": dados.catequisando_id,
        "fase_id": dados.fase_id,
        "ano_letivo": ano_letivo,
        "descricao": (dados.descricao or "").strip() or None,
        "data": datetime.combine(dados.data, datetime.min.time()),
        "registado_por_nome": admin.nome,
        "criado_em": datetime.now(timezone.utc),
    }
    result = await db.caixa.insert_one(doc)
    doc["_id"] = result.inserted_id

    resumo_texto = f"Registou {doc['tipo']} '{doc['categoria']}' de {doc['valor']:.2f} MT"
    if dados.catequisando_id:
        cat = await db.catequisandos.find_one({"_id": object_id_or_404(dados.catequisando_id)})
        if cat:
            resumo_texto += f" para {cat['nome']}"
    if dados.metodo_pagamento:
        resumo_texto += f" ({dados.metodo_pagamento.value})"
    await registar(db, admin, AcaoAuditoria.CRIAR, "Caixa", str(result.inserted_id), resumo_texto)

    return await _to_out(db, doc)


@router.get("", response_model=list[CaixaTransacaoOut])
async def listar_transacoes(
    tipo: TipoTransacao | None = Query(None),
    ano_letivo: int | None = Query(None),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_catequista),
):
    filtro: dict = {}
    if tipo:
        filtro["tipo"] = tipo.value
    if ano_letivo:
        filtro["ano_letivo"] = ano_letivo
    cursor = db.caixa.find(filtro).sort("data", -1)
    return [await _to_out(db, doc) async for doc in cursor]


@router.get("/resumo", response_model=ResumoCaixa)
async def resumo(
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_catequista),
):
    total_receitas = 0.0
    total_despesas = 0.0
    async for doc in db.caixa.find():
        if doc["tipo"] == TipoTransacao.RECEITA.value:
            total_receitas += doc["valor"]
        else:
            total_despesas += doc["valor"]

    return ResumoCaixa(
        total_receitas=total_receitas,
        total_despesas=total_despesas,
        saldo=total_receitas - total_despesas,
    )


@router.put("/{transacao_id}", response_model=CaixaTransacaoOut)
async def atualizar_transacao(
    transacao_id: str,
    dados: CaixaTransacaoUpdate,
    db: AsyncIOMotorDatabase = Depends(get_database),
    admin: CatequistaOut = Depends(get_current_admin),
):
    oid = object_id_or_404(transacao_id)
    atual = await db.caixa.find_one({"_id": oid})
    if atual is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Transação não encontrada")

    update_doc = dados.model_dump(exclude_unset=True)

    if "catequisando_id" in update_doc and update_doc["catequisando_id"]:
        cat = await db.catequisandos.find_one({"_id": object_id_or_404(update_doc["catequisando_id"])})
        if cat is None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="O catequisando indicado não existe")
    if "fase_id" in update_doc and update_doc["fase_id"]:
        fase = await db.fases.find_one({"_id": object_id_or_404(update_doc["fase_id"])})
        if fase is None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="A fase indicada não existe")
    if "categoria" in update_doc:
        update_doc["categoria"] = update_doc["categoria"].strip()
    if "descricao" in update_doc and update_doc["descricao"] is not None:
        update_doc["descricao"] = update_doc["descricao"].strip() or None
    if "data" in update_doc:
        update_doc["data"] = datetime.combine(update_doc["data"], datetime.min.time())
    if "tipo" in update_doc:
        update_doc["tipo"] = update_doc["tipo"].value
    if "metodo_pagamento" in update_doc and update_doc["metodo_pagamento"] is not None:
        update_doc["metodo_pagamento"] = update_doc["metodo_pagamento"].value

    if not update_doc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Nada para atualizar")

    categoria_final = update_doc.get("categoria", atual["categoria"])
    catequisando_final = update_doc.get("catequisando_id", atual.get("catequisando_id"))
    fase_final = update_doc.get("fase_id", atual.get("fase_id"))
    ano_final = update_doc.get("ano_letivo", atual.get("ano_letivo")) or await obter_ano_letivo_atual(db)
    await _validar_matricula_se_aplicavel(
        db, categoria_final, catequisando_final, fase_final, ano_final, ignorar_id=transacao_id
    )

    doc = await db.caixa.find_one_and_update(
        {"_id": oid}, {"$set": update_doc}, return_document=ReturnDocument.AFTER
    )

    await registar(
        db, admin, AcaoAuditoria.ATUALIZAR, "Caixa", transacao_id,
        f"Atualizou transação '{doc['categoria']}' — {doc['valor']:.2f} MT",
    )

    return await _to_out(db, doc)


@router.delete("/{transacao_id}", status_code=status.HTTP_204_NO_CONTENT)
async def apagar_transacao(
    transacao_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    admin: CatequistaOut = Depends(get_current_admin),
):
    oid = object_id_or_404(transacao_id)
    atual = await db.caixa.find_one({"_id": oid})
    if atual is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Transação não encontrada")

    await db.caixa.delete_one({"_id": oid})

    await registar(
        db, admin, AcaoAuditoria.APAGAR, "Caixa", transacao_id,
        f"Apagou transação '{atual['categoria']}' — {atual['valor']:.2f} MT",
    )
