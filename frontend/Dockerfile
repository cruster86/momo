FROM node:16.17.0-bullseye-slim
ENV NODE_ENV production
WORKDIR /usr/src/app
COPY --chown=node:node . .
RUN npm ci --only=production
USER node
ENV VUE_APP_API_URL http://localhost:8081
RUN npm run serve
EXPOSE 8081
