
from fastapi import FastAPI
from routes.neo4j_route import router as graph_router
from fastapi.middleware.cors import CORSMiddleware
from config import CORS_ALLOWED_ORIGINS

app = FastAPI()


app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


app.include_router(graph_router)
