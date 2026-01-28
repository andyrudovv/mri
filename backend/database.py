from sqlalchemy import create_engine, event, text
from sqlalchemy.orm import declarative_base, sessionmaker
from sqlalchemy.pool import StaticPool
import os
from dotenv import load_dotenv
import time

load_dotenv()

# Database URL - Using PostgreSQL
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres:password@localhost:5432/mri_db"
)

# Retry logic for database connection
max_retries = 5
retry_count = 0
engine = None

while retry_count < max_retries:
    try:
        # Create engine
        engine = create_engine(
            DATABASE_URL,
            echo=False,
            pool_pre_ping=True,
            connect_args={
                "connect_timeout": 10,
                "options": "-c statement_timeout=30000"
            }
        )
        
        # Test connection
        with engine.connect() as conn:
            conn.execute(text("SELECT 1"))
        
        print("✓ Database connection successful")
        break
        
    except Exception as e:
        retry_count += 1
        if retry_count < max_retries:
            print(f"Database connection attempt {retry_count} failed: {str(e)}")
            print(f"Retrying in 2 seconds...")
            time.sleep(2)
        else:
            print(f"Failed to connect to database after {max_retries} attempts")
            raise e

# Session factory
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base class for models
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
