
FROM node:22-alpine AS builder

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM node:22-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000
ENV HOME=/tmp
ENV TMPDIR=/tmp

RUN apk add --no-cache dumb-init wget su-exec

COPY package.json package-lock.json ./
RUN npm ci && npm cache clean --force

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/server.ts ./server.ts
COPY --from=builder /app/src/server ./src/server
COPY --from=builder /app/protos ./protos
COPY --from=builder /app/tsconfig.json ./tsconfig.json
COPY docker-entrypoint.sh ./docker-entrypoint.sh

RUN chmod +x ./docker-entrypoint.sh \
    && mkdir -p /app/data \
    && chown -R node:node /app /tmp

USER node

EXPOSE 3000 50051

ENTRYPOINT ["dumb-init", "--", "./docker-entrypoint.sh"]
CMD ["./node_modules/.bin/tsx", "server.ts"]
