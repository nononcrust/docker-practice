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

FROM node:18-alpine AS base

FROM base AS deps

RUN apk add --no-cache libc6-compat
WORKDIR /app

COPY package.json package-lock.json ./
RUN \
  npm ci

# 필요할 때만 소스 코드를 빌드합니다
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

RUN npm run build

# 프로덕션 이미지를 빌드합니다
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