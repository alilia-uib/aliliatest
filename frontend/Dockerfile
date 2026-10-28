# syntax=docker/dockerfile:1

FROM node:22-alpine AS build
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

# VITE_API_BASE_URL is baked into the bundle at build time.
ARG VITE_API_BASE_URL
ENV VITE_API_BASE_URL=${VITE_API_BASE_URL}
RUN if [ -z "$VITE_API_BASE_URL" ]; then \
      echo "VITE_API_BASE_URL build-arg is required" >&2; exit 1; \
    fi \
 && npm run build

FROM node:22-alpine AS runtime
WORKDIR /app
ENV NODE_ENV=production \
    PORT=8080

COPY --from=build /app/dist ./public
COPY docker/static-server.mjs ./server.mjs

USER node
EXPOSE 8080

CMD ["node", "server.mjs"]
