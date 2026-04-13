from sqlalchemy import and_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import hash_password
from app.models.models import Question, User


MOCK_JEE_PYQS = [
    {
        "exam": "JEE_MAIN",
        "subject": "Physics",
        "topic": "Electrostatics",
        "year": 2024,
        "difficulty": 3,
        "question": "A point charge q is placed at the center of a conducting spherical shell. The electric field inside the shell material is:",
        "options": {"A": "Zero", "B": "q/4pi e0 r^2", "C": "Infinity", "D": "Depends on shell radius"},
        "correct_answer": "A",
        "explanation": "In electrostatic equilibrium, electric field inside the conducting material is zero.",
        "weightage": 1.2,
    },
    {
        "exam": "JEE_MAIN",
        "subject": "Chemistry",
        "topic": "Chemical Bonding",
        "year": 2023,
        "difficulty": 2,
        "question": "Which molecule has the maximum bond angle?",
        "options": {"A": "NH3", "B": "H2O", "C": "CH4", "D": "CO2"},
        "correct_answer": "D",
        "explanation": "CO2 is linear with bond angle 180 degrees, maximum among options.",
        "weightage": 1.1,
    },
    {
        "exam": "JEE_MAIN",
        "subject": "Mathematics",
        "topic": "Definite Integration",
        "year": 2022,
        "difficulty": 3,
        "question": "Integral from 0 to pi of sin(x) dx equals:",
        "options": {"A": "0", "B": "1", "C": "2", "D": "pi"},
        "correct_answer": "C",
        "explanation": "Integral of sin(x) from 0 to pi is [-cos(x)]0..pi = 2.",
        "weightage": 1.0,
    },
    {
        "exam": "JEE_MAIN",
        "subject": "Physics",
        "topic": "Current Electricity",
        "year": 2021,
        "difficulty": 2,
        "question": "Equivalent resistance of two 6 ohm resistors in parallel is:",
        "options": {"A": "12 ohm", "B": "6 ohm", "C": "3 ohm", "D": "1.5 ohm"},
        "correct_answer": "C",
        "explanation": "For equal resistors in parallel, Req = R/2 = 3 ohm.",
        "weightage": 0.9,
    },
    {
        "exam": "JEE_MAIN",
        "subject": "Chemistry",
        "topic": "Thermodynamics",
        "year": 2020,
        "difficulty": 3,
        "question": "For an adiabatic process, which quantity remains constant?",
        "options": {"A": "Temperature", "B": "Pressure", "C": "Heat exchange", "D": "Volume"},
        "correct_answer": "C",
        "explanation": "Adiabatic process has no heat exchange with surroundings (Q = 0).",
        "weightage": 1.0,
    },
    {
        "exam": "JEE_ADVANCED",
        "subject": "Physics",
        "topic": "Rotational Mechanics",
        "year": 2024,
        "difficulty": 5,
        "question": "A rigid body rotates with angular acceleration alpha. Torque tau is related to moment of inertia I by:",
        "options": {"A": "tau = I/alpha", "B": "tau = I alpha", "C": "tau = alpha/I", "D": "tau = I alpha^2"},
        "correct_answer": "B",
        "explanation": "Rotational analog of Newton's second law: tau = I alpha.",
        "weightage": 1.5,
    },
    {
        "exam": "JEE_ADVANCED",
        "subject": "Mathematics",
        "topic": "Vectors and 3D",
        "year": 2023,
        "difficulty": 4,
        "question": "If a.b = 0 and |a| = |b| = 1, then |a + b| is:",
        "options": {"A": "0", "B": "1", "C": "sqrt(2)", "D": "2"},
        "correct_answer": "C",
        "explanation": "|a+b|^2 = |a|^2 + |b|^2 + 2a.b = 2.",
        "weightage": 1.3,
    },
    {
        "exam": "JEE_ADVANCED",
        "subject": "Chemistry",
        "topic": "Organic Reactions",
        "year": 2022,
        "difficulty": 4,
        "question": "The major product of hydration of propene in acidic medium is:",
        "options": {"A": "1-propanol", "B": "2-propanol", "C": "propanal", "D": "propanoic acid"},
        "correct_answer": "B",
        "explanation": "Markovnikov addition gives 2-propanol as major product.",
        "weightage": 1.2,
    },
    {
        "exam": "JEE_ADVANCED",
        "subject": "Physics",
        "topic": "Modern Physics",
        "year": 2021,
        "difficulty": 4,
        "question": "In photoelectric effect, stopping potential depends on:",
        "options": {"A": "Intensity only", "B": "Frequency only", "C": "Both intensity and frequency", "D": "Work function only"},
        "correct_answer": "B",
        "explanation": "Stopping potential depends on maximum kinetic energy, hence frequency.",
        "weightage": 1.4,
    },
    {
        "exam": "JEE_ADVANCED",
        "subject": "Mathematics",
        "topic": "Differential Equations",
        "year": 2020,
        "difficulty": 5,
        "question": "General solution of dy/dx = y is:",
        "options": {"A": "y = x + C", "B": "y = Ce^x", "C": "y = Cx", "D": "y = e^(Cx)"},
        "correct_answer": "B",
        "explanation": "Separating variables gives ln y = x + c => y = Ce^x.",
        "weightage": 1.2,
    },
]

MOCK_PLATFORM_PYQS = MOCK_JEE_PYQS + [
    {
        "exam": "UPSC",
        "subject": "Polity",
        "topic": "Fundamental Rights",
        "year": 2022,
        "difficulty": 2,
        "question": "Which Article of the Indian Constitution guarantees equality before law?",
        "options": {"A": "Article 14", "B": "Article 19", "C": "Article 21", "D": "Article 32"},
        "correct_answer": "A",
        "explanation": "Article 14 provides equality before law and equal protection of laws.",
        "weightage": 1.0,
    },
    {
        "exam": "NEET",
        "subject": "Biology",
        "topic": "Cell Biology",
        "year": 2021,
        "difficulty": 2,
        "question": "Powerhouse of the cell is:",
        "options": {"A": "Nucleus", "B": "Ribosome", "C": "Mitochondria", "D": "Golgi body"},
        "correct_answer": "C",
        "explanation": "Mitochondria are known as powerhouse due to ATP production.",
        "weightage": 1.0,
    },
    {
        "exam": "NDA",
        "subject": "General Science",
        "topic": "Motion",
        "year": 2020,
        "difficulty": 1,
        "question": "Unit of acceleration is:",
        "options": {"A": "m/s", "B": "m/s^2", "C": "N", "D": "kg m/s"},
        "correct_answer": "B",
        "explanation": "Acceleration is rate of change of velocity, so unit is m/s^2.",
        "weightage": 0.8,
    },
    {
        "exam": "SSC",
        "subject": "Quantitative Aptitude",
        "topic": "Percentages",
        "year": 2022,
        "difficulty": 2,
        "question": "What is 20% of 250?",
        "options": {"A": "25", "B": "40", "C": "50", "D": "60"},
        "correct_answer": "C",
        "explanation": "20/100 * 250 = 50.",
        "weightage": 0.9,
    },
]


async def _seed_questions(session: AsyncSession, questions: list[dict]) -> dict[str, int]:
    inserted = 0
    skipped = 0
    for item in questions:
        existing = await session.scalar(
            select(Question).where(
                and_(
                    Question.exam == item["exam"],
                    Question.subject == item["subject"],
                    Question.topic == item["topic"],
                    Question.year == item["year"],
                    Question.question == item["question"],
                )
            )
        )
        if existing:
            skipped += 1
            continue
        session.add(Question(**item))
        inserted += 1

    await session.commit()
    return {"inserted": inserted, "skipped": skipped, "total": len(questions)}


async def seed_mock_jee_questions(session: AsyncSession) -> dict[str, int]:
    return await _seed_questions(session, MOCK_JEE_PYQS)


async def seed_platform_questions(session: AsyncSession) -> dict[str, int]:
    return await _seed_questions(session, MOCK_PLATFORM_PYQS)


async def seed_test_users(session: AsyncSession) -> dict[str, int]:
    """Seed test users for development"""
    # Clear existing test users first
    from sqlalchemy import delete
    await session.execute(delete(User).where(User.email.in_([
        "admin@admin.com",
        "premium@test.com", 
        "user@test.com"
    ])))
    
    test_users = [
        {"email": "admin@admin.com", "password": "admin@123", "is_admin": True, "is_premium": True},
        {"email": "premium@test.com", "password": "premium@123", "is_admin": False, "is_premium": True},
        {"email": "user@test.com", "password": "user@test123", "is_admin": False, "is_premium": False},
    ]
    
    inserted = 0
    
    for user_data in test_users:
        user = User(
            email=user_data["email"],
            password_hash=hash_password(user_data["password"]),
            is_admin=user_data["is_admin"],
            is_premium=user_data["is_premium"],
        )
        session.add(user)
        inserted += 1
    
    await session.commit()
    return {"inserted": inserted, "total": len(test_users)}
