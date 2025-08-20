import os
import json
import requests
import openai
import warnings

# PDF 생성을 위한 FPDF 라이브러리
from fpdf import FPDF

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

# 진행률 추적을 위한 딕셔너리 (원래 main.py에 있던 것)
progress_map = {}

# fpdf 경고 메시지 무시 설정
warnings.filterwarnings(
    "ignore",
    message=r"cmap value too big/small:.*",
    category=UserWarning,
    module=r"fpdf\.ttfonts"
)


# ClovaSpeechClient 클래스 (API 키를 settings에서 가져오도록 수정)
class ClovaSpeechClient:
    invoke_url = CLOVA_INVOKE_URL
    secret     = CLOVA_SECRET

    def req_upload(self, file, completion, **kwargs):
        request_body = {
            'language': 'ko-KR',
            'completion': completion,
            **kwargs
        }
        headers = {
            'Accept': 'application/json;UTF-8',
            'X-CLOVASPEECH-API-KEY': self.secret
        }
        files = {
            'media': open(file, 'rb'),
            'params': (None, json.dumps(request_body, ensure_ascii=False).encode('UTF-8'), 'application/json')
        }
        return requests.post(headers=headers, url=f'{self.invoke_url}/recognizer/upload', files=files)


# 텍스트 요약 함수
def summarize_text(text: str, mode="기본", custom_prompt=None) -> str:
    try:
        if mode == "기본":
            system_prompt = (
                "너는 전문 회의록 요약가야. 반드시 아래 양식으로 항목별로 요약해.\n"
                "양식을 생략하거나 문단으로 바꾸지 마. 항목 제목도 반드시 포함할 것.\n\n"
                "양식:\n"
                "1. 회의 제목:\n2. 회의 일시:\n3. 참석자:\n4. 회의 목적:\n"
                "5. 주요 발언 요약:\n6. 결정 사항:\n7. 다음 일정/후속 조치:\n"
            )
            user_prompt = f"다음 회의록을 위 양식대로 항목별로 요약해줘. 각 항목 제목은 그대로 유지하고, 항목 누락 없이 써야 해. 문장은 간결하게.\n\n{text}"
        else:
            system_prompt = custom_prompt or "회의 내용을 요약해줘."
            user_prompt = text

        response = openai.ChatCompletion.create(
            model="gpt-4-turbo",
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            temperature=0.3,
            max_tokens=1500
        )
        return response.choices[0].message["content"].strip()
    except Exception as e:
        print(f"Error during summarization: {e}")
        return f"요약 실패: {e}"


# PDF 생성을 위한 클래스와 함수 (원래 main.py에 있던 것)
class PrettyPDF(FPDF):
    def header(self):
        self.set_font("NanumBarun", "B", 14)
        self.cell(0, 10, "회의 요약 보고서", ln=True, align="C")
        self.ln(10)

def save_summary_as_pdf(summary_text: str, output_path: str):
    # 나눔고딕 폰트가 시스템 또는 Docker 컨테이너 내에 설치되어 있어야 합니다.
    font_regular = "/usr/share/fonts/truetype/nanum/NanumBarunGothic.ttf"
    font_bold    = "/usr/share/fonts/truetype/nanum/NanumBarunGothicBold.ttf"

    pdf = PrettyPDF()
    pdf.add_font("NanumBarun", "", font_regular, uni=True)
    pdf.add_font("NanumBarun", "B", font_bold, uni=True)
    pdf.set_auto_page_break(auto=True, margin=15)
    pdf.add_page()
    pdf.set_font("NanumBarun", "", 12)
    pdf.multi_cell(0, 8, summary_text)
    pdf.output(output_path)
    print(f"✅ PDF 생성 완료: {output_path}")


# 메인 처리 함수 (api/meetings.py에서 호출할 함수)
def transcribe_and_save_to_json(audio_path: str, output_dir: str, summary_mode: str, custom_prompt: str | None):
    directory_key = os.path.basename(output_dir)
    progress_map[directory_key] = 0
    client = ClovaSpeechClient()

    try:
        progress_map[directory_key] = 10
        print("🗣️  Clova STT 요청 중...")
        res = client.req_upload(
            file=audio_path,
            completion='sync',
            wordAlignment=True,
            fullText=True
        )
        res.raise_for_status()
        result = res.json()
        progress_map[directory_key] = 30
        
        raw_segments = result.get('segments', [])
        segments = [{'start': s.get('start'), 'end': s.get('end'), 'speaker': s.get('speaker', {}).get('label', 'unknown'), 'text': s.get('text', '').strip()} for s in raw_segments]
        progress_map[directory_key] = 40

        combined_text = " ".join([s['text'] for s in segments])
        payload = {"segments": segments, "text": combined_text}
        json_path = os.path.join(output_dir, "result.json")
        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(payload, f, ensure_ascii=False, indent=2)
        progress_map[directory_key] = 70

        summary = summarize_text(combined_text, mode=summary_mode, custom_prompt=custom_prompt)
        summary_path = os.path.join(output_dir, "summary.json")
        with open(summary_path, "w", encoding="utf-8") as f:
            json.dump({"summary": summary}, f, ensure_ascii=False, indent=2)
        progress_map[directory_key] = 90
        
        pdf_path = os.path.join(output_dir, "summary.pdf")
        save_summary_as_pdf(summary, pdf_path)
        progress_map[directory_key] = 100

        print(f"✅ 변환 완료! '{json_path}'에 저장됨")
    except Exception as e:
        print(f"❌ 변환 중 에러 발생: {e}")
        progress_map[directory_key] = -1
