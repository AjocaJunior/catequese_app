from datetime import date, datetime, timedelta, timezone
from io import BytesIO

from bson import ObjectId
from fastapi import APIRouter, Depends, File, Form, HTTPException, Query, Response, UploadFile, status
from motor.motor_asyncio import AsyncIOMotorDatabase
from openpyxl import load_workbook
from pymongo import ReturnDocument

from app.core.database import get_database
from app.core.deps import get_current_admin, get_current_catequista
from app.core.mongo_utils import object_id_or_404
from app.core.permissoes import garantir_acesso_fase
from app.models.catequista import CatequistaOut
from app.models.catequisando import (
    CatequisandoCreate,
    CatequisandoOut,
    CatequisandoUpdate,
    ErroImportacao,
    ImportacaoResultado,
)
from app.services.pdf_lista_catequisandos import gerar_pdf_lista_catequisandos
from app.services.pdf_processo_catequisando import gerar_pdf_processo_catequisando

router = APIRouter(prefix="/catequisandos", tags=["catequisandos"])


async def _fase_nome_ou_erro(db: AsyncIOMotorDatabase, fase_id: str) -> str:
    oid = object_id_or_404(fase_id)
    fase = await db.fases.find_one({"_id": oid})
    if fase is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="A fase indicada não existe")
    return fase["nome"]


async def _sector_nome_ou_erro(db: AsyncIOMotorDatabase, sector_id: str) -> str:
    oid = object_id_or_404(sector_id)
    sector = await db.sectores.find_one({"_id": oid})
    if sector is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="O sector indicado não existe")
    return sector["nome"]


def _to_out(doc: dict, fase_nome: str, sector_nome: str | None = None) -> CatequisandoOut:
    data_nasc = doc.get("data_nascimento")
    return CatequisandoOut(
        id=str(doc["_id"]),
        nome=doc["nome"],
        data_nascimento=data_nasc.date() if data_nasc else None,
        fase_id=doc["fase_id"],
        fase_nome=fase_nome,
        sector_id=doc.get("sector_id"),
        sector_nome=sector_nome,
        encarregado_nome=doc.get("encarregado_nome"),
        encarregado_contacto=doc.get("encarregado_contacto"),
        encarregado_parentesco=doc.get("encarregado_parentesco"),
        observacoes=doc.get("observacoes"),
        criado_em=doc["criado_em"],
    )


@router.post("", response_model=CatequisandoOut, status_code=status.HTTP_201_CREATED)
async def criar_catequisando(
    dados: CatequisandoCreate,
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_catequista),
):
    fase_nome = await _fase_nome_ou_erro(db, dados.fase_id)
    sector_nome = await _sector_nome_ou_erro(db, dados.sector_id) if dados.sector_id else None

    doc = dados.model_dump()
    doc["nome"] = doc["nome"].strip()
    doc["criado_em"] = datetime.now(timezone.utc)
    if doc.get("data_nascimento") is not None:
        doc["data_nascimento"] = datetime.combine(doc["data_nascimento"], datetime.min.time())

    result = await db.catequisandos.insert_one(doc)
    doc["_id"] = result.inserted_id
    return _to_out(doc, fase_nome, sector_nome)


@router.get("", response_model=list[CatequisandoOut])
async def listar_catequisandos(
    fase_id: str | None = Query(None, description="Filtrar por ID da fase"),
    sector_id: str | None = Query(None, description="Filtrar por ID do sector"),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_catequista),
):
    filtro: dict = {}
    if fase_id:
        object_id_or_404(fase_id)
        filtro["fase_id"] = fase_id
    if sector_id:
        object_id_or_404(sector_id)
        filtro["sector_id"] = sector_id

    fases = {str(f["_id"]): f["nome"] async for f in db.fases.find()}
    sectores = {str(s["_id"]): s["nome"] async for s in db.sectores.find()}

    resultado = []
    async for doc in db.catequisandos.find(filtro).sort("nome", 1):
        fase_nome = fases.get(doc["fase_id"], "Fase desconhecida")
        sector_nome = sectores.get(doc.get("sector_id")) if doc.get("sector_id") else None
        resultado.append(_to_out(doc, fase_nome, sector_nome))
    return resultado


@router.get("/pdf")
async def gerar_pdf_lista(
    fase_id: str = Query(...),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_catequista),
):
    fase_oid = object_id_or_404(fase_id)
    fase = await db.fases.find_one({"_id": fase_oid})
    if fase is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="A fase indicada não existe")

    catequistas_ids = fase.get("catequista_ids", [])
    catequistas_nomes: list[str] = []
    if catequistas_ids:
        oids = [ObjectId(i) for i in catequistas_ids if ObjectId.is_valid(i)]
        async for c in db.catequistas.find({"_id": {"$in": oids}}).sort("nome", 1):
            catequistas_nomes.append(c["nome"])

    catequisandos = [doc async for doc in db.catequisandos.find({"fase_id": fase_id}).sort("nome", 1)]

    pdf_bytes = gerar_pdf_lista_catequisandos(fase["nome"], catequistas_nomes, catequisandos)

    nome_ficheiro = "lista_" + "".join(ch if ch.isalnum() else "_" for ch in fase["nome"]) + ".pdf"
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'inline; filename="{nome_ficheiro}"'},
    )


def _excel_serial_para_data(valor) -> date | None:
    try:
        numero = float(valor)
    except (TypeError, ValueError):
        return None
    return (datetime(1899, 12, 30) + timedelta(days=numero)).date()


def _parse_data_nascimento(valor) -> date | None:
    if valor is None or valor == "":
        return None
    if isinstance(valor, datetime):
        return valor.date()
    if isinstance(valor, date):
        return valor
    if isinstance(valor, (int, float)):
        return _excel_serial_para_data(valor)
    if isinstance(valor, str):
        valor = valor.strip()
        if not valor:
            return None
        for fmt in ("%d/%m/%Y", "%Y-%m-%d", "%d-%m-%Y"):
            try:
                return datetime.strptime(valor, fmt).date()
            except ValueError:
                continue
        try:
            return _excel_serial_para_data(float(valor))
        except ValueError:
            return None
    return None


@router.post("/importar", response_model=ImportacaoResultado)
async def importar_catequisandos(
    fase_id: str = Form(...),
    arquivo: UploadFile = File(...),
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_catequista),
):
    """Importa catequisandos a partir de um .xlsx com colunas (nesta ordem):
    Nome | Data de Nascimento | Telefone (contacto do encarregado) | Grau de parentesco.
    Só a coluna Nome é obrigatória; as restantes podem ficar em branco."""
    fase_oid = object_id_or_404(fase_id)
    fase = await db.fases.find_one({"_id": fase_oid})
    if fase is None:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="A fase indicada não existe")

    conteudo = await arquivo.read()
    try:
        wb = load_workbook(BytesIO(conteudo), data_only=True, read_only=True)
        ws = wb.active
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Não foi possível ler o ficheiro. Confirma que é um .xlsx válido.",
        )

    erros: list[ErroImportacao] = []
    criados = 0
    total = 0

    for indice, linha in enumerate(ws.iter_rows(min_row=2, values_only=True), start=2):
        if linha is None or all(v is None for v in linha):
            continue  # linha em branco, ignora sem contar como erro

        total += 1

        nome = str(linha[0]).strip() if len(linha) > 0 and linha[0] is not None else ""
        if len(nome) < 2:
            erros.append(ErroImportacao(linha=indice, motivo="Nome em falta ou demasiado curto"))
            continue

        data_nascimento = _parse_data_nascimento(linha[1]) if len(linha) > 1 else None
        telefone = linha[2] if len(linha) > 2 else None
        contacto = str(telefone).strip() if telefone not in (None, "") else None
        parentesco = str(linha[3]).strip() if len(linha) > 3 and linha[3] not in (None, "") else None

        doc = {
            "nome": nome,
            "fase_id": fase_id,
            "sector_id": None,
            "data_nascimento": datetime.combine(data_nascimento, datetime.min.time()) if data_nascimento else None,
            "encarregado_nome": None,
            "encarregado_contacto": contacto,
            "encarregado_parentesco": parentesco,
            "observacoes": None,
            "criado_em": datetime.now(timezone.utc),
        }
        await db.catequisandos.insert_one(doc)
        criados += 1

    return ImportacaoResultado(total_linhas=total, criados=criados, erros=erros)


@router.get("/{catequisando_id}", response_model=CatequisandoOut)
async def obter_catequisando(
    catequisando_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_catequista),
):
    oid = object_id_or_404(catequisando_id)
    doc = await db.catequisandos.find_one({"_id": oid})
    if doc is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Catequisando não encontrado")

    fase = await db.fases.find_one({"_id": object_id_or_404(doc["fase_id"])})
    sector_nome = None
    if doc.get("sector_id"):
        sector = await db.sectores.find_one({"_id": object_id_or_404(doc["sector_id"])})
        sector_nome = sector["nome"] if sector else None

    return _to_out(doc, fase["nome"] if fase else "Fase desconhecida", sector_nome)


@router.get("/{catequisando_id}/pdf")
async def gerar_pdf_processo(
    catequisando_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    catequista: CatequistaOut = Depends(get_current_catequista),
):
    oid = object_id_or_404(catequisando_id)
    doc = await db.catequisandos.find_one({"_id": oid})
    if doc is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Catequisando não encontrado")

    await garantir_acesso_fase(db, doc["fase_id"], catequista)

    fase = await db.fases.find_one({"_id": object_id_or_404(doc["fase_id"])})
    fase_nome = fase["nome"] if fase else "Fase desconhecida"

    sector_nome = None
    if doc.get("sector_id"):
        sector = await db.sectores.find_one({"_id": object_id_or_404(doc["sector_id"])})
        sector_nome = sector["nome"] if sector else None

    registos = []
    async for p in db.presencas.find({"catequisando_id": catequisando_id}).sort("data", 1):
        registos.append({"data": p["data"].date(), "status": p["status"]})

    pdf_bytes = gerar_pdf_processo_catequisando(doc, fase_nome, registos, sector_nome=sector_nome)

    nome_ficheiro = "processo_" + "".join(ch if ch.isalnum() else "_" for ch in doc["nome"]) + ".pdf"
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'inline; filename="{nome_ficheiro}"'},
    )


@router.put("/{catequisando_id}", response_model=CatequisandoOut)
async def atualizar_catequisando(
    catequisando_id: str,
    dados: CatequisandoUpdate,
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    oid = object_id_or_404(catequisando_id)
    update_doc = dados.model_dump(exclude_unset=True)

    if "nome" in update_doc:
        update_doc["nome"] = update_doc["nome"].strip()
    if "data_nascimento" in update_doc and update_doc["data_nascimento"] is not None:
        update_doc["data_nascimento"] = datetime.combine(update_doc["data_nascimento"], datetime.min.time())
    if "fase_id" in update_doc:
        await _fase_nome_ou_erro(db, update_doc["fase_id"])
    if "sector_id" in update_doc and update_doc["sector_id"]:
        await _sector_nome_ou_erro(db, update_doc["sector_id"])

    if not update_doc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Nada para atualizar")

    doc = await db.catequisandos.find_one_and_update(
        {"_id": oid}, {"$set": update_doc}, return_document=ReturnDocument.AFTER
    )
    if doc is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Catequisando não encontrado")

    fase = await db.fases.find_one({"_id": object_id_or_404(doc["fase_id"])})
    sector_nome = None
    if doc.get("sector_id"):
        sector = await db.sectores.find_one({"_id": object_id_or_404(doc["sector_id"])})
        sector_nome = sector["nome"] if sector else None

    return _to_out(doc, fase["nome"] if fase else "Fase desconhecida", sector_nome)


@router.delete("/{catequisando_id}", status_code=status.HTTP_204_NO_CONTENT)
async def apagar_catequisando(
    catequisando_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    _: CatequistaOut = Depends(get_current_admin),
):
    oid = object_id_or_404(catequisando_id)
    result = await db.catequisandos.delete_one({"_id": oid})
    if result.deleted_count == 0:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Catequisando não encontrado")
