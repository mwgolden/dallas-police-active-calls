from fastapi import FastAPI #type: ignore
from fastapi.staticfiles import StaticFiles #type: ignore
from app.v1 import app_router
from api.v1 import active_calls_router
import os

ENVIRONMENT = os.environ.get("ENV")

def configure_static_files(app):
    app.mount("/static", StaticFiles(directory="static"), name="static")

def run():
    app = FastAPI(docs_url=None, redoc_url=None, openapi_url=None) if ENVIRONMENT == "production" else FastAPI()
    configure_static_files(app)
    app.include_router(router=app_router.router)
    app.include_router(router=active_calls_router.router, prefix="/api/v1")
    return app

app = run()