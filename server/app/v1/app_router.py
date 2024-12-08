from fastapi import APIRouter
from fastapi.responses import HTMLResponse

router = APIRouter()

@router.get("/", response_class=HTMLResponse)
async def home():
    with open("./static/index.html") as f:
        return f.read()