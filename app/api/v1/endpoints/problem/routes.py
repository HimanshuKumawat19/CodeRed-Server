from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.services import problem_service
from app.schemas.problem import ProblemResponse
from app.database import get_db

router = APIRouter()

# API for random problems
@router.get(
    "/problems/random",
    response_model=ProblemResponse,
    summary="Get a random problem by difficulty"
)

async def get_random_problem(
    difficulty:str,
    db: Session = Depends(get_db)
):
    # Fetching problems on the basis of "easy","medium","hard"
    problem = await problem_service.get_random_problem_by_difficulty(db,difficulty.title())

    if not problem:
        raise HTTPException(
            status_code=404,
            detail=f"No active problem found with difficulty: {difficulty}"
        )
    
    return problem


# API for particular problem
@router.get(
    "/problems/{problem_id}",
    response_model=ProblemResponse,
    summary="Get a single problem by its ID"
)


async def get_problem(problem_id: int, db:Session = Depends(get_db)):
    problem = await problem_service.get_problem_by_id(db,problem_id)
    if not problem:
        raise HTTPException(status_code=404,details="Problem not found")

    return problem

