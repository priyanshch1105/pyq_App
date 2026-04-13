import os

from pydantic import field_validator
from pydantic_settings import BaseSettings, PydanticBaseSettingsSource, SettingsConfigDict


class Settings(BaseSettings):
    app_name: str = "PYQ Platform API"
    secret_key: str = "change-this-in-production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24
    database_url: str = "postgresql+asyncpg://postgres:2005@localhost:5432/pyq_db"
    free_question_limit: int = 25
    admin_seed_key: str = "seed-dev-key"

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    @field_validator("database_url", mode="before")
    @classmethod
    def normalize_database_url(cls, value: str) -> str:
        database_url = value.strip()

        if database_url.startswith("postgres://"):
            database_url = database_url.replace("postgres://", "postgresql+asyncpg://", 1)
        elif database_url.startswith("postgresql://"):
            database_url = database_url.replace("postgresql://", "postgresql+asyncpg://", 1)

        # On Render, localhost points to the app container itself, not Postgres.
        if os.getenv("RENDER") and "@localhost:" in database_url:
            raise ValueError("Invalid DATABASE_URL for Render: localhost is not reachable. Use Render Postgres internal DATABASE_URL.")

        return database_url

    @classmethod
    def settings_customise_sources(
        cls,
        settings_cls: type[BaseSettings],
        init_settings: PydanticBaseSettingsSource,
        env_settings: PydanticBaseSettingsSource,
        dotenv_settings: PydanticBaseSettingsSource,
        file_secret_settings: PydanticBaseSettingsSource,
    ) -> tuple[PydanticBaseSettingsSource, ...]:
        # Ignore checked-in .env on Render and rely on service environment variables.
        if os.getenv("RENDER"):
            return (init_settings, env_settings, file_secret_settings)

        return (init_settings, env_settings, dotenv_settings, file_secret_settings)


settings = Settings()
