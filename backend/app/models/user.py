from sqlalchemy import Column, Integer, String, Boolean, DateTime
from sqlalchemy.sql import func

from .base import BaseModel

class User(BaseModel):
    __tablename__ = "users"
    
    email = Column(String(255), unique=True, index=True, nullable=False)
    username = Column(String(50), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(100), nullable=True)
    is_active = Column(Boolean, default=True)
    is_superuser = Column(Boolean, default=False)
    last_login = Column(DateTime, nullable=True)
    
    # Relationships
    graphs = relationship("ThoughtGraph", back_populates="owner")
    
    def __repr__(self):
        return f"<User {self.username}>"
    
    @property
    def is_authenticated(self) -> bool:
        return self.is_active
    
    @property
    def display_name(self) -> str:
        return self.full_name or self.username
