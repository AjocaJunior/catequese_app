from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import get_settings
from app.core.database import connect_to_mongo, close_mongo_connection, ensure_indexes
from app.routers import health, auth, fases, catequisandos, catequistas, presencas, retiros, eventos, sectores, publico, ministerios, fotos, caixa, inventario, configuracao, pautas, auditoria

settings = get_settings()


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Executado no arranque
    await connect_to_mongo()
    await ensure_indexes()
    yield
    # Executado no encerramento
    await close_mongo_connection()


app = FastAPI(title=settings.APP_NAME, lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router)
app.include_router(auth.router)
app.include_router(fases.router)
app.include_router(catequisandos.router)
app.include_router(catequistas.router)
app.include_router(presencas.router)
app.include_router(retiros.router)
app.include_router(eventos.router)
app.include_router(sectores.router)
app.include_router(ministerios.router)
app.include_router(fotos.router)
app.include_router(caixa.router)
app.include_router(inventario.router)
app.include_router(configuracao.router)
app.include_router(pautas.router)
app.include_router(auditoria.router)
app.include_router(publico.router)


@app.get("/")
async def root():
    return {"message": f"{settings.APP_NAME} está no ar."}
