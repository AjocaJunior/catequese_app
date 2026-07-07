from datetime import datetime
from typing import Optional

from pydantic import BaseModel


class FotoOut(BaseModel):
    id: str
    titulo: Optional[str] = None
    criado_em: datetime
