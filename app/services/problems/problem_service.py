from sqlalchemy.orm import Session
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from app.models.problems import Problems
from sqlalchemy.sql.expression import func

async def get_problem_by_id(db:Session, problem_id: int):
    # using selectinload fetching problem and all its test_cases in one query
    query = (
        select(Problems)
        .where(Problems.problem_id == problem_id)
        .options(selectinload(Problems.test_cases))
    )

    result = await db.execute(query)
    problem = result.scalar_one_or_none()

    if not problem:
        return None
    
    test_cases_row = problem.test_cases[0] if problem.test_cases else None

    sample_cases = []

    if test_cases_row and test_cases_row.test_cases:
        for case in test_cases_row.test_cases:
            if case.get("hidden") is False:
                sample_cases.append({
                    "input": case.get("input"),
                    "output": case.get("output")
                })

    problem.sample_test_cases = sample_cases
    return problem

async def get_random_problem_by_difficulty(db: Session,difficulty:str):

    query = (
        select(Problems)
        .where(Problems.difficulty_level == difficulty)
        .where(Problems.is_active == True)
        .order_by(func.random())
        .limit(1)
        .options(selectinload(Problems.test_cases))
    )

    # Execute the query
    result = await db.execute(query)
    problem = result.scalar_one_or_none()

    if not problem:
        return None
    
    test_cases_row = problem.test_cases[0] if problem.test_cases else None
    sample_cases = []

    if test_cases_row and test_cases_row.test_cases:
        for case in test_cases_row.test_cases:
            if case.get("hidden") is False:
                sample_cases.append({
                    "input": case.get("input"),
                    "output": case.get("output")
                })
    
    problem.sample_test_cases = sample_cases
    
    return problem