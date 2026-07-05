from datetime import datetime

from pydantic import BaseModel, EmailStr, Field, ConfigDict


class CatequistaCreate(BaseModel):
    nome: str = Field(..., min_length=2, max_length=120)
    email: EmailStr
    password: str = Field(..., min_length=6, max_length=72)


class CatequistaOut(BaseModel):
    id: str
    nome: str
    email: EmailStr
    is_admin: bool = False
    criado_em: datetime

    model_config = ConfigDict(from_attributes=True)


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    catequista: CatequistaOut
