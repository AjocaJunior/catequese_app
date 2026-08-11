import logging
import secrets
from datetime import datetime, timedelta, timezone

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.security import OAuth2PasswordRequestForm
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token as google_id_token
from motor.motor_asyncio import AsyncIOMotorDatabase
from pymongo.errors import DuplicateKeyError
from starlette.concurrency import run_in_threadpool

from app.core.auditoria import registar as registar_auditoria
from app.core.catequista_helpers import construir_catequista_completo
from app.core.config import get_settings
from app.core.database import get_database
from app.core.deps import get_current_catequista
from app.core.rate_limit import limiter
from app.core.security import create_access_token, hash_password, verify_password
from app.models.auditoria import AcaoAuditoria
from app.models.catequista import (
    AlterarSenhaRequest,
    AtualizarPerfilRequest,
    CatequistaCreate,
    CatequistaOut,
    EsqueciSenhaRequest,
    LoginGoogleRequest,
    RedefinirSenhaRequest,
    Token,
)
from app.services.email_service import enviar_email

router = APIRouter(prefix="/auth", tags=["autenticação"])


def _normalizar_nome(nome: str) -> str:
    return " ".join(nome.strip().lower().split())


@router.post("/registar", response_model=CatequistaOut, status_code=status.HTTP_201_CREATED)
@limiter.limit("5/minute")
async def registar(request: Request, dados: CatequistaCreate, db: AsyncIOMotorDatabase = Depends(get_database)):
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

    doc["_id"] = result.inserted_id
    catequista_out = await construir_catequista_completo(db, doc)
    await registar_auditoria(
        db, catequista_out, AcaoAuditoria.CRIAR, "Catequista", str(result.inserted_id),
        "Registou-se na aplicação" + (" (administrador inicial)" if is_admin else ""),
    )
    return catequista_out


@router.post("/login", response_model=Token)
@limiter.limit("8/minute")
async def login(
    request: Request,
    form: OAuth2PasswordRequestForm = Depends(),
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    doc = await db.catequistas.find_one({"email": form.username.lower().strip()})
    if not doc or not doc.get("hashed_password") or not verify_password(form.password, doc["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email ou palavra-passe incorretos",
            headers={"WWW-Authenticate": "Bearer"},
        )

    catequista_out = await construir_catequista_completo(db, doc)
    token = create_access_token(subject=str(doc["_id"]))
    return Token(access_token=token, catequista=catequista_out)


@router.post("/google", response_model=Token)
@limiter.limit("10/minute")
async def login_google(
    request: Request,
    dados: LoginGoogleRequest,
    db: AsyncIOMotorDatabase = Depends(get_database),
):
    """Inicia sessão (ou regista automaticamente, se for a primeira vez)
    usando um token de identidade do Google — validado pelo backend, nunca
    confiado apenas porque o frontend diz que é válido."""
    settings = get_settings()
    if not settings.GOOGLE_CLIENT_ID:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Iniciar sessão com Google ainda não está configurado nesta instalação",
        )

    try:
        payload = google_id_token.verify_oauth2_token(
            dados.id_token, google_requests.Request(), settings.GOOGLE_CLIENT_ID,
        )
    except ValueError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token do Google inválido ou expirado")

    email = payload.get("email")
    if not email or not payload.get("email_verified", False):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="O email da conta Google não está verificado")
    email = email.lower().strip()
    nome_google = (payload.get("name") or email).strip()

    doc = await db.catequistas.find_one({"email": email})

    if doc is None:
        # Primeira vez com esta conta Google — regista automaticamente.
        # O primeiro catequista de sempre continua a tornar-se admin,
        # independentemente de se registar por password ou por Google.
        ja_existem = await db.catequistas.count_documents({})
        is_admin = ja_existem == 0
        novo_doc = {
            "nome": nome_google,
            "nome_normalizado": _normalizar_nome(nome_google),
            "email": email,
            "hashed_password": None,
            "is_admin": is_admin,
            "criado_em": datetime.now(timezone.utc),
        }
        try:
            result = await db.catequistas.insert_one(novo_doc)
        except DuplicateKeyError:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail=f"Já existe um catequista registado com o nome '{nome_google}' — contacta um administrador.",
            )
        novo_doc["_id"] = result.inserted_id
        doc = novo_doc
        catequista_out = await construir_catequista_completo(db, doc)
        await registar_auditoria(
            db, catequista_out, AcaoAuditoria.CRIAR, "Catequista", str(result.inserted_id),
            "Registou-se com Google" + (" (administrador inicial)" if is_admin else ""),
        )
    else:
        # Conta já existente (criada por password ou por Google antes) —
        # inicia sessão nela, ligando pelo email verificado.
        catequista_out = await construir_catequista_completo(db, doc)

    token = create_access_token(subject=str(doc["_id"]))
    return Token(access_token=token, catequista=catequista_out)


@router.get("/eu", response_model=CatequistaOut)
async def eu(
    db: AsyncIOMotorDatabase = Depends(get_database),
    catequista: CatequistaOut = Depends(get_current_catequista),
):
    doc = await db.catequistas.find_one({"_id": ObjectId(catequista.id)})
    return await construir_catequista_completo(db, doc)


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
    return await construir_catequista_completo(db, doc)


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
@limiter.limit("3/minute")
async def esqueci_senha(
    request: Request,
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
            logging.exception("Falha ao enviar email de recuperação de senha")
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Não foi possível enviar o email. Contacta o administrador.",
            )

    # Resposta genérica sempre — não revela se o email existe ou não na base de dados
    return {"mensagem": "Se o email existir, foi enviado um código de confirmação."}


@router.post("/redefinir-senha", status_code=status.HTTP_204_NO_CONTENT)
@limiter.limit("6/minute")
async def redefinir_senha(
    request: Request,
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