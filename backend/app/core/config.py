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

    # Autenticação
    # SEM valor por omissão de propósito, tal como o MONGODB_URI acima —
    # um segredo previsível ("change-me-in-production") permitiria a
    # qualquer pessoa forjar tokens válidos (incluindo de administrador)
    # se a variável de ambiente não fosse definida em produção por engano.
    JWT_SECRET: str
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRE_MINUTES: int = 60 * 12  # 12 horas

    # CORS - lista de origens permitidas, separadas por vírgula
    # Ex: "https://catequese-app-sa.web.app,http://localhost:5000"
    # SEM "*" por omissão — define sempre as origens exatas em produção.
    CORS_ORIGINS: str = "https://catequese-app-sa.web.app"

    # Email (recuperação de palavra-passe). Vazio = funcionalidade desativada
    # de forma controlada (dá erro claro em vez de tentar ligar a lado nenhum).
    SMTP_HOST: str = "smtp.gmail.com"
    SMTP_PORT: int = 587
    SMTP_USER: str = ""
    SMTP_PASSWORD: str = ""

    # Iniciar sessão com Google (Web). Vazio = funcionalidade desativada de
    # forma controlada. É o "Client ID" do OAuth 2.0 Client (tipo "Web
    # application") criado no Google Cloud Console — não é segredo, é
    # normal aparecer também no frontend.
    GOOGLE_CLIENT_ID: str = ""

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    @property
    def cors_origins_list(self) -> list[str]:
        if self.CORS_ORIGINS.strip() == "*":
            return ["*"]
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
