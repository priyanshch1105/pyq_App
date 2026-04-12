import asyncio
from sqlalchemy import text
from app.db.session import engine
from app.models.models import Base

async def fix_db():
    async with engine.begin() as conn:
        try:
            print("Adding is_premium to users table...")
            await conn.execute(text("ALTER TABLE users ADD COLUMN is_premium BOOLEAN DEFAULT FALSE NOT NULL;"))
            print("Successfully added is_premium column!")
        except Exception as e:
            print(f"Column might already exist or failed: {e}")

        try:
            print("Adding is_admin to users table...")
            await conn.execute(text("ALTER TABLE users ADD COLUMN is_admin BOOLEAN DEFAULT FALSE NOT NULL;"))
            print("Successfully added is_admin column!")
        except Exception as e:
            print(f"Column might already exist or failed: {e}")
        
        print("Ensuring all new tables (like announcements) are created...")
        await conn.run_sync(Base.metadata.create_all)
        print("Database schema successfully patched!")

if __name__ == "__main__":
    asyncio.run(fix_db())
