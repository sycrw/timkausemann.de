FROM alpine:edge AS builder
RUN apk add --no-cache hugo git
WORKDIR /src
COPY src .
RUN hugo --destination=/output
FROM nginx:alpine
COPY --from=builder /output /usr/share/nginx/html
WORKDIR /usr/share/nginx/html