from datetime import timedelta, datetime
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from .... import models, schemas
from ....core.security import (
    create_access_token,
    get_password_hash,
    verify_password,
    get_current_user,
    get_current_active_user
)
from ....config import settings
from ....db.base import get_db

router = APIRouter()

@router.post("/login", response_model=schemas.Token)
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    """OAuth2 compatible token login, get an access token for future requests"""
    user = db.query(models.User).filter(
        models.User.username == form_data.username
    ).first()
    
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    elif not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user"
        )
    
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": str(user.id)}, expires_delta=access_token_expires
    )
    
    # Update last login time
    user.last_login = datetime.utcnow()
    db.commit()
    
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/register", response_model=schemas.User)
async def register(
    user_in: schemas.RegisterRequest,
    db: Session = Depends(get_db)
):
    """Register a new user"""
    # Check if username already exists
    db_user = db.query(models.User).filter(
        models.User.username == user_in.username
    ).first()
    if db_user:
        raise HTTPException(
            status_code=400,
            detail="Username already registered"
        )
    
    # Check if email already exists
    db_email = db.query(models.User).filter(
        models.User.email == user_in.email
    ).first()
    if db_email:
        raise HTTPException(
            status_code=400,
            detail="Email already registered"
        )
    
    # Check if passwords match
    if user_in.password != user_in.password_confirm:
        raise HTTPException(
            status_code=400,
            detail="Passwords do not match"
        )
    
    # Create new user
    hashed_password = get_password_hash(user_in.password)
    db_user = models.User(
        username=user_in.username,
        email=user_in.email,
        hashed_password=hashed_password,
        full_name=user_in.full_name,
        is_active=True,
        is_superuser=False
    )
    
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    return db_user

@router.get("/me", response_model=schemas.User)
async def read_users_me(current_user: models.User = Depends(get_current_active_user)):
    """Get current user."""
    return current_user

@router.post("/password-reset")
async def password_reset(
    email: str,
    db: Session = Depends(get_db)
):
    """Request password reset"""
    # In a real app, you would send an email with a reset link
    # For now, we'll just return a success message
    return {"message": "If your email is registered, you will receive a password reset link"}

@router.post("/password-reset/confirm")
async def password_reset_confirm(
    token: str,
    new_password: str,
    db: Session = Depends(get_db)
):
    """Confirm password reset"""
    # In a real app, you would validate the token and update the password
    # For now, we'll just return a success message
    return {"message": "Password has been reset successfully"}
