from bson import ObjectId
from bson.errors import InvalidId
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.database import get_database
from app.core.security import decode_access_token
from app.models.catequista import CatequistaOut

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


async def get_current_catequista(
    token: str = Depends(oauth2_scheme),
    db: AsyncIOMotorDatabase = Depends(get_database),
) -> CatequistaOut:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Credenciais inválidas ou sessão expirada",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = decode_access_token(token)
        user_id = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    try:
        doc = await db.catequistas.find_one({"_id": ObjectId(user_id)})
    except InvalidId:
        raise credentials_exception

    if doc is None:
        raise credentials_exception

    return CatequistaOut(
        id=str(doc["_id"]),
        nome=doc["nome"],
        email=doc["email"],
        is_admin=doc.get("is_admin", False),
        criado_em=doc["criado_em"],
    )


async def get_current_admin(catequista: CatequistaOut = Depends(get_current_catequista)) -> CatequistaOut:
    """Dependency adicional: exige que o catequista autenticado seja administrador."""
    if not catequista.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Apenas administradores podem realizar esta ação",
        )
    return catequista
