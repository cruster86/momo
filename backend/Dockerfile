FROM gitlab.praktikum-services.ru:5050/zerodistance/momo-store/golang:alpine as builder
WORKDIR /app
COPY . .
RUN GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o ./main ./cmd/api/

FROM gitlab.praktikum-services.ru:5050/zerodistance/momo-store/golang:alpine
WORKDIR /app
COPY --from=builder /app/main ./main
EXPOSE 8081
ENTRYPOINT [ "./main" ]
