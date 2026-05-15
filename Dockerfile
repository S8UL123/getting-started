# ----------------------------
# Python base (FIXED: avoids Python 3.13 issue with htmlmin/cgi)
# ----------------------------
FROM python:3.12-slim AS base

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt


# ----------------------------
# Node base for frontend build
# ----------------------------
FROM node:18-alpine AS app-base

WORKDIR /app

COPY app/package.json app/yarn.lock ./
COPY app/spec ./spec
COPY app/src ./src


# ----------------------------
# Run tests
# ----------------------------
FROM app-base AS test

RUN yarn install
RUN yarn test


# ----------------------------
# Create zip package
# ----------------------------
FROM app-base AS app-zip-creator

COPY --from=test /app/package.json /app/yarn.lock ./
COPY app/spec ./spec
COPY app/src ./src

RUN apk add --no-cache zip && \
    zip -r /app.zip /app


# ----------------------------
# Dev environment (MkDocs server)
# ----------------------------
FROM base AS dev

CMD ["mkdocs", "serve", "-a", "0.0.0.0:8000"]


# ----------------------------
# Build MkDocs site
# ----------------------------
FROM base AS build

COPY . .

RUN mkdocs build


# ----------------------------
# Final Nginx production image
# ----------------------------
FROM nginx:alpine

COPY --from=app-zip-creator /app.zip /usr/share/nginx/html/assets/app.zip
COPY --from=build /app/site /usr/share/nginx/html
