import os
import sys
import warnings
import json
import shutil
import uuid
import asyncio
import re
from urllib.parse import unquote
from datetime import datetime
from typing import List, Optional

# FastAPI 관련 모듈
from fastapi import (
    FastAPI,
    Depends,
    HTTPException,
    status,
    APIRouter,
    WebSocket,
    WebSocketDisconnect,
    Header,
    BackgroundTasks,
    File,
    UploadFile,
    Form,
    Request,
    Body,
)
from fastapi.responses import JSONResponse, FileResponse
from fastapi.middleware.cors import CORSMiddleware

# Pydantic (데이터 유효성 검사)
from pydantic import BaseModel, EmailStr

# SQLAlchemy (데이터베이스 ORM)
from sqlalchemy import create_engine, Column, Integer, String, Text, ForeignKeyConstraint
from sqlalchemy.orm import Session, sessionmaker, declarative_base

# 비밀번호 암호화
from passlib.context import CryptContext

# 환경 변수 관리
from dotenv import load_dotenv

# 외부 서비스 연동 (주석 처리된 부분 포함)
import requests
import openai
from azure.cognitiveservices.speech import AudioConfig, SpeechConfig, SpeechRecognizer, ResultReason
import azure.cognitiveservices.speech as speechsdk
from fpdf import FPDF

# 프로젝트 내부 모듈
from api import meetings
from api.websockets import manager as notification_manager
from api.websockets import router as websockets_router

# --- 환경 변수 로드 ---
# .env 파일에서 필요한 값들을 불러옵니다.
load_dotenv()

# 환경 변수들을 가져옵니다.
SPEECH_KEY = os.getenv("SPEECH_KEY")
REGION = os.getenv("REGION")
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
CLOVA_SECRET = os.getenv("CLOVA_SECRET")
CLOVA_INVOKE_URL = os.getenv("CLOVA_INVOKE_URL")
DB_URL = os.getenv("DB_URL")

# --- FastAPI 앱 및 라우터 설정 ---
app = FastAPI()

router = APIRouter(prefix="/api", tags=["Users API"])

app.include_router(meetings.router, prefix="/api", tags=["Meetings API"])
app.include_router(websockets_router)


# 모든 출처(CORS)에서 요청을 허용하도록 설정합니다.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- 데이터베이스 설정 ---
engine = create_engine(DB_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base() # 데이터베이스 테이블의 '설계도' 역할을 합니다.

def get_db():
    """FastAPI가 요청을 처리할 때마다 데이터베이스에 연결하고, 끝나면 연결을 자동으로 끊어줍니다."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# --- 비밀번호 보안 설정 ---
# 사용자의 비밀번호를 안전하게 저장하고 검증하기 위한 설정입니다.
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

def get_password_hash(password: str) -> str:
    """비밀번호를 암호화하는 함수입니다."""
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """사용자가 입력한 비밀번호와 저장된 암호화된 비밀번호가 일치하는지 확인하는 함수입니다."""
    return pwd_context.verify(plain_password, hashed_password)

# --- 데이터베이스 모델 (테이블 설계도) ---
class User(Base):
    """'users'라는 이름의 데이터베이스 테이블을 어떻게 만들지 정의합니다."""
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True)
    email = Column(String(255), unique=True, index=True)
    hashed_password = Column(String(255))

class Group(Base):
    __tablename__ = "groups"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), unique=True, index=True)
    description = Column(Text)

class UserGroup(Base):
    __tablename__ = "user_groups"
    user_id = Column(Integer, primary_key=True)
    group_id = Column(Integer, primary_key=True)
    __table_args__ = (
        ForeignKeyConstraint(['user_id'], ['users.id']),
        ForeignKeyConstraint(['group_id'], ['groups.id']),
    )

# --- Pydantic 스키마 (데이터 유효성 검사) ---
class UserCreate(BaseModel):
    username: str
    password: str
    email: EmailStr

class UserLogin(BaseModel):
    username: str
    password: str

class UserInDB(BaseModel):
    id: int
    username: str
    email: EmailStr
    hashed_password: str
    class Config:
        from_attributes = True

class GroupCreate(BaseModel):
    name: str
    description: Optional[str] = None
    username: str

class UserGroupCreate(BaseModel):
    username: str
    group_name: str

# --- CRUD (Create, Read, Update, Delete) 로직 ---
# 데이터베이스와 상호작용하는 모든 함수를 이 부분에 모아둡니다.
def get_user_by_username(db: Session, username: str):
    return db.query(User).filter(User.username == username).first()

def create_user(db: Session, user: UserCreate):
    hashed_password = get_password_hash(user.password)
    db_user = User(
        username=user.username,
        email=user.email,
        hashed_password=hashed_password
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def get_group_by_name(db: Session, name: str):
    return db.query(Group).filter(Group.name == name).first()

def create_group(db: Session, group_data: GroupCreate):
    db_group = Group(name=group_data.name, description=group_data.description)
    db.add(db_group)
    db.commit()
    db.refresh(db_group)
    return db_group

def get_user_groups_by_username(db: Session, username: str):
    """사용자 이름으로 해당 사용자가 속한 모든 그룹을 조회합니다."""
    user = db.query(User).filter(User.username == username).first()
    if not user:
        return []
    
    user_groups = (
        db.query(Group)
        .join(UserGroup, UserGroup.group_id == Group.id)
        .filter(UserGroup.user_id == user.id)
        .all()
    )
    return user_groups

def delete_group_by_id(db: Session, group_id: int):
    """그룹 ID로 그룹을 삭제합니다. (user_groups 테이블의 연결도 같이 삭제됩니다 - ON DELETE CASCADE)"""
    db_group = db.query(Group).filter(Group.id == group_id).first()
    if db_group:
        db.delete(db_group)
        db.commit()
        return True
    return False

# --- API 엔드포인트 ---
# 실제 사용자가 요청을 보낼 주소와 그 요청을 처리할 함수를 연결합니다.
# 모든 @router로 시작하는 함수들을 이 부분에 모아둡니다.

@router.post("/signup", response_model=UserInDB)
async def create_user_route(user: UserCreate, db: Session = Depends(get_db)):
    """회원가입을 처리하는 API입니다. 사용자 이름이 이미 존재하면 에러를 반환합니다."""
    db_user = get_user_by_username(db, username=user.username)
    if db_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="이미 존재하는 아이디입니다."
        )
    return create_user(db=db, user=user)

@router.post("/login")
async def login_route(user_data: UserLogin, db: Session = Depends(get_db)):
    """로그인을 처리하는 API입니다. 아이디와 비밀번호가 맞지 않으면 에러를 반환합니다."""
    user = get_user_by_username(db, username=user_data.username)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="아이디 또는 비밀번호가 틀립니다."
        )
    if not verify_password(user_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="아이디 또는 비밀번호가 틀립니다."
        )
    return {
        "message": "로그인 성공!",
        "username": user.username,
        "email": user.email
    }

@router.post("/groups")
async def create_group_route(group_data: GroupCreate, db: Session = Depends(get_db)):
    """새로운 그룹을 생성하고, 생성한 사용자를 해당 그룹에 자동으로 추가합니다."""
    db_group = get_group_by_name(db, name=group_data.name)
    if db_group:
        raise HTTPException(status_code=400, detail="Group already exists")
    
    new_group = create_group(db=db, group_data=group_data)
    user = get_user_by_username(db, username=group_data.username)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    db_user_group = UserGroup(user_id=user.id, group_id=new_group.id)
    db.add(db_user_group)
    db.commit()
    
    return {"message": "그룹이 성공적으로 생성되었고, 사용자가 그룹에 추가되었습니다.", "group_id": new_group.id}

@router.get("/user-groups/{username}")
async def get_user_groups_route(username: str, db: Session = Depends(get_db)):
    """특정 사용자가 속한 모든 그룹 목록을 반환합니다."""
    groups = get_user_groups_by_username(db, username)
    return [{"id": g.id, "name": g.name, "description": g.description} for g in groups]

@router.delete("/groups/{group_id}")
async def delete_group_route(group_id: int, db: Session = Depends(get_db)):
    """특정 그룹을 삭제합니다."""
    success = delete_group_by_id(db, group_id)
    if not success:
        raise HTTPException(status_code=404, detail="Group not found")
    return {"message": "Group deleted successfully"}

# --- WebSocket & Background Tasks ---
@app.post("/api/notifications/pdf-complete")
async def send_pdf_complete_notification():
    """PDF 생성 완료 알림을 웹소켓으로 보냅니다."""
    message = json.dumps({"type": "pdf_complete"})
    await notification_manager.broadcast(message)
    return {"message": "Notification sent"}

app.include_router(router)

@app.websocket("/ws/notifications")
async def notifications_ws(websocket: WebSocket):
    """클라이언트와 웹소켓 연결을 설정합니다."""
    await notification_manager.connect(websocket)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        notification_manager.disconnect(websocket)