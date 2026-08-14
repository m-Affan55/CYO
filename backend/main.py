from fastapi import FastAPI

app = FastAPI()


@app.get("/")
def root():
    return {"message": "FastAPI is running!"}


@app.get("/hello")
def hello():
    return {"message": "Hello World"}