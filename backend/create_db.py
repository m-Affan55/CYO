import asyncio
import asyncpg
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

async def create_database():
    user = "postgres"
    password = "123Abc"
    host = "localhost"
    port = "5432"
    target_db = "cyo_db"

    # Connect to the default 'postgres' database to create the new database
    try:
        conn = await asyncpg.connect(
            user=user, 
            password=password, 
            host=host, 
            port=port, 
            database="postgres"
        )
        logger.info("Connected to default postgres database successfully.")
        
        # Check if target database exists
        exists = await conn.fetchval(f"SELECT 1 FROM pg_database WHERE datname = '{target_db}'")
        
        if not exists:
            logger.info(f"Database '{target_db}' does not exist. Creating...")
            # create database cannot be run inside a transaction block
            await conn.execute(f'CREATE DATABASE "{target_db}"')
            logger.info(f"Database '{target_db}' created successfully.")
        else:
            logger.info(f"Database '{target_db}' already exists.")
            
        await conn.close()
    except Exception as e:
        logger.error(f"Failed to create database '{target_db}': {e}")

if __name__ == "__main__":
    asyncio.run(create_database())
