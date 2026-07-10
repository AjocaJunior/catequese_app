from datetime import date, datetime, timezone

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.auditoria import registar
from app.core.database import get_database
from app.core.deps import get_current_catequista
from app.core.mongo_utils import object_id_or_404
from app.core.permissoes import garantir_acesso_fase
from app.models.auditoria import AcaoAuditoria
from app.models.catequista import CatequistaOut
from app.models.presenca import (
    HistoricoPresencasOut,
    LinhaRelatorioPresencas,
    ListaPresencasOut,
    MarcarPresencasRequest,
    PresencaOut,
    RegistoPresenca,
    StatusPresenca,
)
from app.services.pdf_relatorio_presencas import gerar_pdf_relatorio_presencas

router = APIRouter(prefix="/presencas", tags=["presenças"])


async def _listar(db: AsyncIOMotorDatabase, fase_id: str, dia: date) -> ListaPresencasOut:
    data_dt = datetime.combine(dia, datetime.min.time())

    catequisandos = [
        c async for c in db.catequisandos.find({"fase_id": fase_id, "situacao": {"$ne": "crismado"}}).sort("nome", 1)
    ]
    marcadas = {
        p["catequisando_id"]: p["status"]
        async for p in db.presencas.find({"fase_id": fase_id, "data": data_dt})
    }

    presencas = [
        PresencaOut(
            catequisando_id=str(c["_id"]),
            catequisando_nome=c["nome"],
            # catequisando sem registo para esta data conta como falta por omissão
            status=marcadas.get(str(c["_id"]), StatusPresenca.FALTA.value),
        )
        for c in catequisandos
    ]

    return ListaPresencasOut(fase_id=fase_id, data=dia, presencas=presencas)


@router.put("", response_model=ListaPresencasOut)
async def marcar_presencas(
    dados: MarcarPresencasRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
    catequista: CatequistaOut = Depends(get_current_catequista),
):
    await garantir_acesso_fase(db, dados.fase_id, catequista)

    data_dt = datetime.combine(dados.data, datetime.min.time())

    for item in dados.presencas:
        object_id_or_404(item.catequisando_id)  # valida só o formato
        await db.presencas.update_one(
            {"catequisando_id": item.catequisando_id, "data": data_dt},
            {
                "$set": {
                    "fase_id": dados.fase_id,
                    "status": item.status.value,
                    "marcado_por": catequista.id,
                    "atualizado_em": datetime.now(timezone.utc),
                }
            },
            upsert=True,
        )

    resultado = await _listar(db, dados.fase_id, dados.data)

    presentes = sum(1 for p in resultado.presencas if p.status == StatusPresenca.PRESENTE)
    faltas = sum(1 for p in resultado.presencas if p.status == StatusPresenca.FALTA)
    faltas_just = sum(1 for p in resultado.presencas if p.status == StatusPresenca.FALTA_JUSTIFICADA)
    fase = await db.fases.find_one({"_id": object_id_or_404(dados.fase_id)})

    await registar(
        db, catequista, AcaoAuditoria.ATUALIZAR, "Presença", dados.fase_id,
        f"Marcou presenças de '{fase['nome'] if fase else dados.fase_id}' em {dados.data} "
        f"({presentes} presença(s), {faltas} falta(s), {faltas_just} justificada(s))",
    )

    return resultado


@router.get("", response_model=ListaPresencasOut)
async def listar_presencas(
    fase_id: str = Query(...),
    data: date = Query(...),
    db: AsyncIOMotorDatabase = Depends(get_database),
    catequista: CatequistaOut = Depends(get_current_catequista),
):
    await garantir_acesso_fase(db, fase_id, catequista)
    return await _listar(db, fase_id, data)


@router.get("/relatorio")
async def gerar_relatorio(
    fase_id: str = Query(...),
    db: AsyncIOMotorDatabase = Depends(get_database),
    catequista: CatequistaOut = Depends(get_current_catequista),
):
    fase = await garantir_acesso_fase(db, fase_id, catequista)

    catequistas_ids = fase.get("catequista_ids", [])
    catequistas_nomes: list[str] = []
    if catequistas_ids:
        oids = [ObjectId(i) for i in catequistas_ids if ObjectId.is_valid(i)]
        async for c in db.catequistas.find({"_id": {"$in": oids}}).sort("nome", 1):
            catequistas_nomes.append(c["nome"])

    catequisandos = [
        doc async for doc in db.catequisandos.find({"fase_id": fase_id, "situacao": {"$ne": "crismado"}}).sort("nome", 1)
    ]

    linhas: list[LinhaRelatorioPresencas] = []
    for c in catequisandos:
        registos = [p async for p in db.presencas.find({"catequisando_id": str(c["_id"])})]
        presencas_count = sum(1 for r in registos if r["status"] == StatusPresenca.PRESENTE.value)
        faltas_count = sum(1 for r in registos if r["status"] == StatusPresenca.FALTA.value)
        faltas_just_count = sum(1 for r in registos if r["status"] == StatusPresenca.FALTA_JUSTIFICADA.value)
        linhas.append(LinhaRelatorioPresencas(
            catequisando_id=str(c["_id"]),
            nome=c["nome"],
            presencas=presencas_count,
            faltas=faltas_count,
            faltas_justificadas=faltas_just_count,
            total=len(registos),
        ))

    pdf_bytes = gerar_pdf_relatorio_presencas(fase["nome"], catequistas_nomes, linhas)

    nome_ficheiro = "relatorio_presencas_" + "".join(ch if ch.isalnum() else "_" for ch in fase["nome"]) + ".pdf"
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'inline; filename="{nome_ficheiro}"'},
    )


@router.get("/catequisando/{catequisando_id}", response_model=HistoricoPresencasOut)
async def historico_presencas_catequisando(
    catequisando_id: str,
    db: AsyncIOMotorDatabase = Depends(get_database),
    catequista: CatequistaOut = Depends(get_current_catequista),
):
    oid = object_id_or_404(catequisando_id)
    cat_doc = await db.catequisandos.find_one({"_id": oid})
    if cat_doc is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Catequisando não encontrado")

    await garantir_acesso_fase(db, cat_doc["fase_id"], catequista)

    registos: list[RegistoPresenca] = []
    async for p in db.presencas.find({"catequisando_id": catequisando_id}).sort("data", 1):
        registos.append(RegistoPresenca(data=p["data"].date(), status=p["status"]))

    total_presencas = sum(1 for r in registos if r.status == StatusPresenca.PRESENTE)
    total_faltas = sum(1 for r in registos if r.status == StatusPresenca.FALTA)
    total_faltas_justificadas = sum(1 for r in registos if r.status == StatusPresenca.FALTA_JUSTIFICADA)

    return HistoricoPresencasOut(
        catequisando_id=catequisando_id,
        total_registos=len(registos),
        total_presencas=total_presencas,
        total_faltas=total_faltas,
        total_faltas_justificadas=total_faltas_justificadas,
        registos=registos,
    )
