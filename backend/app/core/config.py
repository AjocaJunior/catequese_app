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
    # SEM valor por omissão de propósito: se o .env não for encontrado,
    # o arranque falha imediatamente com um erro claro do Pydantic,
    # em vez de cair silenciosamente para "localhost" e dar um erro de
    # SSL confuso minutos depois.
    MONGODB_URI: str
    DB_NAME: str = "catequese"

    # Autenticação (usado a partir do Módulo 2)
    JWT_SECRET: str = "change-me-in-production"
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRE_MINUTES: int = 60 * 12  # 12 horas

    # CORS - lista de origens permitidas, separadas por vírgula
    # Ex: "https://catequese-app.onrender.com,http://localhost:5000"
    CORS_ORIGINS: str = "*"

    # Email (recuperação de palavra-passe). Vazio = funcionalidade desativada
    # de forma controlada (dá erro claro em vez de tentar ligar a lado nenhum).
    SMTP_HOST: str = "smtp.gmail.com"
    SMTP_PORT: int = 587
    SMTP_USER: str = ""
    SMTP_PASSWORD: str = ""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    @property
    def cors_origins_list(self) -> list[str]:
        if self.CORS_ORIGINS.strip() == "*":
            return ["*"]
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
