# Multi-stage build: compile TypeScript in a full node image, run the compiled JS
# in a slim one — keeps the final image small since it doesn't need the TS compiler.

FROM node:22-alpine AS build
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install
COPY . .
RUN npm run build

FROM node:22-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production
COPY package.json package-lock.json* ./
RUN npm install --omit=dev
COPY --from=build /app/dist ./dist
COPY --from=build /app/src/db/schema.sql ./dist/db/schema.sql

EXPOSE 3001
CMD ["node", "dist/index.js"]
