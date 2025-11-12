from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

# For creating a new test case (Admin)
class TestCasesCreate(BaseModel):
    problem_id: int
    input_data: str
    expected_output: str
    is_hidden: bool = Field(False, description="False=Sample (visible), True=Hidden (for judging)")

# For updating a test case (Admin)
class TestCasesUpdate(BaseModel):
    input_data: Optional[str] = None
    expected_output: Optional[str] = None
    is_hidden: Optional[bool] = None
    
# It correctly includes expected_output
class TestCasesSampleResponse(BaseModel):
    test_cases_id: int
    input_data: str
    expected_output: str

    class Config:
        from_attributes = True