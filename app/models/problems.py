from sqlalchemy import Column,Integer,String,TEXT,Float,DateTime,Boolean,ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database import Base

class Problems(Base):
    __tablename__ = "problems"

    problem_id = Column(Integer,primary_key=True,index=True)
    title = Column(String,nullable=False)
    description = Column(TEXT,nullable=False)
    difficulty_level = Column(String,nullable=False)
    topic_id = Column(Integer,nullable=False)
    time_limit = Column(Integer,nullable=False,default=100)
    memory_limit = Column(Integer,nullable=False,default=1000)
    points = Column(Integer,nullable=False,default=0)
    acceptance_rate = Column(Float,default=0,nullable=False)
    total_submission = Column(Integer,default=0,nullable=False)
    successfull_submission = Column(Integer,default=0,nullable=False)
    is_active = Column(Boolean,default=True,nullable=False)
    test_cases = relationship("TestCases",back_populates="problem",cascade="all, delete-orphan")
    created_at = Column(DateTime(timezone=True),server_default=func.now())
    updated_at = Column(DateTime(timezone=True),server_default=func.now())