#!/bin/bash

apt-get update
apt-get install -y python3-pip python3-venv


mkdir -p /opt/backend-api
cd /opt/backend-api


python3 -m venv venv
source venv/bin/activate
pip install fastapi uvicorn

cat << 'EOF' > main.py
from fastapi import FastAPI
import socket

app = FastAPI()

@app.get("/")
def read_root():
    hostname = socket.gethostname()
    return {
        "status": "ok",
        "message": "working hello world",
        "server_instance": hostname
    }
EOF


nohup uvicorn main:app --host 0.0.0.0 --port 80 > api.log 2>&1 &