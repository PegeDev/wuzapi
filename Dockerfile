FROM golang:1.23-bullseye AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    pkg-config

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
ENV CGO_ENABLED=1
RUN go build -o wuzapi

FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    netcat-openbsd \
    postgresql-client \
    openssl \
    curl \
    ffmpeg \
    tzdata

ENV TZ="Asia/Jakarta"
WORKDIR /app

COPY --from=builder /app/wuzapi /app/
COPY --from=builder /app/static /app/static/
COPY --from=builder /app/wuzapi.service /app/wuzapi.service


RUN chmod +x /app/wuzapi && \
    chmod -R 755 /app && \
    chown -R root:root /app 

ENTRYPOINT ["/app/wuzapi", "--logtype=console", "--color=true"]
