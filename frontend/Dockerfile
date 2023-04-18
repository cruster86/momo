FROM node:16.17.0-bullseye-slim
WORKDIR /usr/src/app
COPY . .
RUN npm install
CMD NODE_ENV=production VUE_APP_API_URL=http://localhost:8081 npm run serve
EXPOSE 8080
