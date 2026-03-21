FROM node:22-alpine

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci --production

COPY server.js data.js ./
COPY openapi.yaml ./

EXPOSE 8080

CMD ["node", "server.js"]
