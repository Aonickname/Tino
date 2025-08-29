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
from typing import List

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
from sqlalchemy import create_engine, Column, Integer, String
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

# --- 데이터베이스 설정 ---
engine = create_engine(DB_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base() # 데이터베이스 테이블의 '설계도' 역할을 합니다.

# 데이터베이스 세션을 가져오는 함수입니다.
# FastAPI가 요청을 처리할 때마다 데이터베이스에 연결하고, 끝나면 연결을 자동으로 끊어줍니다.
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# --- 비밀번호 보안 설정 ---
# 사용자의 비밀번호를 안전하게 저장하고 검증하기 위한 설정입니다.
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# 비밀번호를 암호화하는 함수입니다.
def get_password_hash(password: str) -> str:
    return pwd_context.hash(password)

# 사용자가 입력한 비밀번호와 저장된 암호화된 비밀번호가 일치하는지 확인하는 함수입니다.
def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

# --- 데이터베이스 모델 (테이블 설계도) ---
# 'users'라는 이름의 데이터베이스 테이블을 어떻게 만들지 정의합니다.
class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True)
    email = Column(String(255), unique=True, index=True)
    hashed_password = Column(String(255))

# --- Pydantic 스키마 (데이터 유효성 검사) ---
# API로 들어오는 요청 데이터가 어떤 모양인지 정의합니다.
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
    
    # ORM 모드 설정: 데이터베이스 객체를 Pydantic 모델로 변환할 수 있게 해줍니다.
    class Config:
        from_attributes = True

# --- CRUD (Create, Read, Update, Delete) 로직 ---
# 데이터베이스와 상호작용하는 함수들을 모아놓은 곳입니다.
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

# --- FastAPI 앱 및 라우터 설정 ---
# 웹 서버의 '뼈대'를 만들고, API 주소(라우터)들을 연결합니다.
app = FastAPI()

# 모든 출처(CORS)에서 요청을 허용하도록 설정합니다.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# API 주소들을 모아놓는 '라우터'를 만듭니다.
router = APIRouter(prefix="/api", tags=["Users API"])
app.include_router(meetings.router, prefix="/api", tags=["Meetings API"])


# --- API 엔드포인트 ---
# 실제 사용자가 요청을 보낼 주소와 그 요청을 처리할 함수를 연결합니다.

@router.post("/signup", response_model=UserInDB)
async def create_user_route(user: UserCreate, db: Session = Depends(get_db)):
    """
    회원가입을 처리하는 API입니다.
    사용자 이름이 이미 존재하면 에러를 반환합니다.
    """
    db_user = get_user_by_username(db, username=user.username)
    if db_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="이미 존재하는 아이디입니다."
        )
    return create_user(db=db, user=user)

# @router.post("/login")
# async def login_route(user_data: UserLogin, db: Session = Depends(get_db)):
#     """
#     로그인을 처리하는 API입니다.
#     아이디와 비밀번호가 맞지 않으면 에러를 반환합니다.
#     """
#     user = get_user_by_username(db, username=user_data.username)
#     if not user:
#         raise HTTPException(
#             status_code=status.HTTP_400_BAD_REQUEST,
#             detail="아이디 또는 비밀번호가 틀립니다."
#         )
#     if not verify_password(user_data.password, user.hashed_password):
#         raise HTTPException(
#             status_code=status.HTTP_400_BAD_REQUEST,
#             detail="아이디 또는 비밀번호가 틀립니다."
#         )
#     return {"message": "로그인 성공!"}

@router.post("/login")
async def login_route(user_data: UserLogin, db: Session = Depends(get_db)):
    """
    로그인을 처리하는 API입니다.
    아이디와 비밀번호가 맞지 않으면 에러를 반환합니다.
    """
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
    # 아래 return 문을 수정합니다.
    return {
        "message": "로그인 성공!",
        "username": user.username,  # DB에서 찾은 사용자 이름을 추가
        "email": user.email        # DB에서 찾은 이메일을 추가
    }


# main 앱에 라우터를 포함시킵니다.
app.include_router(router)


@app.post("/api/notifications/pdf-complete")
async def send_pdf_complete_notification():
    message = json.dumps({"type": "pdf_complete"})
    await notification_manager.broadcast(message)
    return {"message": "Notification sent"}

@app.websocket("/ws/notifications")
async def notifications_ws(websocket: WebSocket):
    await notification_manager.connect(websocket)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        notification_manager.disconnect(websocket)

