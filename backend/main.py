from fastapi import FastAPI, File, UploadFile, Form, Request, Body, WebSocket, WebSocketDisconnect
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from datetime import datetime
from pydantic import BaseModel
from fastapi import BackgroundTasks
from fastapi.responses import FileResponse
from urllib.parse import unquote
from fpdf import FPDF
from fastapi import HTTPException
import json
import shutil
import openai
import uuid
import warnings
import requests
import re
import asyncio
from azure.cognitiveservices.speech import AudioConfig, SpeechConfig, SpeechRecognizer, ResultReason
import azure.cognitiveservices.speech as speechsdk
from typing import List

from api import meetings

import os
from dotenv import load_dotenv
load_dotenv()


#azure
SPEECH_KEY = os.getenv("SPEECH_KEY")
REGION = os.getenv("REGION")

#openapi
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

#Clova
CLOVA_SECRET = os.getenv("CLOVA_SECRET")
CLOVA_INVOKE_URL = os.getenv("CLOVA_INVOKE_URL")



app = FastAPI()

app.include_router(meetings.router, prefix="/api", tags=["Meetings API"])

# CORS 설정: 모든 출처에서 요청을 허용
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

#업로드 완료되면 앱 푸시
class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def broadcast(self, message: str):
        for conn in list(self.active_connections):
            try:
                await conn.send_text(message)
            except:
                self.disconnect(conn)

manager = ConnectionManager()

@app.websocket("/ws/notifications")
async def notifications_ws(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            # 클라이언트 ping 용(필요 없으면 지워도 OK)
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket)



progress_map = {}
# fpdf/ttfonts.py 모듈에서 "cmap value too big/small" 메시지를 무시
warnings.filterwarnings(
    "ignore",
    message=r"cmap value too big/small:.*",
    category=UserWarning,
    module=r"fpdf\.ttfonts"
)

@app.websocket("/ws/stt")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    print("🎙 WebSocket 연결됨")

    # 오디오 데이터를 받기 위한 스트림
    stream = speechsdk.audio.PushAudioInputStream()
    audio_config = speechsdk.audio.AudioConfig(stream=stream)
    speech_config = speechsdk.SpeechConfig(subscription=SPEECH_KEY, region=REGION)
    speech_config.speech_recognition_language = "ko-KR"

    recognizer = speechsdk.SpeechRecognizer(
        speech_config=speech_config, audio_config=audio_config
    )

    loop = asyncio.get_event_loop()

    done = asyncio.Event()

    def handle_result(evt):
        if evt.result.reason == ResultReason.RecognizedSpeech:
            asyncio.run_coroutine_threadsafe(
                websocket.send_text(evt.result.text), loop
            )

    recognizer.recognized.connect(handle_result)

    def stop_cb(evt):
        print("🛑 인식 종료:", evt)
        done.set()

    recognizer.session_stopped.connect(stop_cb)
    recognizer.canceled.connect(stop_cb)

    recognizer.start_continuous_recognition()

    try:
        while True:
            data = await websocket.receive_bytes()
            stream.write(data)
    except Exception as e:
        print("❌ 에러:", e)
    finally:
        recognizer.stop_continuous_recognition()
        stream.close()
        await websocket.close()


# ClovaSpeechClient 정의
class ClovaSpeechClient:

    def req_upload(self, file, completion, callback=None, userdata=None,
                   forbiddens=None, boostings=None, wordAlignment=True,
                   fullText=True, diarization=None, sed=None):
        request_body = {
            'language': 'ko-KR',
            'completion': completion,
            'callback': callback,
            'userdata': userdata,
            'wordAlignment': wordAlignment,
            'fullText': fullText,
            'forbiddens': forbiddens,
            'boostings': boostings,
            'diarization': diarization,
            'sed': sed,
        }
        headers = {
            'Accept': 'application/json;UTF-8',
            'X-CLOVASPEECH-API-KEY': self.secret
        }
        files = {
            'media': open(file, 'rb'),
            'params': (None, json.dumps(request_body, ensure_ascii=False).encode('UTF-8'),
                       'application/json')
        }
        return requests.post(
            headers=headers,
            url=self.invoke_url + '/recognizer/upload',
            files=files
        )



#mp3 텍스트화
def transcribe_and_save_to_json(audio_path: str, output_dir: str,
                                summary_mode: str = "기본",
                                custom_prompt: str = None):
    directory_key = os.path.basename(output_dir)
    progress_map[directory_key] = 0

    client = ClovaSpeechClient()
    try:
        # 10% 진행
        progress_map[directory_key] = 10

        # 30% – Clova STT 업로드 & 결과 수신
        print("🗣️ Clova STT 요청 중...")
        progress_map[directory_key] = 30
        res = client.req_upload(file=audio_path, completion='sync')
        res.raise_for_status()
        result = res.json()

        # 40% – segments 추출 및 speaker 레이블 정리
        raw_segments = result.get('segments', [])
        segments = []
        for seg in raw_segments:
            label = seg.get('speaker', {}).get('label', 'unknown')
            segments.append({
                'start': seg.get('start'),
                'end':   seg.get('end'),
                'speaker': label,
                'text': seg.get('text', '').strip()
            })
        progress_map[directory_key] = 40

        # 70% – result.json 저장
        combined_text = " ".join([s['text'] for s in segments])
        payload = {"segments": segments, "text": combined_text}
        os.makedirs(output_dir, exist_ok=True)
        json_path = os.path.join(output_dir, "result.json")
        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(payload, f, ensure_ascii=False, indent=2)
        progress_map[directory_key] = 70

        # 90% – 요약 생성
        summary = summarize_text(combined_text, mode=summary_mode, custom_prompt=custom_prompt)
        summary_path = os.path.join(output_dir, "summary.json")
        with open(summary_path, "w", encoding="utf-8") as f:
            json.dump({"summary": summary}, f, ensure_ascii=False, indent=2)
        progress_map[directory_key] = 90

        print(f"✅ 변환 완료! '{json_path}'에 저장됨")
        progress_map[directory_key] = 100


        pdf_path = os.path.join(output_dir, "summary.pdf")
        save_summary_as_pdf(summary, pdf_path)

        # save_summary_as_pdf(summary, output_dir)
        return json_path

    except Exception as e:
        print("❌ 변환 중 에러 발생:", e)
        progress_map[directory_key] = -1
        return


#result.json 파일 출력
@app.get("/result/{directory}")
def get_result_json(directory: str):
    try:
        decoded_dir = unquote(directory)
        base_dir = os.path.dirname(__file__)
        result_path = os.path.join(base_dir, "uploaded_files", decoded_dir, "result.json")

        if os.path.exists(result_path):
            with open(result_path, "r", encoding="utf-8") as f:
                data = json.load(f)
            return JSONResponse(content=data, media_type="application/json; charset=utf-8")
        else:
            return JSONResponse(content={"error": "result.json not found"}, status_code=404)
    except Exception as e:
        return JSONResponse(content={"error": str(e)}, status_code=500)

def summarize_text(text: str, mode="기본", custom_prompt=None) -> str:
    try:
        # 1. 기본 모드일 경우: 정형화된 회의록 양식 적용
        if mode == "기본":
            system_prompt = (
                "너는 전문 회의록 요약가야. 반드시 아래 양식으로 항목별로 요약해.\n"
                "양식을 생략하거나 문단으로 바꾸지 마. 항목 제목도 반드시 포함할 것.\n\n"
                "양식:\n"
                "1. 회의 제목:\n"
                "2. 회의 일시:\n"
                "3. 참석자:\n"
                "4. 회의 목적:\n"
                "5. 주요 발언 요약:\n"
                "6. 결정 사항:\n"
                "7. 다음 일정/후속 조치:\n"
            )

            user_prompt = (
                "다음 회의록을 위 양식대로 항목별로 요약해줘. 각 항목 제목은 그대로 유지하고, "
                "항목 누락 없이 써야 해. 문장은 간결하게.\n\n"
                f"{text}"
            )

        # 2. 사용자 지정 프롬프트 사용 시
        else:
            system_prompt = custom_prompt or "회의 내용을 요약해줘."
            user_prompt = text

        # 3. GPT 호출
        response = openai.ChatCompletion.create(
            model="gpt-4-turbo",  # 또는 gpt-3.5-turbo
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            temperature=0.3,
            max_tokens=1500
        )

        return response.choices[0].message["content"].strip()

    except Exception as e:
        return f"요약 실패: {e}"


#PDF 다운로드 제공
@app.get("/pdf/{directory}")
def get_summary_pdf(directory: str):
    pdf_path = os.path.join("uploaded_files", directory, "summary.pdf")
    
    if os.path.exists(pdf_path):
        return FileResponse(
            path=pdf_path,
            filename="회의록.pdf",
            media_type="application/pdf"
        )
    else:
        return {"error": "PDF 파일을 찾을 수 없습니다."}

class PrettyPDF(FPDF):
    def header(self):
        self.set_font("NanumBarun", "B", 14)
        self.cell(0, 10, "회의 요약 보고서", ln=True, align="C")
        self.ln(10)

    def add_boxed_section(self, title, content):
        self.set_font("NanumBarun", "B", 12)
        self.set_fill_color(230, 230, 250)
        self.cell(0, 10, title, ln=True, fill=True)

        self.set_font("NanumBarun", "", 11)
        self.multi_cell(0, 8, content.strip())
        self.ln(5)

def save_summary_as_pdf(summary_text: str, output_path: str):
    font_regular = "/usr/share/fonts/truetype/nanum/NanumBarunGothic.ttf"
    font_bold    = "/usr/share/fonts/truetype/nanum/NanumBarunGothicBold.ttf"

    pdf = PrettyPDF()
    pdf.add_font("NanumBarun", "", font_regular, uni=True)
    pdf.add_font("NanumBarun", "B", font_bold, uni=True)
    pdf.set_auto_page_break(auto=True, margin=15)
    pdf.add_page()
    pdf.set_font("NanumBarun", "", 12)
    effective_width = pdf.w - pdf.l_margin - pdf.r_margin
    pdf.multi_cell(effective_width, 8, summary_text)

    pdf.output(output_path)
    print(f"✅ PDF 생성 완료: {output_path}")
    # print(f"✅ 회의 분석 완료!!")

    # WebSocket 브로드캐스트: 새 이벤트 루프에서 동기 실행
    try:
        asyncio.run(
            manager.broadcast(
                json.dumps({"type": "pdf_complete", "path": output_path})
            )
        )
    except Exception as e:
        print("🔴 WS 브로드캐스트 에러:", e)

# 로컬 테스트용
if __name__ == "__main__":
    # 실제 summary.json 경로 설정
    json_path = "uploaded_files/20250621_135715_d_9008da/summary.json"
    pdf_path  = "uploaded_files/20250621_135715_d_9008da/summary.pdf"

    if not os.path.exists(json_path):
        print(f"ERROR: '{json_path}' 파일을 찾을 수 없습니다.")
        exit(1)

    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    summary_text = data.get("summary") or data.get("text") or ""
    if not summary_text:
        print("ERROR: JSON에 'summary' 또는 'text' 필드가 없습니다.")
        exit(1)

    save_summary_as_pdf(summary_text, pdf_path)



# 진행률 제공
@app.get("/progress/{directory}")
def get_progress(directory: str):
    progress = progress_map.get(directory)
    if progress is None:
        return JSONResponse(content={"error": "진행률 정보 없음"}, status_code=404)
    return {"progress": progress}



# 회의 관심 등록
@app.patch("/meetings/interested")
def update_is_interested(data: dict = Body(...)):
    directory = data.get("directory")
    new_status = data.get("is_interested")

    meetings_path = os.path.join(os.path.dirname(__file__), "meetings.json")
    if not os.path.exists(meetings_path):
        raise HTTPException(status_code=404, detail="meetings.json 파일 없음")

    with open(meetings_path, "r", encoding="utf-8") as f:
        meetings = json.load(f)

    found = False
    for date in meetings:
        for meeting in meetings[date]:
            if meeting.get("directory") == directory:
                meeting["is_interested"] = new_status
                found = True

    if not found:
        raise HTTPException(status_code=404, detail="해당 회의 찾을 수 없음")

    with open(meetings_path, "w", encoding="utf-8") as f:
        json.dump(meetings, f, ensure_ascii=False, indent=2)

    return {"message": "관심 상태가 업데이트되었습니다!"}



# 6/25 새로운 회의용 로직 추가 작성 부분

@app.post("/upload_meeting_aac")
async def upload_meeting_aac(
    background_tasks: BackgroundTasks,
    meetingName: str = Form(...),
    meetingDescription: str = Form(...),
    meetingDate: str = Form(...),
    file: UploadFile = File(...)
):
    try:
        # ✅ 요청 수신 로그 추가
        print("📥 [upload_meeting_aac] POST 요청 수신됨")
        print(f"📌 회의명: {meetingName}, 날짜: {meetingDate}, 설명: {meetingDescription}")
        print(f"📁 업로드된 파일명: {file.filename}, 콘텐츠 타입: {file.content_type}")

        # 기본 디렉토리 설정
        base_dir = os.path.dirname(__file__)
        upload_root = os.path.join(base_dir, "uploaded_files")

        # 폴더 생성
        safe_name = meetingName.replace(" ", "_")[:15]
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        unique_id = uuid.uuid4().hex[:6]
        folder_name = f"{timestamp}_{safe_name}_{unique_id}"
        folder_path = os.path.join(upload_root, folder_name)
        os.makedirs(folder_path, exist_ok=True)

        # AAC 저장
        aac_path = os.path.join(folder_path, "audio.aac")
        try:
            with open(aac_path, "wb") as buffer:
                shutil.copyfileobj(file.file, buffer)
            print(f"✅ AAC 파일 저장 완료: {aac_path}")
        except Exception as e:
            print(f"❌ AAC 저장 중 오류: {repr(e)}")

        # meetings.json 기록 추가
        print("📝 meetings.json 기록 준비 중")
        meetings_path = os.path.join(base_dir, "meetings.json")
        if os.path.exists(meetings_path):
            with open(meetings_path, "r", encoding="utf-8") as f:
                meetings = json.load(f)
        else:
            meetings = {}

        meeting_obj = {
            "name": meetingName,
            "description": meetingDescription,
            "is_interested": False,
            "is_ended": True,
            "directory": folder_name
        }

        if meetingDate not in meetings:
            meetings[meetingDate] = []
        meetings[meetingDate].append(meeting_obj)

        with open(meetings_path, "w", encoding="utf-8") as f:
            json.dump(meetings, f, ensure_ascii=False, indent=2)

        # 백그라운드 작업 등록
        summary_mode = "기본"
        custom_prompt = None

        print(f"🟡 백그라운드 작업 등록 시작: {aac_path}")
        background_tasks.add_task(
            transcribe_and_save_to_json,
            aac_path,
            folder_path,
            summary_mode,
            custom_prompt
        )

        return {"message": "✅ AAC 파일 업로드 및 처리 시작", "directory": folder_name}

    except Exception as e:
        print("🔴 에러 발생:", e)
        return JSONResponse(status_code=500, content={"error": str(e)})
