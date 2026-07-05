from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from motor.motor_asyncio import AsyncIOMotorDatabase
from pymongo.errors import DuplicateKeyError

from app.core.database import get_database
from app.core.deps import get_current_catequista
from app.core.security import create_access_token, hash_password, verify_password
from app.models.catequista import CatequistaCreate, CatequistaOut, Token

router = APIRouter(prefix="/auth", tags=["autenticação"])


@router.post("/registar", response_model=CatequistaOut, status_code=status.HTTP_201_CREATED)
async def registar(dados: CatequistaCreate, db: AsyncIOMotorDatabase = Depends(get_database)):
    # O primeiro catequista a registar-se numa base de dados nova torna-se
    # administrador automaticamente (bootstrap). Os seguintes ficam sem
    # permissões de admin até serem promovidos por um administrador existente.
    ja_existem = await db.catequistas.count_documents({})
    is_admin = ja_existem == 0

    doc = {
        "nome": dados.nome.strip(),
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
        is_admin=doc.get("is_admin", False),
        criado_em=doc["criado_em"],
    )
    token = create_access_token(subject=str(doc["_id"]))
    return Token(access_token=token, catequista=catequista_out)


@router.get("/eu", response_model=CatequistaOut)
async def eu(catequista: CatequistaOut = Depends(get_current_catequista)):
    return catequista
