import os
import json
import requests
import openai
import warnings
import asyncio
from fpdf import FPDF
from dotenv import load_dotenv

# .env 파일 로드를 위해 BASE_DIR를 정의합니다.
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
dotenv_path = os.path.join(BASE_DIR, ".env")
load_dotenv(dotenv_path)

# .env에서 API 키를 불러와 할당합니다.
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
CLOVA_SECRET = os.getenv("CLOVA_SECRET")
CLOVA_INVOKE_URL = os.getenv("CLOVA_INVOKE_URL")

# OpenAI API 키를 설정합니다.
openai.api_key = OPENAI_API_KEY

# 진행률 추적을 위한 딕셔너리
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

# PDF 생성을 위한 클래스
class PrettyPDF(FPDF):
    def header(self):
        self.set_font("NanumBarun", "B", 14)
        self.cell(0, 10, "회의 요약 보고서", ln=True, align="C")
        self.ln(10)

def save_summary_as_pdf(summary_text: str, output_path: str):
    # 현재 파일의 경로를 기준으로 폰트 경로를 설정합니다.
    base_dir = os.path.dirname(os.path.abspath(__file__))
    font_regular = os.path.join(base_dir, "fonts", "NanumBarunGothic.ttf")
    font_bold = os.path.join(base_dir, "fonts", "NanumBarunGothicBold.ttf")

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

def summarize_text(text: str, mode="기본", custom_prompt=None) -> str:
    try:
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
        return f"요약 실패: {e}"

# 메인 처리 함수
def transcribe_and_save_to_json(audio_path: str, output_dir: str, summary_mode: str, custom_prompt: str | None):
    directory_key = os.path.basename(output_dir)
    progress_map[directory_key] = 0
    # ClovaSpeechClient 인스턴스를 생성합니다.
    client = ClovaSpeechClient()

    try:
        progress_map[directory_key] = 10
        print("🗣️  Clova STT 요청 중...")
        
        
        # #===========================================================
        # print("✅ API 호출 대신 테스트 모드로 진행합니다.")
        # # 가상의 요약 텍스트를 만듭니다.
        # test_summary_text = """
        # 1. 회의 제목: 웹 소켓 알림 테스트 회의
        # 2. 회의 일시: 2025년 8월 26일
        # 3. 참석자: 홍길동, 김철수
        # 4. 회의 목적: API 호출 없이 푸시 알림 테스트
        # 5. 주요 발언 요약:
        #    - 홍길동: API 비용을 절감하기 위해 알림 테스트만 하고 싶다.
        #    - 김철수: 더미 데이터를 사용하여 푸시 알림 기능을 점검하자고 제안했다.
        # 6. 결정 사항:
        #    - API 호출 부분을 주석 처리하고 가짜 데이터를 사용하기로 결정함.
        #    - 테스트용 요약 텍스트를 만들어 PDF를 생성하고 알림을 보낼 예정.
        # 7. 다음 일정/후속 조치:
        #    - 코드 수정 후 푸시 알림 테스트 실행
        #    - 테스트 완료 후 원래 코드로 복구
        # """
        
        # # 가상의 결과 파일들을 저장할 경로를 설정합니다.
        # json_path = os.path.join(output_dir, "result.json")
        # with open(json_path, "w", encoding="utf-8") as f:
        #     json.dump({"segments": [], "text": "테스트용 음성 인식 텍스트"}, f, ensure_ascii=False, indent=2)
        # progress_map[directory_key] = 70

        # summary_path = os.path.join(output_dir, "summary.json")
        # with open(summary_path, "w", encoding="utf-8") as f:
        #     json.dump({"summary": test_summary_text}, f, ensure_ascii=False, indent=2)
        # progress_map[directory_key] = 90
        
        # # PDF 생성 함수를 호출합니다.
        # pdf_path = os.path.join(output_dir, "summary.pdf")
        # save_summary_as_pdf(test_summary_text, pdf_path)
        # progress_map[directory_key] = 100
        # #===========================================================
        
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

        # summarize_text 함수를 직접 호출합니다.
        summary = summarize_text(combined_text, mode=summary_mode, custom_prompt=custom_prompt)
        summary_path = os.path.join(output_dir, "summary.json")
        with open(summary_path, "w", encoding="utf-8") as f:
            json.dump({"summary": summary}, f, ensure_ascii=False, indent=2)
        progress_map[directory_key] = 90
        
        # PDF 생성 함수를 호출합니다.
        pdf_path = os.path.join(output_dir, "summary.pdf")
        save_summary_as_pdf(summary, pdf_path)
        progress_map[directory_key] = 100

        print(f"✅ 변환 완료! '{json_path}'에 저장됨")
        send_pdf_complete_notification_via_http()
            
    except Exception as e:
        print(f"❌ 변환 중 에러 발생: {e}")
        progress_map[directory_key] = -1


# 웹 소켓 통해 요약 완료 알림 보내기
def send_pdf_complete_notification_via_http():
    try:
        # .env 파일에서 서버 주소를 가져옵니다.
        base_url = os.getenv("API_BASE_URL")
        if not base_url:
            print("❌ 오류: 'API_BASE_URL'이 .env에 설정되지 않았습니다.")
            return

        # FastAPI 엔드포인트에 POST 요청을 보냅니다.
        requests.post(f"{base_url}/api/notifications/pdf-complete")
        print("🎉 PDF 완료 알림 요청을 서버에 보냈습니다!")

    except Exception as e:
        print(f"❌ 알림 요청 실패: {e}")
