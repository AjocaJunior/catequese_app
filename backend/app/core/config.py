"""
Configurações da aplicação, lidas a partir de variáveis de ambiente.
Em produção (Render), estas variáveis são definidas no painel do serviço.
Em desenvolvimento local, podem ser definidas num ficheiro .env (ver .env.example).
"""
from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    # Aplicação
    APP_NAME: str = "Catequese API"
    ENVIRONMENT: str = "development"  # development | production

    # MongoDB
    MONGODB_URI: str = "mongodb://localhost:27017"
    DB_NAME: str = "catequese"

    # Autenticação (usado a partir do Módulo 2)
    JWT_SECRET: str = "change-me-in-production"
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRE_MINUTES: int = 60 * 12  # 12 horas

    # CORS - lista de origens permitidas, separadas por vírgula
    # Ex: "https://catequese-app.onrender.com,http://localhost:5000"
    CORS_ORIGINS: str = "*"

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    @property
    def cors_origins_list(self) -> list[str]:
        if self.CORS_ORIGINS.strip() == "*":
            return ["*"]
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
