FROM python:3.8-slim-buster

RUN pip install --no-cache-dir --upgrade pip \
    && pip install awscli==1.19.57

RUN apt-get update \
    && apt-get install -y ffmpeg

WORKDIR /work
