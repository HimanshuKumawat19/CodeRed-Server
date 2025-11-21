from sqlalchemy import Column,Integer,String,TEXT,DateTime,Boolean,ForeignKey
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base

class TestCases(Base):
    __tablename__ = "test_cases"

    test_cases_id = Column(Integer,primary_key=True,index=True)
    problem_id = Column(Integer,ForeignKey("problems.problem_id"),nullable=False)
    
    test_cases = Column(JSONB, nullable=False)
    problem = relationship("Problems",back_populates = "test_cases")
    created_at = Column(DateTime(timezone=True),server_default=func.now())
    updated_at = Column(DateTime(timezone=True),server_default=func.now())