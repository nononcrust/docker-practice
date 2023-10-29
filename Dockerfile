# Next.js 공식 Dockerfile 예제
# https://github.com/vercel/next.js/blob/canary/examples/with-docker/Dockerfile

# Medium 블로그
# https://medium.com/@elifront/best-next-js-docker-compose-hot-reload-production-ready-docker-setup-28a9125ba1dc

# Multi Staged Build - Docker 공식 문서
# https://docs.docker.com/build/building/multi-stage/

# FROM - base 이미지를 설정합니다
# WORKDIR - 작업 디렉토리를 설정합니다
# RUN - 이미지 빌드 시 실행할 명령어를 설정합니다
# ENTRYPOINT - 컨테이너가 시작되었을 때 실행할 명령어를 설정합니다
# CMD - 이미지 실행 시 파라미터를 설정합니다
# EXPOSE: 컨테이너가 실행되었을 때 노출할 포트를 설정합니다
# COPY - 파일을 복사합니다
# ADD - 파일을 복사합니다. COPY와 다르게 압축 파일을 자동으로 압축 해제합니다
# ENV - 환경 변수를 설정합니다
# ARG - 빌드 시 사용할 변수를 설정합니다

# Stage 1 - Base Stage
FROM node:18-alpine AS base

FROM base AS deps

RUN apk add --no-cache libc6-compat
WORKDIR /app

COPY package.json package-lock.json ./
RUN \
  npm ci

# 여러 개의 패키지 매니저를 사용할 경우
# COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* ./
# RUN \
#   if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
#   elif [ -f package-lock.json ]; then npm ci; \
#   elif [ -f pnpm-lock.yaml ]; then yarn global add pnpm && pnpm i --frozen-lockfile; \
#   else echo "Lockfile not found." && exit 1; \
#   fi

# Stage 2 - Dev Stage
FROM base AS dev
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Stage 3 - Build Stage
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

RUN npm run build
# 여러 패키지 매니저를 사용할 경우
# RUN \
#   if [ -f yarn.lock ]; then yarn build; \
#   elif [ -f package-lock.json ]; then npm run build; \
#   elif [ -f pnpm-lock.yaml ]; then yarn global add pnpm && pnpm run build; \
#   else echo "Lockfile not found." && exit 1; \
#   fi

# Stage 4 - Runner Stage
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public

RUN mkdir .next
RUN chown nextjs:nodejs .next

COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000

ENV HOSTNAME "0.0.0.0"

CMD ["node", "server.js"]