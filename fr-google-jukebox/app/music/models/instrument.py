from pydantic import BaseModel


class InstrumentBase(BaseModel):
    id: str
    url: str
