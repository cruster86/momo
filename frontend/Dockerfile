FROM node:16 as builder
WORKDIR /usr/src/app
COPY . .
RUN npm install && npm install
NODE_ENV=production VUE_APP_API_URL=http://localhost:8081 npm run serve

FROM nginx:latest
COPY --from=builder /usr/src/app/dist/frontend/* /usr/share/nginx/html/
EXPOSE 8081
