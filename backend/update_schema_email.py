import asyncio
import asyncpg
import os
from dotenv import load_dotenv

# Load .env explicitly
load_dotenv()

async def add_email_column():
    print("Connecting to PostgreSQL...")
    db_url = os.getenv("DATABASE_URL")
    if db_url and "postgresql+asyncpg" in db_url:
        db_url = db_url.replace("postgresql+asyncpg", "postgresql")
    
    conn = await asyncpg.connect(db_url)
    
    try:
        # Add the email column
        await conn.execute("ALTER TABLE accounts ADD COLUMN email VARCHAR UNIQUE;")
        print("✅ Successfully added 'email' column to 'accounts' table!")
    except asyncpg.exceptions.DuplicateColumnError:
        print("Column 'email' already exists.")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        await conn.close()

if __name__ == "__main__":
    asyncio.run(add_email_column())
