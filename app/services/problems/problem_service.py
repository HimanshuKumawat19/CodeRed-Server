from sqlalchemy.orm import Session
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from app.models.problems import Problems
from app.models.test_cases import TestCases
from sqlalchemy.sql.expression import func

async def get_problem_by_id(db:Session, problem_id: int):
    # using selectinload fetching problem and all its test_cases in one query
    query = (
        select(ProblemBase)
        .where(ProblemBase.problem_id == problem_id)
        .options(selectinload(ProblemBase.test_cases))
    )

    result = await db.execute(query)
    problem = result.scalar_one_or_none()

    if not problem:
        return None
    
    # Manuaally filter the things for ONLY the sample cases
    sample_cases = [
        case for case in problem.test_cases if not case.is_hidden
    ]

    # attach this filtered list to the problem
    # the 'ProblemResponse' schema will read 
    problem.sample_test_cases = sample_cases

    return problem

async def get_random_problem_by_difficulty(db: Session,difficulty:str):
    # Filter by the difficulty
    # - Order by 'random()' to get a random one

    query = (
        select(ProblemBase)
        .where(ProblemBase.difficulty_level == difficulty)
        .where(ProblemBase.is_active == True)
        .order_by(func.random())
        .limit(1)
        .options(selectinload(ProblemBase.test_cases))
    )

    # Execute the query
    result = await db.execute(query)
    problem = result.scalar_one_or_none()

    if not problem:
        return None
    
    # filter only the sample cases
    sample_cases = [
        case for case in problem.test_cases if not case.is_hidden
    ]

    # attach the filtered list to the object
    problem.sample_test_cases = sample_cases
    
    return problem