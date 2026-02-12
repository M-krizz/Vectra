from fastapi import FastAPI
from pydantic import BaseModel
from typing import List, Optional

app = FastAPI()

class Rider(BaseModel):
    id: str
    lat: float
    lon: float

class PoolRequest(BaseModel):
    vehicle_type: str
    riders: List[Rider]

@app.get("/")
def read_root():
    return {"Hello": "World"}

@app.post("/evaluate-pool")
def evaluate_pool(request: PoolRequest):
    # Mock Logic: Always approve
    return {
        "isValid": True,
        "score": 0.95,
        "sequence": [r.id for r in request.riders],
        "detourOk": True
    }
