from fastapi import FastAPI
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import json
import os

app = FastAPI()

# CORS 설정: 모든 출처에서 요청을 허용
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 모든 출처에서 접근 허용
    allow_credentials=True,
    allow_methods=["*"],  # 모든 HTTP 메서드 허용
    allow_headers=["*"],  # 모든 헤더 허용
)

# 회의 데이터 모델
class Meeting(BaseModel):
    name: str
    description: str
    date: str

# GET: 회의 목록 조회
@app.get("/meetings")
def get_meetings():
    file_path = os.path.join(os.path.dirname(__file__), "meetings.json")

    try:
        with open(file_path, "r", encoding="utf-8") as f:
            data = json.load(f)
        # 명시적으로 UTF-8 charset을 지정해서 응답
        return JSONResponse(content=data, media_type="application/json; charset=utf-8")
    except Exception as e:
        print("에러 발생:", e)
        return JSONResponse(content={"error": str(e)}, status_code=500)



# POST: 회의 추가
@app.post("/meetings")
def add_meeting(meeting: Meeting):
    file_path = os.path.join(os.path.dirname(__file__), "meetings.json")

    try:
        # 파일 읽기
        if os.path.exists(file_path):
            with open(file_path, "r", encoding="utf-8") as f:
                meetings = json.load(f)
        else:
            meetings = {}

        # 새 회의 만들기
        meeting_obj = {
            "name": meeting.name,
            "description": meeting.description
        }

        # 해당 날짜에 회의 리스트가 없으면 초기화
        if meeting.date not in meetings:
            meetings[meeting.date] = []

        # 회의 추가
        meetings[meeting.date].append(meeting_obj)

        # 다시 저장
        with open(file_path, "w", encoding="utf-8") as f:
            json.dump(meetings, f, ensure_ascii=False, indent=2)

        return {"message": "회의가 성공적으로 추가되었습니다!"}
    
    except Exception as e:
        print("에러 발생:", e)
        return JSONResponse(content={"error": str(e)}, status_code=500)

