from typing import List
from fastapi import WebSocket, WebSocketDisconnect
import os
import asyncio
from fastapi import APIRouter
import azure.cognitiveservices.speech as speechsdk
from dotenv import load_dotenv

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


# --- (STT 웹소켓 코드) ---
SPEECH_KEY = os.getenv("SPEECH_KEY")
REGION = os.getenv("REGION")

def run_coroutine_in_thread(coro):
    try:
        loop = asyncio.get_running_loop()
        loop.create_task(coro)
    except RuntimeError:
        asyncio.run(coro)


@router.websocket("/ws/stt")
async def stt_websocket(websocket: WebSocket):
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
            print(f"✅ 최종 인식: {evt.result.text}")
            await websocket.send_text(evt.result.text)

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