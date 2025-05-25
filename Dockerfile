FROM golang:1.24-alpine AS build

WORKDIR /app
COPY . .
RUN go build -o hugo-contact .

FROM alpine:latest

ENV PORT=8080
EXPOSE 8080

RUN adduser -D appuser
USER appuser

WORKDIR /app
COPY --from=build /app/hugo-contact .

ENTRYPOINT ["./hugo-contact"]
