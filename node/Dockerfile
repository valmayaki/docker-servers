FROM node:10.19
LABEL author="Valentine Mayaki"

RUN apt-get update -qqy \
    && apt-get -y install build-essential ffmpeg \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

