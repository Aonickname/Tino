import os
import json
import uuid
import shutil
from datetime import datetime
from fastapi import APIRouter, HTTPException, BackgroundTasks, Form, UploadFile, File
from fastapi.responses import JSONResponse
from urllib.parse import unquote
from models.meeting_schemas import Meeting


# FastApi 라우터 생성
router = APIRouter()

# 프로젝트 기준 폴더 경로
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

#회의 정보를 저장할 JSON 파일 경로
MEETINGS_JSON_PATH = os.path.join(BASE_DIR, "meetings.json")


# GET: 회의 조회
@router.get("/meetings")
def get_meetings():
    try:
        with open(MEETINGS_JSON_PATH, "r", encoding="utf-8") as f:
            data = json.load(f)
        return JSONResponse(content=data, media_type="application/json; charset=utf-8")
    except FileNotFoundError:
        #파일이 없으면 빈 딕셔너리 반환
        return JSONResponse(content={}, media_type="application/json; charset=utf-8")
    except Exception as e:
        print(f"Error reading meetings.json: {e}")
        raise HTTPException(status_code=500, detail="서버에서 파일을 읽는 중 오류가 발생했습니다.")
    
# POST: 회의 추가
@router.post("/meetings")
def add_meeting(meeting: Meeting):
    try:
        #기존 meetings.json 읽기
        if os.path.exists(MEETINGS_JSON_PATH):
            with open(MEETINGS_JSON_PATH, "r", encoding="utf-8") as f:
                meetings = json.load(f)
        else:
            meetings = {}

        # 새 회의 폴더 이름 생성 : timestamp_이름_uuid
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")    # 폴더 이름
        safe_name = meeting.name.replace(" ", "_")[:15]         # 랜덤 6자리
        unique_id = uuid.uuid4().hex[:6]
        directory = f"{timestamp}_{safe_name}_{unique_id}"

        # 폴더 생성
        folder_path = os.path.join(BASE_DIR, "uploaded_files", directory)
        os.makedirs(folder_path, exist_ok=True)

        # JSON에 들어갈 회의 객체 생성
        meeting_obj = {
            "name": meeting.name,
            "description": meeting.description,
            "is_interested": meeting.is_interested,
            "is_ended": meeting.is_ended,
            "directory": directory
        }

        # 날짜별로 회의 리스트 관리
        if meeting.date not in meetings:
            meetings[meeting.date] = []

        meetings[meeting.date].append(meeting_obj)

        # meetings.json에 저장
        with open(MEETINGS_JSON_PATH, "w", encoding="utf-8") as f:
            json.dump(meetings, f, ensure_ascii=False, indent=2)

        return {"message": "회의가 성공적으로 추가되었습니다!", "directory": directory}

    except Exception as e:
        print(f"Error adding meeting: {e}")
        raise HTTPException(status_code=500, detail="회의 추가 중 서버 오류가 발생했습니다.")
    
# POST: mp3 업로드 & 회의 추가
@router.post("/upload")
async def upload_meeting_with_file(
    background_tasks: BackgroundTasks,
    name: str = Form(...),
    description: str = Form(...),
    date: str = Form(...),
    file: UploadFile = File(...),
    summary_mode: str = Form(...),
    custom_prompt: str = Form(None),
):
    try:
        upload_root = os.path.join(BASE_DIR, "uploaded_files")

        # 고유 폴더 생성
        safe_name = name.replace(" ", "_")[:15]
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        unique_id = uuid.uuid4().hex[:6]
        folder_name = f"{timestamp}_{safe_name}_{unique_id}"
        folder_path = os.path.join(upload_root, folder_name)
        os.makedirs(folder_path, exist_ok=True)

        # mp3 저장
        extension = os.path.splitext(file.filename)[1]
        mp3_path = os.path.join(folder_path, f"audio{extension}")
        with open(mp3_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)

        # meetings.json 업데이트
        if os.path.exists(MEETINGS_JSON_PATH):
            with open(MEETINGS_JSON_PATH, "r", encoding="utf-8") as f:
                meetings = json.load(f)
        else:
            meetings = {}

        meeting_obj = {
            "name": name,
            "description": description,
            "is_interested": False,
            "is_ended": True,
            "directory": folder_name
        }

        if date not in meetings:
            meetings[date] = []
        meetings[date].append(meeting_obj)

        with open(MEETINGS_JSON_PATH, "w", encoding="utf-8") as f:
            json.dump(meetings, f, ensure_ascii=False, indent=2)
        
        # 백그라운드 작업: mp3 -> 텍스트 변환 + summary 생성
        background_tasks.add_task(
            transcribe_and_save_to_json,
            mp3_path,
            folder_path,
            summary_mode,
            custom_prompt
        )

        return {"message": "회의 정보와 파일이 성공적으로 저장되었습니다!", "directory": folder_name}

    except Exception as e:
        print(f"Error uploading file: {e}")
        raise HTTPException(status_code=500, detail="파일 업로드 중 서버 오류가 발생했습니다.")
    
# DELETE: 회의 삭제
@router.delete("/delete/{directory}")
def delete_meeting(directory: str):
    try:
        base_dir = os.path.dirname(__file__)
        folder_path = os.path.join(base_dir, "uploaded_files", directory)
        meetings_path = os.path.join(base_dir, "meetings.json")

        # uploaded_files에서 폴더 삭제
        if os.path.exists(folder_path):
            shutil.rmtree(folder_path)
        else:
            print("❗ 폴더가 존재하지 않음:", folder_path)

        # meetings.json에서 해당 directory를 가진 회의 제거
        if os.path.exists(meetings_path):
            with open(meetings_path, "r", encoding="utf-8") as f:
                meetings = json.load(f)

            modified = False
            for date in list(meetings.keys()):
                original_len = len(meetings[date])
                meetings[date] = [m for m in meetings[date] if m.get("directory") != directory]
                if len(meetings[date]) < original_len:
                    modified = True
                if not meetings[date]:
                    del meetings[date]  # 빈 날짜 제거

            if modified:
                with open(meetings_path, "w", encoding="utf-8") as f:
                    json.dump(meetings, f, ensure_ascii=False, indent=2)
            else:
                print("❗ meetings.json에서 해당 데이터 못 찾음")

        return {"message": f"{directory} 삭제 완료"}

    except Exception as e:
        print("❌ 삭제 중 오류:", e)
        raise HTTPException(status_code=500, detail=str(e))
    
# GET: summary.json 출력
@router.get("/summary/{directory}") 
def get_summary_json(directory: str):
    try:
        decoded_dir = unquote(directory)    #URL 디코딩
        summary_path = os.path.join(BASE_DIR, "uploaded_files", decoded_dir, "summary.json")

        if os.path.exists(summary_path):
            with open(summary_path, "r", encoding="utf-8") as f:
                data = json.load(f)
            return JSONResponse(content=data, media_type="application/json; charset=utf-8")
        else:
            raise HTTPException(status_code=404, detail="summary.json not found")

    except Exception as e:
        print(f"Error reading summary.json for {directory}: {e}")
        raise HTTPException(status_code=500, detail="서버 오류가 발생했습니다.")


#발언 비율 계산
@router.get("/ratio/{directory}")
def get_speaker_ratio_for_directory(directory: str):
    try:
        decoded_dir = unquote(directory)
        result_path = os.path.join(BASE_DIR, "uploaded_files", decoded_dir, "result.json")

        if not os.path.exists(result_path):
            raise HTTPException(status_code=404, detail="result.json not found")

        with open(result_path, "r", encoding="utf-8") as f:
            data = json.load(f)

        # 발언 시간 계산
        durations = {}
        for seg in data.get("segments", []):
            sp = seg.get("speaker")
            start_time = seg.get("start", 0) or 0
            end_time = seg.get("end", 0) or 0
            dur = end_time - start_time
            
            durations[sp] = durations.get(sp, 0) + dur

        total = sum(durations.values())
        if total == 0:
            return JSONResponse(content={sp: 0 for sp in durations}, media_type="application/json; charset=utf-8")

        # 비율 계산
        ratios = {sp: round((dur / total) * 100, 1) for sp, dur in durations.items()}
        return JSONResponse(content=ratios, media_type="application/json; charset=utf-8")

    except Exception as e:
        print(f"Error calculating ratio for {directory}: {e}")
        raise HTTPException(status_code=500, detail="서버 오류가 발생했습니다.")