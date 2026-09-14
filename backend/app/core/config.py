from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    APP_NAME: str = "Guardian Circle API"
    APP_VERSION: str = "1.0.0"

    DATABASE_URL: str = (
        "postgresql://snehahankare2007@localhost:5432/guardian_circle"
    )

    SECRET_KEY: str = "guardian-circle-development-secret-key"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60

    class Config:
        env_file = ".env"


settings = Settings()