from sqlalchemy import Column,Integer,String,TEXT,Float,DateTime,Boolean,ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base

class TestCases(Base):
    __tablename__ = "test_cases"

    test_cases_id = Column(Integer,primary_key=True,index=True)
    problem_id = Column(Integer,ForeignKey("problems.problem_id"),nullable=False)
    input_data = Column(TEXT,nullable=False)
    expected_output = Column(TEXT,nullable=False)
    is_hidden = Column(Boolean,nullable=False,default=False,comment="False=Sample (visible), True=Hidden (for judging)")

    problem = relationship("Problems",back_populates = "test_cases")
    created_at = Column(DateTime(timezone=True),server_default=func.now())
    updated_at = Column(DateTime(timezone=True),server_default=func.now())