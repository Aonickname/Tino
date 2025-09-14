from typing import List, Optional
from fastapi import WebSocket, WebSocketDisconnect, APIRouter
import os
import asyncio
import azure.cognitiveservices.speech as speechsdk
from dotenv import load_dotenv
import json
import sys
from pydantic import BaseModel
import warnings
from fpdf import FPDF
from unidecode import unidecode

# 환경 변수 불러오기
load_dotenv()
router = APIRouter()

class ConnectionManager:
    def __init__(self):
        self.active_connections: List[WebSocket] = []

    async def connect(self, websocket: WebSocket):
        await websocket.accept()
        self.active_connections.append(websocket)

    def disconnect(self, websocket: WebSocket):
        self.active_connections.remove(websocket)

    async def broadcast(self, message: str):
        for connection in list(self.active_connections):
            try:
                await connection.send_text(message)
            except:
                self.disconnect(connection)

manager = ConnectionManager()

# ✨ 전역 변수로 선언하여 모든 연결에서 공유 ✨
recordings = []

# fpdf 경고 메시지 무시 설정
warnings.filterwarnings(
    "ignore",
    message=r"cmap value too big/small:.*",
    category=UserWarning,
    module=r"fpdf\.ttfonts"
)

# PDF 생성을 위한 클래스
class PrettyPDF(FPDF):
    def header(self):
        self.set_font("NanumBarun", "B", 14)
        self.cell(0, 10, "회의 요약 보고서", ln=True, align="C")
        self.ln(10)

def save_summary_as_pdf(summary_text: str, output_path: str):
    # 현재 파일의 경로를 기준으로 폰트 경로를 설정합니다.
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    font_regular = os.path.join(base_dir, "services", "fonts", "NanumBarunGothic.ttf")
    font_bold = os.path.join(base_dir, "services", "fonts", "NanumBarunGothicBold.ttf")

    if not os.path.exists(font_regular) or not os.path.exists(font_bold):
        print("❌ 에러: TTF Font file not found. 폰트 경로를 확인하세요.")
        print(f"폰트 경로: {font_regular}")
        return

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

# --- (STT 웹소켓 코드) ---
SPEECH_KEY = os.getenv("SPEECH_KEY")
REGION = os.getenv("REGION")

def run_coroutine_in_thread(coro):
    try:
        loop = asyncio.get_running_loop()
        loop.create_task(coro)
    except RuntimeError:
        asyncio.run(coro)

@router.websocket("/ws/stt/{directory}")
async def stt_websocket(websocket: WebSocket, directory: str):
    await websocket.accept()
    print("✅ STT 클라이언트가 연결되었습니다.")

    speech_config = speechsdk.SpeechConfig(subscription=SPEECH_KEY, region=REGION)
    speech_config.speech_recognition_language = "ko-KR"

    stream_format = speechsdk.audio.AudioStreamFormat(samples_per_second=16000, bits_per_sample=16, channels=1)
    push_stream = speechsdk.audio.PushAudioInputStream(stream_format)

    audio_config = speechsdk.AudioConfig(stream=push_stream)
    speech_recognizer = speechsdk.SpeechRecognizer(speech_config=speech_config, audio_config=audio_config)

    async def send_recognized_text(evt):
        if evt.result.reason == speechsdk.ResultReason.RecognizedSpeech and evt.result.text:
            recognized_text = evt.result.text
            print(f"✅ 최종 인식: {recognized_text}")
            await websocket.send_text(recognized_text)
            
            # 전역 리스트에 텍스트 추가
            global recordings
            recordings.append({"text": recognized_text})

    speech_recognizer.recognized.connect(lambda evt: run_coroutine_in_thread(send_recognized_text(evt)))
    
    speech_recognizer.session_started.connect(lambda evt: print(f"--- 세션 시작됨 ---"))
    speech_recognizer.session_stopped.connect(lambda evt: print(f"--- 세션 중단됨 ---"))

    speech_recognizer.start_continuous_recognition_async()

    try:
        while True:
            audio_data = await websocket.receive_bytes()
            push_stream.write(audio_data)

    except WebSocketDisconnect:
        print("🔌 STT 클라이언트 연결이 끊어졌습니다.")
    finally:
        speech_recognizer.stop_continuous_recognition_async()
        push_stream.close()
        print("🗑️ STT 리소스를 정리했습니다.")
        
# ⭐️ Pydantic 모델을 사용하여 요청 본문 유효성 검사
class SummaryRequest(BaseModel):
    mode: str
    custom_prompt: Optional[str] = None
        
def save_transcription_to_json(directory: str):
    global recordings
    
    # 최종 JSON 파일로 저장
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    upload_root = os.path.join(base_dir, "uploaded_files")
    save_path = os.path.join(upload_root, directory, "result.json")
    
    with open(save_path, "w", encoding="utf-8") as f:
        json.dump({"segments": recordings}, f, ensure_ascii=False, indent=2)
    
    print(f"✅ 최종 JSON 파일이 '{save_path}'에 저장되었습니다.")
        
# ⭐️ 요약 기능을 위한 새로운 API 엔드포인트 추가
@router.post("/summarize/{directory}")
async def summarize_meeting(directory: str, request: SummaryRequest):
    # ⭐️ 요약 요청이 들어오면 먼저 transcription 파일부터 저장합니다.
    save_transcription_to_json(directory)
    
    # 1. 파일 경로 설정
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    file_path = os.path.join(base_dir, "uploaded_files", directory, "result.json")
    
    # 2. 파일이 있는지 확인
    if not os.path.exists(file_path):
        return {"error": "파일을 찾을 수 없습니다."}
    
    # 3. JSON 파일 읽기
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            data = json.load(f)
            # 모든 텍스트를 하나로 합치기
            full_text = " ".join(item['text'] for item in data['segments'])
    except Exception as e:
        return {"error": f"파일 읽기 실패: {e}"}

    # 4. summarize_text.py 모듈 불러오기
    sys.path.append(os.path.join(base_dir, "services"))
    from summarize_text import summarize_text
    
    # 5. 요약 함수 실행
    if request.mode == "기본":
        summary = summarize_text(full_text, mode="기본")
    else: # 사용자 지정 요약
        summary = summarize_text(full_text, mode="사용자 지정", custom_prompt=request.custom_prompt)
        
    # ⭐️ 요약 결과를 summary.json 파일로 저장
    summary_dir = os.path.join(base_dir, "uploaded_files", directory)
    summary_path = os.path.join(summary_dir, "summary.json")
    
    with open(summary_path, "w", encoding="utf-8") as f:
        json.dump({"summary": summary}, f, ensure_ascii=False, indent=2)
    print(f"✅ 요약 JSON 파일이 '{summary_path}'에 저장되었습니다.")

    # ⭐️ 요약 결과를 summary.pdf 파일로 저장
    pdf_path = os.path.join(summary_dir, "summary.pdf")
    save_summary_as_pdf(summary, pdf_path)
        
    return {"summary": summary}