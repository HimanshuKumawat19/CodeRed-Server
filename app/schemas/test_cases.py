from pydantic import BaseModel, Field
from typing import Optional,List,Any

# for SINGLE test case inside JSON
class TestCaseItem(BaseModel):
    input: str
    output: str
    hidden: bool = False

# creating/updating the database
class TestCasesCreate(BaseModel):
    problem_id: int
    test_cases: List[TestCaseItem]

class TestCasesUpdate(BaseModel):
    test_cases: Optional[List[TestCaseItem]] = None

# for frontend response
class TestCasePublic(BaseModel):
    input: str
    output: str

class TestCasesSampleResponse(BaseModel):
    input: str
    output: str

    class Config:
        from_attributes = True