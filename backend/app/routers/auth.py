import secrets
from datetime import datetime, timedelta, timezone

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from motor.motor_asyncio import AsyncIOMotorDatabase
from pymongo.errors import DuplicateKeyError
from starlette.concurrency import run_in_threadpool

from app.core.database import get_database
from app.core.deps import get_current_catequista
from app.core.security import create_access_token, hash_password, verify_password
from app.models.catequista import (
    AlterarSenhaRequest,
    AtualizarPerfilRequest,
    CatequistaCreate,
    CatequistaOut,
    EsqueciSenhaRequest,
    RedefinirSenhaRequest,
    Token,
)
from app.services.email_service import enviar_email

router = APIRouter(prefix="/auth", tags=["autenticação"])


def _normalizar_nome(nome: str) -> str:
    return " ".join(nome.strip().lower().split())


@router.post("/registar", response_model=CatequistaOut, status_code=status.HTTP_201_CREATED)
async def registar(dados: CatequistaCreate, db: AsyncIOMotorDatabase = Depends(get_database)):
    # O primeiro catequista a registar-se numa base de dados nova torna-se
    # administrador automaticamente (bootstrap). Os seguintes ficam sem
    # permissões de admin até serem promovidos por um administrador existente.
    ja_existem = await db.catequistas.count_documents({})
    is_admin = ja_existem == 0

    nome_normalizado = _normalizar_nome(dados.nome)
    if await db.catequistas.find_one({"nome_normalizado": nome_normalizado}):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Já existe um catequista registado com o nome '{dados.nome.strip()}'",
        )

    doc = {
        "nome": dados.nome.strip(),
        "nome_normalizado": nome_normalizado,
        "email": dados.email.lower().strip(),
        "hashed_password": hash_password(dados.password),
        "is_admin": is_admin,
        "criado_em": datetime.now(timezone.utc),
    }
    try:
        result = await db.catequistas.insert_one(doc)
    except DuplicateKeyError:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Já existe um catequista registado com este email",
        )

    return CatequistaOut(
        id=str(result.inserted_id),
        nome=doc["nome"],
        email=doc["email"],
        contacto=doc.get("contacto"),
        is_admin=doc["is_admin"],
        criado_em=doc["criado_em"],
    )


@router.post("/login", response_model=Token)
async def login(
    form: OAuth2PasswordRequestForm = Depends(),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    doc = await db.catequistas.find_one({"email": form.username.lower().strip()})
    if not doc or not verify_password(form.password, doc["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email ou palavra-passe incorretos",
            headers={"WWW-Authenticate": "Bearer"},
        )

    catequista_out = CatequistaOut(
        id=str(doc["_id"]),
        nome=doc["nome"],
        email=doc["email"],
        contacto=doc.get("contacto"),
        is_admin=doc.get("is_admin", False),
        criado_em=doc["criado_em"],
    )
    token = create_access_token(subject=str(doc["_id"]))
    return Token(access_token=token, catequista=catequista_out)


@router.get("/eu", response_model=CatequistaOut)
async def eu(catequista: CatequistaOut = Depends(get_current_catequista)):
    return catequista


@router.put("/perfil", response_model=CatequistaOut)
async def atualizar_perfil(
    dados: AtualizarPerfilRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
    catequista: CatequistaOut = Depends(get_current_catequista),
):
    update_doc = dados.model_dump(exclude_unset=True)
    if "nome" in update_doc:
        update_doc["nome"] = update_doc["nome"].strip()
    if "contacto" in update_doc and update_doc["contacto"] is not None:
        update_doc["contacto"] = update_doc["contacto"].strip() or None

    if update_doc:
        await db.catequistas.update_one({"_id": ObjectId(catequista.id)}, {"$set": update_doc})

    doc = await db.catequistas.find_one({"_id": ObjectId(catequista.id)})
    return CatequistaOut(
        id=str(doc["_id"]),
        nome=doc["nome"],
        email=doc["email"],
        contacto=doc.get("contacto"),
        is_admin=doc.get("is_admin", False),
        criado_em=doc["criado_em"],
    )


@router.put("/senha", status_code=status.HTTP_204_NO_CONTENT)
async def alterar_senha(
    dados: AlterarSenhaRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
    catequista: CatequistaOut = Depends(get_current_catequista),
):
    doc = await db.catequistas.find_one({"_id": ObjectId(catequista.id)})
    if doc is None or not verify_password(dados.senha_atual, doc["hashed_password"]):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Palavra-passe atual incorreta")

    await db.catequistas.update_one(
        {"_id": ObjectId(catequista.id)},
        {"$set": {"hashed_password": hash_password(dados.nova_senha)}},
    )


@router.post("/esqueci-senha")
async def esqueci_senha(
    dados: EsqueciSenhaRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    doc = await db.catequistas.find_one({"email": dados.email.lower().strip()})
    if doc is not None:
        codigo = f"{secrets.randbelow(1_000_000):06d}"
        expira_em = datetime.now(timezone.utc) + timedelta(minutes=15)
        await db.catequistas.update_one(
            {"_id": doc["_id"]},
            {"$set": {"reset_codigo": codigo, "reset_expira_em": expira_em}},
        )
        corpo = (
            f"Olá {doc['nome']},\n\n"
            "Recebemos um pedido para redefinir a tua palavra-passe na app Gestão Catequética.\n"
            f"O teu código de confirmação é: {codigo}\n\n"
            "Este código expira em 15 minutos. Se não foste tu a pedir, ignora este email."
        )
        try:
            await run_in_threadpool(enviar_email, doc["email"], "Redefinir palavra-passe", corpo)
        except Exception:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Não foi possível enviar o email. Contacta o administrador.",
            )

    # Resposta genérica sempre — não revela se o email existe ou não na base de dados
    return {"mensagem": "Se o email existir, foi enviado um código de confirmação."}


@router.post("/redefinir-senha", status_code=status.HTTP_204_NO_CONTENT)
async def redefinir_senha(
    dados: RedefinirSenhaRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    doc = await db.catequistas.find_one({"email": dados.email.lower().strip()})

    expira_em = doc.get("reset_expira_em") if doc else None
    if expira_em is not None and expira_em.tzinfo is None:
        expira_em = expira_em.replace(tzinfo=timezone.utc)

    codigo_valido = (
        doc is not None
        and doc.get("reset_codigo") == dados.codigo
        and expira_em is not None
        and expira_em >= datetime.now(timezone.utc)
    )
    if not codigo_valido:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Código inválido ou expirado")

    await db.catequistas.update_one(
        {"_id": doc["_id"]},
        {
            "$set": {"hashed_password": hash_password(dados.nova_senha)},
            "$unset": {"reset_codigo": "", "reset_expira_em": ""},
        },
    )
