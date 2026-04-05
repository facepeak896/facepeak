# Backend/database.py

from sqlalchemy.ext.asyncio import (
    create_async_engine,
    AsyncSession,
)
from sqlalchemy.orm import sessionmaker, declarative_base
import os
from dotenv import load_dotenv

# ======================
# LOAD ENV
# ======================
load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL")

if not DATABASE_URL:
    raise ValueError("DATABASE_URL nije postavljen")

# ======================
# BASE (MODELS)
# ======================
Base = declarative_base()

# ======================
# ENGINE (ASYNC)
# ======================
engine = create_async_engine(
    DATABASE_URL,
    echo=False,
    pool_pre_ping=True,
)

# ======================
# SESSION (ASYNC)
# ======================
AsyncSessionLocal = sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
)

# ======================
# DEPENDENCY (🔥 BITNO)
# ======================
async def get_db():
    async with AsyncSessionLocal() as session:
        yield session