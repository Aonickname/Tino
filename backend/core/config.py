import os
from pydantic_settings import BaseSettings

# .env 파일, 시스템 환경 변수에서 설정 값을 읽어오기
class Settings(BaseSettings):
    # Azure Speech 설정
    SPEECH_KEY: str
    REGION: str = "eastus"

    # OpenAI 설정
    OPENAI_API_KEY: str

    # Clova Speech 설정
    CLOVA_INVOKE_URL: str
    CLOVA_SECRET: str

    class Config:
        # 프로젝트 루트에 있는 .env 파일에서 환경 변수를 불러오기
        env_file = ".env"
        env_file_encoding = "utf-8"

# 앱 전체에서 공유할 단일 설정 인스턴스를 생성
settings = Settings()
