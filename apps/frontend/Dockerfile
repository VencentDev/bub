FROM node:20-alpine AS deps
RUN corepack enable
WORKDIR /repo
COPY pnpm-lock.yaml pnpm-workspace.yaml package.json ./
COPY apps/frontend/package.json apps/frontend/
COPY packages/api-types/package.json packages/api-types/
RUN pnpm install --frozen-lockfile

FROM node:20-alpine AS build
RUN corepack enable
WORKDIR /repo
COPY --from=deps /repo/node_modules ./node_modules
COPY . .
RUN pnpm --filter @app/api-types generate:types
RUN pnpm --filter @app/frontend build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=3000
RUN addgroup --system app && adduser --system --ingroup app app
COPY --from=build /repo/apps/frontend/.next/standalone ./
COPY --from=build /repo/apps/frontend/.next/static ./apps/frontend/.next/static
COPY --from=build /repo/apps/frontend/public ./apps/frontend/public
USER app
EXPOSE 3000
CMD ["node", "apps/frontend/server.js"]
