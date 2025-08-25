import os
import openai
from dotenv import load_dotenv

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
dotenv_path = os.path.join(BASE_DIR, ".env")
load_dotenv(dotenv_path)

openai.api_key = os.getenv("OPENAI_API_KEY")

#json 요약 함수
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
