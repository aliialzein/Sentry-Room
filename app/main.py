from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def root():
    return {
        "message": "Sentry Room Backend Running"
    }

@app.get("/health")
def health():
    return {
        "status": "healthy"
    }

@app.get("/users/{user_id}")
def get_user(user_id: int):
    return {
        "user_id": user_id,
        "name": "Ali"
    }