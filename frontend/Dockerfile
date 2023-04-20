FROM node:16.20.0-alpine3.17 as builder
WORKDIR /usr/src/app
COPY package*.json .
RUN npm install
COPY . .
RUN npm run build

FROM nginx:stable-alpine3.17-slim
RUN rm -rf /usr/share/nginx/html/* && rm -rf /etc/nginx/conf.d/*
COPY default.conf /etc/nginx/conf.d
COPY --from=builder /usr/src/app/dist/ /usr/share/nginx/html
EXPOSE 80
