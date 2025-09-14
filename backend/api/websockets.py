from typing import List
from fastapi import WebSocket, WebSocketDisconnect, APIRouter
import os
import asyncio
import azure.cognitiveservices.speech as speechsdk
from dotenv import load_dotenv
import json

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
            recordings.append({"text": recognized_text})

    speech_recognizer.recognized.connect(lambda evt: run_coroutine_in_thread(send_recognized_text(evt)))
    
    speech_recognizer.session_started.connect(lambda evt: print(f"--- 세션 시작됨 ---"))
    speech_recognizer.session_stopped.connect(lambda evt: print(f"--- 세션 중단됨 ---"))

    speech_recognizer.start_continuous_recognition_async()

    # 파일이 저장될 기본 루트 폴더
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    upload_root = os.path.join(base_dir, "uploaded_files")

    # 최종 파일 저장 경로를 만듭니다.
    save_path = os.path.join(upload_root, directory, "result.json")

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
        
        # 최종 JSON 파일로 저장
        with open(save_path, "w", encoding="utf-8") as f:
            json.dump({"segments": recordings}, f, ensure_ascii=False, indent=2)
        
        print(f"✅ 최종 JSON 파일이 '{save_path}'에 저장되었습니다.")