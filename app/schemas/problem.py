from pydantic import BaseModel,Field
from typing import Optional,List
from datetime import datetime
from .test_cases import TestCasesSampleResponse

# class for creating or reading
class ProblemBase(BaseModel):
    title : str
    description : str
    difficulty_level : str
    topic_id : Optional[int] = None
    time_limit : int
    memory_limit : int
    points : int

class ProblemCreate(ProblemBase):
    pass

# Update scehma - Inherit from the base class but all the fields are optional
class ProblemUpdate(BaseModel):
    title : Optional[str] = None
    description : Optional[str] = None
    difficulty_level : Optional[str] = None
    topic_id : Optional[int] = None
    time_limit : Optional[int] = None
    memory_limit : Optional[int] = None
    points : Optional[int] = None

# Response schema - add the fields into DB
class ProblemResponse(BaseModel):
    problem_id : int
    acceptance_rate : float
    total_submission : int
    successfull_submission : int
    is_active : bool
    created_at : datetime
    updated_at : datetime
    #contain a list of test cases
    sample_test_cases: List[TestCasesSampleResponse] = []
    class Config:
        from_attributes=True