# Stage 1: Build stage
FROM python:3.8 AS builder

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
ARG MYSQL_HOST=localhost
COPY generate_html.py .
RUN python generate_html.py $MYSQL_HOST

# Stage 2: Nginx stage
FROM nginx:alpine

COPY ./nginx.conf /etc/nginx/nginx.conf

COPY --from=builder /app/index.html /usr/share/nginx/html/index.html


EXPOSE 9980
