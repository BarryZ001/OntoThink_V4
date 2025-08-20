from pydantic_settings import BaseSettings
from typing import List, Optional

class Settings(BaseSettings):
    # API settings
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "OntoThink"
    
    # CORS settings
    CORS_ORIGINS: List[str] = ["http://localhost:3000", "http://localhost:8000"]
    
    # Database settings
    POSTGRES_SERVER: str = "localhost"
    POSTGRES_USER: str = "postgres"
    POSTGRES_PASSWORD: str = "postgres"
    POSTGRES_DB: str = "ontothink"
    DATABASE_URL: Optional[str] = None
    
    # Security
    SECRET_KEY: str = "your-secret-key-here"  # Change this in production
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 8  # 8 days
    
    # Model settings
    DEEPSEEK_API_KEY: Optional[str] = None
    
    class Config:
        case_sensitive = True
        env_file = ".env"

# Initialize settings
settings = Settings()

# Set database URL if not set
if not settings.DATABASE_URL:
    settings.DATABASE_URL = f"postgresql://{settings.POSTGRES_USER}:{settings.POSTGRES_PASSWORD}@{settings.POSTGRES_SERVER}/{settings.POSTGRES_DB}"
