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
