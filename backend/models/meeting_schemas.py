from pydantic import BaseModel

# 회의 데이터 모델
class Meeting(BaseModel):
    name: str
    description: str
    date: str
    is_interested: bool
    is_ended: bool