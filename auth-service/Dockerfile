FROM golang:1.21-alpine AS builder
WORKDIR /src
COPY go.mod ./
COPY . .
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /out/auth-service .

FROM alpine:3.20
RUN apk add --no-cache ca-certificates curl
WORKDIR /app
COPY --from=builder /out/auth-service /usr/local/bin/auth-service
EXPOSE 8001
ENTRYPOINT ["/usr/local/bin/auth-service"]
