from fastapi import FastAPI #type: ignore
from fastapi.staticfiles import StaticFiles #type: ignore
from app.v1 import app_router
from api.v1 import active_calls_router
import os
from starlette.middleware.trustedhost import TrustedHostMiddleware
from starlette.middleware.base import BaseHTTPMiddleware
from dotenv import load_dotenv

ENVIRONMENT = os.environ.get("ENV")

def configure_static_files(app):
    app.mount("/static", StaticFiles(directory="static"), name="static")

def run():
    if ENVIRONMENT == "production":
        app = FastAPI(docs_url=None, redoc_url=None, openapi_url=None)
    else:
        load_dotenv()
        app = FastAPI()

    configure_static_files(app)
    app.include_router(router=app_router.router)
    app.include_router(router=active_calls_router.router, prefix="/api/v1")
    return app

app = run()

# Middleware to handle X-Forwarded-Proto
@app.middleware("http")
async def https_redirect(request, call_next):
    # Check if the original request was HTTPS (using X-Forwarded-Proto)
    if request.headers.get("x-forwarded-proto") == "https":
        request.scope["scheme"] = "https"
    response = await call_next(request)
    return response 
